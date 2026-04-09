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
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../tracker_constants.dart';

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

  static Duration _frequencyToDuration(String frequency) {
    // Uses central constant – change TrackerConstants.locationInterval to adjust
    return TrackerConstants.locationInterval;
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
    // Catch-all: any unhandled error in this isolate must NOT crash the service.
    runZonedGuarded(() async {
      await _startService(service);
    }, (error, stack) async {
      await _log('UNCAUGHT ERROR: $error\n$stack');
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _startService(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();
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
    final deviceId = prefs.getString('tracker_device_id') ?? '';
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
      await _log('_onStart: SQLite ready');
    } catch (e) {
      await _log('_onStart: SQLite FAILED: $e');
    }

    // --- Settings ---
    String frequency = 'normal';
    int movementAlertMinutes = 0;
    int lowBatteryThreshold = 0;
    final settingsJson = prefs.getString('tracker_settings');
    if (settingsJson != null) {
      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      frequency = settings['updateFrequency'] as String? ?? 'normal';
      movementAlertMinutes = settings['movementAlertMinutes'] as int? ?? 0;
      lowBatteryThreshold = settings['lowBatteryThreshold'] as int? ?? 0;
    }

    Timer? locationTimer;
    DateTime? stationarySince;
    bool lowBatteryAlerted = false;

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

    Future<void> syncPending() async {
      if (firestore == null || db == null) return;
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
          };
          await firestore.collection('locations').doc(deviceId).set(data);
          await firestore
              .collection('location_history')
              .doc(deviceId)
              .collection('points')
              .add(data);
          await db.delete('offline_location_queue',
              where: 'id = ?', whereArgs: [row['id']]);
        }
      } catch (_) {}
    }

    final insideZones = <int>{};

    Future<void> checkGeofences(double lat, double lng) async {
      if (db == null) return;
      try {
        final zones = await db.query('geofences');
        for (final row in zones) {
          final zoneId = row['id'] as int;
          final zoneLat = (row['latitude'] as num).toDouble();
          final zoneLng = (row['longitude'] as num).toDouble();
          final radius = (row['radius_meters'] as num).toDouble();
          final notifyEnter = row['notify_on_enter'] == 1;
          final notifyExit = row['notify_on_exit'] == 1;
          final name = row['name'] as String;

          final dLat = (lat - zoneLat) * 111320;
          final dLng = (lng - zoneLng) *
              111320 *
              math.cos(zoneLat * 3.14159265 / 180);
          final distance = math.sqrt(dLat * dLat + dLng * dLng);

          final wasInside = insideZones.contains(zoneId);
          final isInside = distance <= radius;

          if (isInside && !wasInside) {
            insideZones.add(zoneId);
            if (notifyEnter) {
              showAlert('Entered $name', 'Device entered the $name zone');
            }
          } else if (!isInside && wasInside) {
            insideZones.remove(zoneId);
            if (notifyExit) {
              showAlert('Left $name', 'Device left the $name zone');
            }
          }
        }
      } catch (_) {}
    }

    Future<void> sendLocation() async {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final batteryLevel = await battery.batteryLevel;
        final batteryState = await battery.batteryState;

        await checkGeofences(position.latitude, position.longitude);

        if (movementAlertMinutes > 0) {
          if (position.speed < 1.0) {
            stationarySince ??= DateTime.now();
          } else {
            if (stationarySince != null) {
              final stationaryDuration =
                  DateTime.now().difference(stationarySince!);
              if (stationaryDuration.inMinutes >= movementAlertMinutes) {
                showAlert('Movement Detected',
                    'Device started moving after ${stationaryDuration.inMinutes} minutes');
              }
            }
            stationarySince = null;
          }
        }

        if (lowBatteryThreshold > 0 &&
            batteryLevel <= lowBatteryThreshold &&
            !lowBatteryAlerted) {
          lowBatteryAlerted = true;
          showAlert('Low Battery', 'Battery at $batteryLevel%');
        } else if (batteryLevel > lowBatteryThreshold) {
          lowBatteryAlerted = false;
        }

        final data = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'batteryLevel': batteryLevel,
          'isCharging': batteryState == BatteryState.charging,
        };

        bool firebaseOk = false;
        if (firestore != null) {
          try {
            await firestore.collection('locations').doc(deviceId).set(data);
            await firestore
                .collection('location_history')
                .doc(deviceId)
                .collection('points')
                .add(data);
            firebaseOk = true;
            await syncPending();
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
            'is_charging': batteryState == BatteryState.charging ? 1 : 0,
            'timestamp': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        int pendingCount = 0;
        if (db != null) {
          pendingCount = Sqflite.firstIntValue(
              await db.rawQuery(
                  'SELECT COUNT(*) FROM offline_location_queue')) ?? 0;
        }

        if (service is AndroidServiceInstance) {
          final suffix = pendingCount > 0 ? ' • $pendingCount queued' : '';
          service.setForegroundNotificationInfo(
            title: 'Location sharing active',
            content: 'Battery: $batteryLevel% • Updated just now$suffix',
          );
        }
        await _log('sendLocation: OK lat=${position.latitude}');
      } catch (e) {
        await _log('sendLocation: ERROR $e');
      }
    }

    void startTimer(String freq) {
      locationTimer?.cancel();
      final duration = _frequencyToDuration(freq);
      locationTimer = Timer.periodic(duration, (_) => sendLocation());
      _log('startTimer: interval=${duration.inSeconds}s');
    }

    // Start the timer FIRST, then do initial send.
    // This ensures the timer is running even if the first send fails.
    startTimer(frequency);
    await _log('_onStart: timer started, doing initial send');
    await sendLocation();
    await _log('_onStart: FULLY INITIALIZED — service running');

    service.on('updateFrequency').listen((event) {
      if (event != null && event['frequency'] is String) {
        frequency = event['frequency'] as String;
        startTimer(frequency);
      }
    });

    service.on('stopService').listen((_) async {
      locationTimer?.cancel();
      await db?.close();
      service.stopSelf();
    });
  }

  /// Request battery optimization exemption so Android doesn't kill the service.
  /// Call this before starting the service.
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

  static void updateFrequency(String frequency) {
    final service = FlutterBackgroundService();
    service.invoke('updateFrequency', {'frequency': frequency});
  }

  /// Attempt to open OEM-specific autostart/battery settings.
  /// OnePlus, Oppo, Xiaomi, Huawei, Samsung etc. have proprietary battery
  /// killers that ignore standard Android battery optimization exemptions.
  /// Returns true if an intent was launched successfully.
  static Future<bool> openOemBatterySettings() async {
    if (!Platform.isAndroid) return false;

    const intents = [
      // OnePlus / Oppo (ColorOS / OxygenOS)
      'com.coloros.safecenter/.permission.startup.StartupAppListActivity',
      'com.coloros.safecenter/.startupapp.StartupAppListActivity',
      'com.oppo.safe/.permission.startup.StartupAppListActivity',
      'com.oplus.battery/.BatteryOptimizationActivity',
      // Xiaomi / MIUI
      'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
      // Huawei
      'com.huawei.systemmanager/.startupmgr.ui.StartupNormalAppListActivity',
      // Samsung
      'com.samsung.android.lool/.activity.SleepingAppsActivity',
      // Vivo
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
