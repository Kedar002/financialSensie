import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../tracker_constants.dart';
import 'stationary_detector.dart';

@pragma('vm:entry-point')
class TrackerBackgroundService {
  static const String _notificationChannelId = 'location_tracker_channel';
  static const String _notificationChannelName = 'Location Tracking';

  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    final androidConfig = AndroidConfiguration(
      onStart: _onStart,
      autoStart: false,
      autoStartOnBoot: true,
      isForegroundMode: true,
      notificationChannelId: _notificationChannelId,
      initialNotificationTitle: 'Location Tracker',
      initialNotificationContent: 'Preparing...',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    );

    await service.configure(
      androidConfiguration: androidConfig,
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
      ),
    );
  }

  static Future<void> setupNotificationChannel() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: 'Used for location tracking service',
      importance: Importance.low,
    );
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  @pragma('vm:entry-point')
  static Future<void> _log(String msg) async {
    final line = '[BG ${DateTime.now().toIso8601String()}] $msg';
    // ignore: avoid_print
    print(line);
    try {
      final dir = await getDatabasesPath();
      final f = File(p.join(dir, 'bg_service.log'));
      await f.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    // Use print() directly — _log() requires plugins which may not be ready yet
    // ignore: avoid_print
    print('[BG] _onStart CALLED');
    runZonedGuarded(() async {
      await _startService(service);
    }, (error, stack) async {
      // ignore: avoid_print
      print('[BG] UNCAUGHT ERROR: $error\n$stack');
      try {
        await _log('UNCAUGHT ERROR: $error\n$stack');
      } catch (_) {}
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _startService(ServiceInstance service) async {
    // ignore: avoid_print
    print('[BG] _startService BEGIN');
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (e) {
      // ignore: avoid_print
      print('[BG] DartPluginRegistrant FAILED: $e');
      return;
    }
    // ignore: avoid_print
    print('[BG] DartPluginRegistrant OK');
    await _log('_onStart: DartPluginRegistrant initialized');

    // CRITICAL: Promote to foreground IMMEDIATELY before any async work.
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
      service.setForegroundNotificationInfo(
        title: 'Location Tracker',
        content: 'Starting up...',
      );
    }
    await _log('_onStart: foreground service set');

    // --- Firebase (optional — must NOT crash the service) ---
    FirebaseFirestore? firestore;
    try {
      await Firebase.initializeApp();
      firestore = FirebaseFirestore.instance;
      await _log('_onStart: Firebase initialized');
    } catch (e) {
      await _log('_onStart: Firebase init FAILED (will queue locally): $e');
    }

    final battery = Battery();
    final prefs = await SharedPreferences.getInstance();
    // Accept either key — same-device use shares the same hardcoded ID
    final deviceId = prefs.getString('tracker_device_id') ??
        prefs.getString('tracker_paired_device_id') ??
        '';
    await _log('_onStart: deviceId=$deviceId');

    if (deviceId.isEmpty) {
      await _log('_onStart: deviceId empty — stopping');
      service.stopSelf();
      return;
    }

    // --- SQLite ---
    Database? db;
    try {
      final dbPath = await getDatabasesPath();
      db = await openDatabase(p.join(dbPath, 'financesensei.db'));
      // Ensure tables exist (background isolate may start before main app migration)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offline_location_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          accuracy REAL NOT NULL,
          speed REAL NOT NULL,
          heading REAL NOT NULL,
          battery_level INTEGER NOT NULL,
          is_charging INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS geofences (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          radius_meters REAL NOT NULL,
          notify_on_enter INTEGER NOT NULL DEFAULT 1,
          notify_on_exit INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          arrival_time TEXT NOT NULL,
          departure_time TEXT,
          duration_minutes INTEGER,
          zone_name TEXT,
          zone_id INTEGER,
          battery_on_arrival INTEGER NOT NULL DEFAULT -1,
          battery_on_departure INTEGER
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS zone_settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          geofence_id INTEGER NOT NULL,
          zone_name TEXT NOT NULL,
          alert_on_enter INTEGER NOT NULL DEFAULT 1,
          alert_on_exit INTEGER NOT NULL DEFAULT 1,
          minimum_stay_minutes INTEGER NOT NULL DEFAULT 0,
          suppress_while_inside INTEGER NOT NULL DEFAULT 0,
          alert_only_on_exit INTEGER NOT NULL DEFAULT 0,
          update_interval_minutes INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await _log('_onStart: SQLite ready');
    } catch (e) {
      await _log('_onStart: SQLite FAILED: $e');
    }

    // --- Notifications ---
    FlutterLocalNotificationsPlugin? notificationsPlugin;
    try {
      notificationsPlugin = FlutterLocalNotificationsPlugin();
      await notificationsPlugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _log('_onStart: Notifications initialized');
    } catch (e) {
      await _log('_onStart: Notifications init FAILED: $e');
      notificationsPlugin = null;
    }

    Future<void> showAlert(String title, String body) async {
      try {
        await notificationsPlugin?.show(
          889,
          title,
          body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'tracker_alerts',
              'Tracker Alerts',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      } catch (_) {}
    }

    // --- State Machine ---
    final detector = StationaryDetector();

    // Restore persisted state
    final stateJson = prefs.getString('tracker_detector_state');
    if (stateJson != null) {
      try {
        final restored =
            StationaryDetector.fromJson(jsonDecode(stateJson) as Map<String, dynamic>);
        detector.restore(
          state: restored.state,
          anchorLat: restored.anchorLat,
          anchorLng: restored.anchorLng,
          visitStartTime: restored.visitStartTime,
        );
        await _log('_onStart: detector state restored: ${detector.state}');
      } catch (e) {
        await _log('_onStart: detector state restore FAILED: $e');
      }
    }

    // Track active visit DB id
    int? activeVisitId = prefs.getInt('tracker_active_visit_id');

    // Load frequency settings
    String updateFrequency = 'smart';
    int customFrequencySeconds = 60;
    final settingsJson = prefs.getString('tracker_settings');
    if (settingsJson != null) {
      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      updateFrequency = settings['updateFrequency'] as String? ?? 'smart';
      customFrequencySeconds =
          settings['customFrequencySeconds'] as int? ?? 60;
    }
    await _log('_onStart: frequency=$updateFrequency');

    // Load zone settings for per-zone interval
    Map<int, Map<String, dynamic>> zoneSettingsMap = {};
    if (db != null) {
      try {
        final rows = await db.query('zone_settings');
        for (final row in rows) {
          zoneSettingsMap[row['geofence_id'] as int] = row;
        }
      } catch (_) {}
    }

    final insideZones = <int>{};

    /// Last time a location was sent to Firebase.
    /// Used to throttle Firebase sends when zone interval > GPS poll interval.
    DateTime? lastFirebaseSendTime;

    // --- Geofence checking + zone settings ---
    double calcDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
      final dLat = (lat1 - lat2) * 111320;
      final dLng =
          (lng1 - lng2) * 111320 * math.cos(lat2 * 3.14159265 / 180);
      return math.sqrt(dLat * dLat + dLng * dLng);
    }

    Future<_ZoneMatch?> checkGeofences(double lat, double lng) async {
      if (db == null) return null;
      _ZoneMatch? match;
      try {
        final zones = await db.query('geofences');
        await _log('checkGeofences: ${zones.length} zones, device at $lat,$lng');
        for (final row in zones) {
          final zoneId = row['id'] as int;
          final zoneLat = (row['latitude'] as num).toDouble();
          final zoneLng = (row['longitude'] as num).toDouble();
          final radius = (row['radius_meters'] as num).toDouble();
          final notifyEnter = row['notify_on_enter'] == 1;
          final notifyExit = row['notify_on_exit'] == 1;
          final name = row['name'] as String;

          final distance = calcDistanceMeters(lat, lng, zoneLat, zoneLng);
          await _log('  zone "$name" (id=$zoneId): dist=${distance.toStringAsFixed(1)}m, radius=${radius.toStringAsFixed(0)}m');

          final wasInside = insideZones.contains(zoneId);
          final isInside = distance <= radius;

          if (isInside && !wasInside) {
            insideZones.add(zoneId);
            final zs = zoneSettingsMap[zoneId];
            final shouldAlertEnter = zs != null
                ? zs['alert_on_enter'] == 1
                : notifyEnter;
            final alertOnlyOnExit = zs != null
                ? zs['alert_only_on_exit'] == 1
                : false;
            if (shouldAlertEnter && !alertOnlyOnExit) {
              showAlert('Entered $name', 'Device entered the $name zone');
            }
          } else if (!isInside && wasInside) {
            insideZones.remove(zoneId);
            final zs = zoneSettingsMap[zoneId];
            final shouldAlertExit = zs != null
                ? zs['alert_on_exit'] == 1
                : notifyExit;
            if (shouldAlertExit) {
              showAlert('Left $name', 'Device left the $name zone');
            }
          }

          if (isInside) {
            match = _ZoneMatch(zoneId: zoneId, zoneName: name);
          }
        }
      } catch (e) {
        await _log('checkGeofences ERROR: $e');
      }
      return match;
    }

    // Drain queued offline points into location_history (append-only timeline).
    // Do NOT write into `locations/{deviceId}` here — that doc holds the
    // *current* position, and overwriting it with a stale queued point would
    // make the viewer's map jump backwards.
    //
    // A row is deleted only after its Firebase write succeeds. On any write
    // failure we stop the drain (preserves ordering and lets the next tick
    // retry from the same head).
    Future<int> syncPending() async {
      if (firestore == null || db == null) return 0;
      int synced = 0;
      try {
        final pending = await db.query(
          'offline_location_queue',
          orderBy: 'timestamp ASC',
          limit: 20,
        );
        for (final row in pending) {
          final data = {
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'timestamp': Timestamp.fromDate(
                DateTime.parse(row['timestamp'] as String)),
            'speed': row['speed'],
            'heading': row['heading'],
            'accuracy': row['accuracy'],
            'batteryLevel': row['battery_level'],
            'isCharging': row['is_charging'] == 1,
            'syncedFromQueue': true,
          };
          try {
            await firestore
                .collection('location_history')
                .doc(deviceId)
                .collection('points')
                .add(data);
            await db.delete('offline_location_queue',
                where: 'id = ?', whereArgs: [row['id']]);
            synced++;
          } catch (e) {
            await _log('syncPending: write failed, stopping drain: $e');
            break;
          }
        }
        if (synced > 0) {
          await _log('syncPending: drained $synced queued points');
        }
      } catch (e) {
        await _log('syncPending ERROR: $e');
      }
      return synced;
    }

    Timer? locationTimer;

    // --- Core: Process a location reading ---
    Future<void> processLocation() async {
      try {
        // Re-read frequency setting (may have changed from Viewer settings)
        try {
          await prefs.reload();
        } catch (e) {
          await _log('prefs.reload() FAILED: $e');
        }
        final freshSettings = prefs.getString('tracker_settings');
        if (freshSettings != null) {
          final s = jsonDecode(freshSettings) as Map<String, dynamic>;
          final oldFreq = updateFrequency;
          updateFrequency = s['updateFrequency'] as String? ?? 'smart';
          customFrequencySeconds =
              s['customFrequencySeconds'] as int? ?? 60;
          if (oldFreq != updateFrequency) {
            await _log('Frequency CHANGED: $oldFreq → $updateFrequency');
          }
          // Check paused state
          final paused = s['isPaused'] as bool? ?? false;
          if (paused) {
            await _log('processLocation: SKIPPED — tracking is paused');
            if (service is AndroidServiceInstance) {
              service.setForegroundNotificationInfo(
                title: 'Tracking Paused',
                content: 'Tap settings to resume',
              );
            }
            return;
          }
        }
        await _log('processLocation: freq=$updateFrequency, customSec=$customFrequencySeconds');

        // Check location permission and service before attempting GPS
        String? skipReason;
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          skipReason = 'permission not granted ($permission)';
        } else {
          final serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            skipReason = 'location service disabled';
          }
        }
        if (skipReason != null) {
          await _log('processLocation: SKIP — $skipReason');
          if (service is AndroidServiceInstance) {
            service.setForegroundNotificationInfo(
              title: 'Location unavailable',
              content: skipReason,
            );
          }
          // Still adjust timer interval even without GPS
          final fixedNoGps = TrackerConstants.fixedIntervalForFrequency(
              updateFrequency, customFrequencySeconds);
          final nextNoGps = fixedNoGps ?? TrackerConstants.movingPollInterval;
          if (locationTimer != null && _currentTimerInterval != nextNoGps) {
            locationTimer?.cancel();
            _currentTimerInterval = nextNoGps;
            locationTimer =
                Timer.periodic(nextNoGps, (_) => processLocation());
            await _log('Timer CHANGED (no-GPS) → ${nextNoGps.inSeconds}s');
          }
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final batteryLevel = await battery.batteryLevel;
        final batteryState = await battery.batteryState;
        final isCharging = batteryState == BatteryState.charging;

        // Check geofences
        final zoneMatch =
            await checkGeofences(position.latitude, position.longitude);

        // Set per-zone interval if in a zone
        if (zoneMatch != null) {
          final zs = zoneSettingsMap[zoneMatch.zoneId];
          final interval = zs?['update_interval_minutes'] as int? ?? 0;
          detector.setZoneInterval(interval);
        } else {
          detector.setZoneInterval(0);
        }

        // Feed into state machine
        final reading = GpsReading(
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed,
          accuracy: position.accuracy,
          timestamp: DateTime.now(),
        );

        final result = detector.process(reading);

        // --- Visit lifecycle ---
        if (result.visitStarted) {
          await _log('VISIT STARTED at ${position.latitude},${position.longitude}');
          // Record an "Unknown" placeholder immediately when no zone matches,
          // so the visit shows up in history right away instead of appearing
          // only after the 3-minute minimum + departure auto-zone step.
          final initialZoneName = zoneMatch?.zoneName ?? 'Unknown';
          // Create visit in local DB
          if (db != null) {
            activeVisitId = await db.insert('visits', {
              'latitude': result.anchorLat,
              'longitude': result.anchorLng,
              'arrival_time': result.visitStartTime!.toIso8601String(),
              'zone_name': initialZoneName,
              'zone_id': zoneMatch?.zoneId,
              'battery_on_arrival': batteryLevel,
            });
            await prefs.setInt('tracker_active_visit_id', activeVisitId!);
          }
          // Write active visit to Firebase
          if (firestore != null) {
            try {
              await firestore.collection('active_visit').doc(deviceId).set({
                'latitude': result.anchorLat,
                'longitude': result.anchorLng,
                'arrivalTime': result.visitStartTime!.toIso8601String(),
                'zoneName': initialZoneName,
                'zoneId': zoneMatch?.zoneId,
                'batteryOnArrival': batteryLevel,
              });
            } catch (_) {}
          }
        }

        // Update zone name on active visit if it was missing but now matched.
        // Only update if the visit's ANCHOR is inside the zone (not just
        // the current GPS position, which may have moved to a different zone).
        if (!result.visitStarted &&
            !result.visitEnded &&
            activeVisitId != null &&
            db != null) {
          try {
            final row = await db.query('visits',
                where: 'id = ?', whereArgs: [activeVisitId]);
            final currentName = row.isNotEmpty
                ? row.first['zone_name'] as String?
                : null;
            final isPlaceholder =
                currentName == null || currentName == 'Unknown';
            if (row.isNotEmpty && isPlaceholder) {
              final visitLat = (row.first['latitude'] as num).toDouble();
              final visitLng = (row.first['longitude'] as num).toDouble();
              // Check which zone the visit's anchor falls in
              _ZoneMatch? anchorZone;
              final zones = await db.query('geofences');
              for (final z in zones) {
                final zLat = (z['latitude'] as num).toDouble();
                final zLng = (z['longitude'] as num).toDouble();
                final radius = (z['radius_meters'] as num).toDouble();
                final dist = calcDistanceMeters(visitLat, visitLng, zLat, zLng);
                if (dist <= radius) {
                  anchorZone = _ZoneMatch(
                    zoneId: z['id'] as int,
                    zoneName: z['name'] as String,
                  );
                  break;
                }
              }
              if (anchorZone != null) {
                await db.update(
                  'visits',
                  {
                    'zone_name': anchorZone.zoneName,
                    'zone_id': anchorZone.zoneId,
                  },
                  where: 'id = ?',
                  whereArgs: [activeVisitId],
                );
                if (firestore != null) {
                  try {
                    await firestore
                        .collection('active_visit')
                        .doc(deviceId)
                        .update({
                      'zoneName': anchorZone.zoneName,
                      'zoneId': anchorZone.zoneId,
                    });
                  } catch (_) {}
                }
                await _log(
                    'Updated active visit zone: ${anchorZone.zoneName}');
              } else {
                // No existing zone matches. If the visit has already run past
                // the minimum-visit threshold, mint an auto-zone NOW rather
                // than waiting for departure — otherwise a device that stays
                // put (or a mock-location test) never gets a zone at all.
                final arrivalIso = row.first['arrival_time'] as String?;
                final arrival =
                    arrivalIso != null ? DateTime.tryParse(arrivalIso) : null;
                final elapsed = arrival != null
                    ? DateTime.now().difference(arrival)
                    : Duration.zero;
                if (arrival != null &&
                    elapsed >= TrackerConstants.minimumVisitDuration) {
                  final now = DateTime.now();
                  String two(int n) => n.toString().padLeft(2, '0');
                  const months = [
                    'Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'
                  ];
                  final zoneName =
                      'Place ${two(now.hour)}:${two(now.minute)} ${two(now.day)} ${months[now.month - 1]}';
                  final newZoneId = await db.insert('geofences', {
                    'name': zoneName,
                    'latitude': visitLat,
                    'longitude': visitLng,
                    'radius_meters': 100.0,
                    'notify_on_enter': 1,
                    'notify_on_exit': 1,
                    'created_at': now.toIso8601String(),
                  });
                  await db.update(
                    'visits',
                    {'zone_name': zoneName, 'zone_id': newZoneId},
                    where: 'id = ?',
                    whereArgs: [activeVisitId],
                  );
                  await _log(
                      'Mid-visit auto-created zone "$zoneName" (id=$newZoneId) after ${elapsed.inMinutes}m');
                  if (firestore != null) {
                    try {
                      await firestore
                          .collection('geofences')
                          .doc(deviceId)
                          .collection('zones')
                          .doc(newZoneId.toString())
                          .set({
                        'name': zoneName,
                        'latitude': visitLat,
                        'longitude': visitLng,
                        'radiusMeters': 100.0,
                        'notifyOnEnter': true,
                        'notifyOnExit': true,
                      });
                      await firestore
                          .collection('active_visit')
                          .doc(deviceId)
                          .update({
                        'zoneName': zoneName,
                        'zoneId': newZoneId,
                      });
                    } catch (_) {}
                  }
                }
              }
            }
          } catch (_) {}
        }

        if (result.visitEnded && result.visitStartTime != null) {
          // Use the detector's actual departure time (first movement detection)
          // for accurate timing, falling back to now if unavailable
          final departureTime = result.departureTime ?? DateTime.now();
          final duration =
              departureTime.difference(result.visitStartTime!);

          // Read the stored zone name from the visit's DB record only.
          // Do NOT initialize from zoneMatch (current GPS position) —
          // the device may have already moved to a known zone (e.g. katraj)
          // while the old visit at an unknown location is ending.
          String? storedZoneName;
          int? storedZoneId;
          if (db != null && activeVisitId != null) {
            try {
              final row = await db.query('visits',
                  where: 'id = ?', whereArgs: [activeVisitId]);
              if (row.isNotEmpty) {
                storedZoneName = row.first['zone_name'] as String?;
                storedZoneId = row.first['zone_id'] as int?;
              }
            } catch (_) {}
          }

          // Only record visits longer than minimum duration
          if (duration >= TrackerConstants.minimumVisitDuration) {
            await _log(
                'VISIT ENDED: ${duration.inMinutes}m at ${result.anchorLat},${result.anchorLng}');

            // Auto-create zone for unknown locations so they appear
            // as named places in history and are recognized on future visits.
            // "Unknown" is the placeholder we wrote on arrival — treat it the
            // same as null (not yet matched to a real zone).
            final needsAutoZone =
                storedZoneName == null || storedZoneName == 'Unknown';
            if (needsAutoZone &&
                result.anchorLat != null &&
                result.anchorLng != null &&
                db != null) {
              try {
                // Check if a zone already exists near this anchor
                bool nearbyExists = false;
                final existingZones = await db.query('geofences');
                for (final z in existingZones) {
                  final zLat = (z['latitude'] as num).toDouble();
                  final zLng = (z['longitude'] as num).toDouble();
                  final dist = calcDistanceMeters(
                      result.anchorLat!, result.anchorLng!, zLat, zLng);
                  if (dist <= 150) {
                    nearbyExists = true;
                    storedZoneName = z['name'] as String?;
                    storedZoneId = z['id'] as int?;
                    break;
                  }
                }

                if (!nearbyExists) {
                  // Use a timestamp-based suffix so auto-zones never collide
                  // with manually-named zones like "Location 5". Format:
                  // "Place HH:MM dd MMM" — e.g. "Place 14:32 13 Apr".
                  final now = DateTime.now();
                  String two(int n) => n.toString().padLeft(2, '0');
                  const months = [
                    'Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'
                  ];
                  final zoneName =
                      'Place ${two(now.hour)}:${two(now.minute)} ${two(now.day)} ${months[now.month - 1]}';
                  final newZoneId = await db.insert('geofences', {
                    'name': zoneName,
                    'latitude': result.anchorLat,
                    'longitude': result.anchorLng,
                    'radius_meters': 100.0,
                    'notify_on_enter': 1,
                    'notify_on_exit': 1,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  storedZoneName = zoneName;
                  storedZoneId = newZoneId;
                  await _log('Auto-created zone "$zoneName" (id=$newZoneId)');

                  // Sync auto-zone to Firebase
                  if (firestore != null) {
                    try {
                      await firestore
                          .collection('geofences')
                          .doc(deviceId)
                          .collection('zones')
                          .doc(newZoneId.toString())
                          .set({
                        'name': zoneName,
                        'latitude': result.anchorLat,
                        'longitude': result.anchorLng,
                        'radiusMeters': 100.0,
                        'notifyOnEnter': true,
                        'notifyOnExit': true,
                      });
                    } catch (_) {}
                  }
                }

                // Update the visit record with zone info
                if (activeVisitId != null && storedZoneName != null) {
                  await db.update(
                    'visits',
                    {'zone_name': storedZoneName, 'zone_id': storedZoneId},
                    where: 'id = ?',
                    whereArgs: [activeVisitId],
                  );
                }
              } catch (e) {
                await _log('Auto-zone creation ERROR: $e');
              }
            }

            // Finalize in local DB
            if (db != null && activeVisitId != null) {
              await db.update(
                'visits',
                {
                  'departure_time': departureTime.toIso8601String(),
                  'duration_minutes': duration.inMinutes,
                  'battery_on_departure': batteryLevel,
                },
                where: 'id = ?',
                whereArgs: [activeVisitId],
              );
            }

            // Write completed visit to Firebase
            if (firestore != null) {
              try {
                await firestore
                    .collection('visits')
                    .doc(deviceId)
                    .collection('records')
                    .add({
                  'latitude': result.anchorLat,
                  'longitude': result.anchorLng,
                  'arrivalTime': result.visitStartTime!.toIso8601String(),
                  'departureTime': departureTime.toIso8601String(),
                  'durationMinutes': duration.inMinutes,
                  'zoneName': storedZoneName,
                  'zoneId': storedZoneId,
                  'batteryOnArrival': batteryLevel,
                  'batteryOnDeparture': batteryLevel,
                });
              } catch (_) {}
            }

          } else {
            // Too short — delete the visit record
            if (db != null && activeVisitId != null) {
              await db.delete('visits',
                  where: 'id = ?', whereArgs: [activeVisitId]);
            }
          }

          // Clear active visit
          activeVisitId = null;
          await prefs.remove('tracker_active_visit_id');
          if (firestore != null) {
            try {
              await firestore.collection('active_visit').doc(deviceId).delete();
            } catch (_) {}
          }
        }

        // --- Update current location in Firebase (throttled by zone interval) ---
        // GPS is polled at the capped exit-detection rate, but Firebase sends
        // are throttled to the full zone interval for battery savings.
        final zoneReport = detector.zoneReportInterval;
        final shouldSendFirebase = zoneReport == Duration.zero ||
            lastFirebaseSendTime == null ||
            DateTime.now().difference(lastFirebaseSendTime!) >= zoneReport;

        // Get pending queue count before Firebase write (used in locData + notification)
        int pendingCount = 0;
        if (db != null) {
          pendingCount = Sqflite.firstIntValue(
                  await db.rawQuery(
                      'SELECT COUNT(*) FROM offline_location_queue')) ??
              0;
        }

        // Check actual network connectivity (Firestore offline cache makes
        // set() succeed even without network, so we must check explicitly).
        bool isOnline = false;
        try {
          final connResult = await Connectivity().checkConnectivity();
          isOnline = !connResult.contains(ConnectivityResult.none);
        } catch (_) {
          isOnline = true; // assume online if check fails
        }

        if (shouldSendFirebase) {
          final locData = {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'speed': position.speed,
            'heading': position.heading,
            'accuracy': position.accuracy,
            'batteryLevel': batteryLevel,
            'isCharging': isCharging,
            'motionState': result.state.name,
            'isNetworkAvailable': isOnline,
            'isLocationServiceEnabled': true,
            'pendingQueueCount': pendingCount,
          };

          bool firebaseOk = false;
          if (isOnline && firestore != null) {
            try {
              await firestore.collection('locations').doc(deviceId).set(locData);
              // Append to the continuous trail so the viewer can render the
              // route taken between two visits. The `locations` doc only
              // holds the latest fix; this append keeps full history.
              // `sync_service.dart` writes the same shape for offline-drained
              // samples, so queries can treat both paths uniformly.
              await firestore
                  .collection('location_history')
                  .doc(deviceId)
                  .collection('points')
                  .add({
                'latitude': position.latitude,
                'longitude': position.longitude,
                'timestamp': Timestamp.fromDate(DateTime.now()),
                'speed': position.speed,
                'heading': position.heading,
                'accuracy': position.accuracy,
                'batteryLevel': batteryLevel,
                'isCharging': isCharging,
              });
              firebaseOk = true;
              lastFirebaseSendTime = DateTime.now();
            } catch (_) {}
          }

          if (!firebaseOk && db != null) {
            await db.insert('offline_location_queue', {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'speed': position.speed,
              'heading': position.heading,
              'battery_level': batteryLevel,
              'is_charging': isCharging ? 1 : 0,
              'timestamp': DateTime.now().toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
            });
            pendingCount++;
          }
          await _log('processLocation: Firebase ${firebaseOk ? 'sent' : 'queued offline'} (network=${isOnline ? 'on' : 'off'})');
        } else {
          await _log('processLocation: GPS polled (exit detection), Firebase throttled');
        }

        // Independent offline-queue drain: runs every tick while online,
        // regardless of whether the current tick's live-location write
        // succeeded. Previously syncPending() was only called inside the
        // success branch, which meant a device that came back online would
        // never drain its queue until a live write first worked.
        if (isOnline && pendingCount > 0) {
          final drained = await syncPending();
          if (drained > 0) {
            // Recount after drain so the notification suffix is accurate.
            pendingCount = Sqflite.firstIntValue(
                    await db!.rawQuery(
                        'SELECT COUNT(*) FROM offline_location_queue')) ??
                0;
          }
        }

        // Persist detector state for crash recovery
        await prefs.setString(
            'tracker_detector_state', jsonEncode(detector.toJson()));

        if (service is AndroidServiceInstance) {
          final suffix = pendingCount > 0 ? ' • $pendingCount queued' : '';
          String stateLabel;
          switch (result.state) {
            case MotionState.stationary:
            case MotionState.maybeMoving:
              final zoneName = zoneMatch?.zoneName;
              if (zoneName != null) {
                stateLabel = 'At $zoneName';
              } else {
                stateLabel = 'Stationary';
              }
              if (detector.visitStartTime != null) {
                final dur = DateTime.now().difference(detector.visitStartTime!);
                if (dur.inMinutes >= 1) {
                  stateLabel += ' for ${dur.inMinutes}m';
                }
              }
            case MotionState.moving:
            case MotionState.maybeStationary:
              stateLabel = 'In transit';
          }
          service.setForegroundNotificationInfo(
            title: stateLabel,
            content: 'Battery: $batteryLevel%$suffix',
          );
        }

        // Adjust timer interval based on frequency setting
        final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
            updateFrequency, customFrequencySeconds);
        // Smart mode: use detector's recommendation. Others: use fixed interval.
        final nextInterval = fixedInterval ?? result.nextPollInterval;
        await _log('Timer check: mode=$updateFrequency, fixed=${fixedInterval?.inSeconds}s, '
            'next=${nextInterval.inSeconds}s, current=${_currentTimerInterval.inSeconds}s');
        if (locationTimer != null) {
          if (_currentTimerInterval != nextInterval) {
            locationTimer?.cancel();
            _currentTimerInterval = nextInterval;
            locationTimer =
                Timer.periodic(nextInterval, (_) => processLocation());
            await _log(
                'Timer CHANGED → ${nextInterval.inSeconds}s');
          }
        }

        await _log(
            'processLocation: OK state=${result.state.name} lat=${position.latitude}');
      } catch (e) {
        await _log('processLocation: ERROR $e');
      }
    }

    // Auto-cleanup: delete visits older than 30 days
    if (db != null) {
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 30));
        final deleted = await db.delete(
          'visits',
          where: 'departure_time IS NOT NULL AND departure_time < ?',
          whereArgs: [cutoff.toIso8601String()],
        );
        if (deleted > 0) {
          await _log('cleanup: deleted $deleted old visits');
        }
      } catch (e) {
        await _log('cleanup: ERROR $e');
      }
    }

    // Auto-cleanup: delete Firebase location history older than 7 days
    if (firestore != null) {
      try {
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        final points = firestore
            .collection('location_history')
            .doc(deviceId)
            .collection('points');
        final old = await points
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoff))
            .limit(100)
            .get();
        if (old.docs.isNotEmpty) {
          final batch = firestore.batch();
          for (final doc in old.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          await _log('cleanup: deleted ${old.docs.length} old history entries');
        }
      } catch (e) {
        await _log('cleanup: ERROR $e');
      }
    }

    // Listen for geofence updates from viewer (zones are created on viewer device)
    //
    // Diff-based upsert — do NOT wipe and reinsert. Wiping created a window
    // where zones briefly did not exist, and a stale/empty Firebase snapshot
    // could destroy freshly-created local zones. Instead:
    //   - Upsert each Firebase zone by id (insert or update).
    //   - Delete local zones whose id is not in the Firebase set.
    //   - If Firebase delivers an EMPTY snapshot, skip the prune step — an
    //     empty snapshot is almost always a transient cache/error, not the
    //     user wanting every zone gone.
    if (firestore != null) {
      firestore
          .collection('geofences')
          .doc(deviceId)
          .collection('zones')
          .snapshots()
          .listen((snapshot) async {
        if (db == null) return;
        try {
          final firebaseIds = <int>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final localId = int.tryParse(doc.id) ?? 0;
            if (localId == 0) continue;
            firebaseIds.add(localId);
            final row = {
              'id': localId,
              'name': data['name'] as String? ?? '',
              'latitude': (data['latitude'] as num).toDouble(),
              'longitude': (data['longitude'] as num).toDouble(),
              'radius_meters':
                  (data['radiusMeters'] as num?)?.toDouble() ?? 100.0,
              'notify_on_enter':
                  (data['notifyOnEnter'] as bool? ?? true) ? 1 : 0,
              'notify_on_exit':
                  (data['notifyOnExit'] as bool? ?? true) ? 1 : 0,
              'created_at': DateTime.now().toIso8601String(),
            };
            final existing = await db.query(
              'geofences',
              where: 'id = ?',
              whereArgs: [localId],
              limit: 1,
            );
            if (existing.isEmpty) {
              await db.insert('geofences', row);
            } else {
              await db.update('geofences', row,
                  where: 'id = ?', whereArgs: [localId]);
            }
          }

          if (firebaseIds.isNotEmpty) {
            final placeholders = List.filled(firebaseIds.length, '?').join(',');
            final removed = await db.delete(
              'geofences',
              where: 'id NOT IN ($placeholders)',
              whereArgs: firebaseIds.toList(),
            );
            if (removed > 0) {
              await _log('geofences synced: pruned $removed removed zones');
            }
          } else {
            await _log(
                'geofences sync: empty Firebase snapshot — skip prune (treat as stale)');
          }
          await _log(
              'geofences synced from Firebase: ${snapshot.docs.length} zones');
        } catch (e) {
          await _log('geofences sync ERROR: $e');
        }
      }, onError: (_) {});
    }

    // Listen for zone settings updates from viewer
    if (firestore != null) {
      firestore
          .collection('zone_settings')
          .doc(deviceId)
          .collection('zones')
          .snapshots()
          .listen((snapshot) async {
        zoneSettingsMap.clear();
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final gId = data['geofenceId'] as int? ?? 0;
          final settingsRow = {
            'geofence_id': gId,
            'zone_name': data['zoneName'] as String? ?? '',
            'alert_on_enter': (data['alertOnEnter'] as bool? ?? true) ? 1 : 0,
            'alert_on_exit': (data['alertOnExit'] as bool? ?? true) ? 1 : 0,
            'minimum_stay_minutes': data['minimumStayMinutes'] as int? ?? 0,
            'suppress_while_inside':
                (data['suppressWhileInside'] as bool? ?? false) ? 1 : 0,
            'alert_only_on_exit':
                (data['alertOnlyOnExit'] as bool? ?? false) ? 1 : 0,
            'update_interval_minutes':
                data['updateIntervalMinutes'] as int? ?? 0,
          };
          zoneSettingsMap[gId] = settingsRow;

          // Also write to SQLite so the foreground tracker can read it
          if (db != null) {
            try {
              final existing = await db.query('zone_settings',
                  where: 'geofence_id = ?', whereArgs: [gId]);
              if (existing.isNotEmpty) {
                await db.update('zone_settings', settingsRow,
                    where: 'geofence_id = ?', whereArgs: [gId]);
              } else {
                await db.insert('zone_settings', settingsRow);
              }
            } catch (e) {
              await _log('zone_settings DB write ERROR: $e');
            }
          }
        }
        await _log('zone settings updated (memory + DB): ${zoneSettingsMap.length} zones');
      }, onError: (_) {});
    }

    // Listen for frequency setting changes from viewer (reliable cross-isolate)
    if (firestore != null) {
      firestore
          .collection('tracker_settings')
          .doc(deviceId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists || snapshot.data() == null) return;
        final data = snapshot.data()!;
        final newFreq = data['updateFrequency'] as String? ?? 'smart';
        final newCustom = data['customFrequencySeconds'] as int? ?? 60;
        // Persist settings to SharedPreferences so processLocation
        // can read them on every tick (cross-isolate sync).
        // IMPORTANT: preserve local isPaused — Firebase may deliver stale
        // data that reverts a resume the user just performed locally.
        try {
          final currentJson = prefs.getString('tracker_settings');
          final current = currentJson != null
              ? jsonDecode(currentJson) as Map<String, dynamic>
              : <String, dynamic>{};
          final localPaused = current['isPaused'] as bool? ?? false;
          final merged = Map<String, dynamic>.from(data);
          merged['isPaused'] = localPaused;
          await prefs.setString('tracker_settings', jsonEncode(merged));
        } catch (_) {}
        if (newFreq != updateFrequency || newCustom != customFrequencySeconds) {
          await _log('Firebase settings: $updateFrequency → $newFreq (custom=$newCustom)');
          updateFrequency = newFreq;
          customFrequencySeconds = newCustom;
          // For fixed modes, immediately adjust timer.
          // For smart mode, trigger a processLocation so the detector
          // sets the correct interval based on current motion state.
          final fixedInterval = TrackerConstants.fixedIntervalForFrequency(
              updateFrequency, customFrequencySeconds);
          if (fixedInterval != null) {
            if (locationTimer != null && _currentTimerInterval != fixedInterval) {
              locationTimer?.cancel();
              _currentTimerInterval = fixedInterval;
              locationTimer =
                  Timer.periodic(fixedInterval, (_) => processLocation());
              await _log('Timer CHANGED via Firebase → ${fixedInterval.inSeconds}s');
            }
          } else {
            // Smart mode — run processLocation immediately so the detector
            // can set the appropriate interval for current state
            await _log('Smart mode selected — triggering processLocation for interval');
            await processLocation();
          }
        }
      }, onError: (_) {});
    }

    // Listen for locate-now commands from viewer — triggers immediate GPS reading
    if (firestore != null) {
      String? lastHandledLocate;
      firestore
          .collection('commands')
          .doc(deviceId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists || snapshot.data() == null) return;
        final locateNow = snapshot.data()!['locateNow'] as String?;
        if (locateNow != null && locateNow != lastHandledLocate) {
          lastHandledLocate = locateNow;
          await _log('locateNow command received — sending immediate GPS');
          await processLocation();
        }
      }, onError: (_) {});
    }

    // Re-write active_visit if detector was restored as stationary
    // (the visitStarted event only fires on transition, not after restore)
    if (detector.state == MotionState.stationary &&
        detector.anchorLat != null &&
        detector.visitStartTime != null &&
        firestore != null) {
      try {
        await firestore.collection('active_visit').doc(deviceId).set({
          'latitude': detector.anchorLat,
          'longitude': detector.anchorLng,
          'arrivalTime': detector.visitStartTime!.toIso8601String(),
          'batteryOnArrival': await battery.batteryLevel,
        });
        await _log('_onStart: re-wrote active_visit (restored stationary)');
      } catch (e) {
        await _log('_onStart: active_visit re-write FAILED: $e');
      }
    }

    // Start the timer FIRST, then do initial send.
    final initialFixed = TrackerConstants.fixedIntervalForFrequency(
        updateFrequency, customFrequencySeconds);
    _currentTimerInterval = initialFixed ?? TrackerConstants.movingPollInterval;
    locationTimer =
        Timer.periodic(_currentTimerInterval, (_) => processLocation());
    await _log('_onStart: timer started, doing initial processLocation');
    await processLocation();
    await _log('_onStart: FULLY INITIALIZED — service running');

    service.on('stopService').listen((_) async {
      locationTimer?.cancel();
      await db?.close();
      service.stopSelf();
    });
  }

  static Duration _currentTimerInterval = TrackerConstants.movingPollInterval;

  /// Request battery optimization exemption so Android doesn't kill the service.
  static Future<bool> requestBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isGranted) return true;
    final result = await Permission.ignoreBatteryOptimizations.request();
    return result.isGranted;
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  /// Attempt to open OEM-specific autostart/battery settings.
  static Future<bool> openOemBatterySettings() async {
    if (!Platform.isAndroid) return false;

    const intents = [
      'com.coloros.safecenter/.permission.startup.StartupAppListActivity',
      'com.coloros.safecenter/.startupapp.StartupAppListActivity',
      'com.oppo.safe/.permission.startup.StartupAppListActivity',
      'com.oplus.battery/.BatteryOptimizationActivity',
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      'com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity',
      'com.samsung.android.lool/.activity.SleepingAppsActivity',
      'com.vivo.permissionmanager/.activity.BgStartUpManagerActivity',
    ];

    const platform = MethodChannel('com.financesensei/oem_settings');
    for (final intent in intents) {
      try {
        final result = await platform.invokeMethod<bool>(
          'openActivity',
          {'component': intent},
        );
        if (result == true) return true;
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}

class _ZoneMatch {
  final int zoneId;
  final String zoneName;
  const _ZoneMatch({required this.zoneId, required this.zoneName});
}
