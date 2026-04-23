import 'dart:async';
import 'dart:math' as math;
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/geofence.dart';
import '../core/models/location_data.dart';
import '../core/models/visit.dart';
import '../core/repositories/geofence_repository.dart';
import '../core/services/firebase_service.dart';
import '../core/services/visit_firebase_service.dart';
import '../widgets/battery_badge.dart';
import '../widgets/location_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final TrackerFirebaseService _firebaseService = TrackerFirebaseService();
  final VisitFirebaseService _visitFirebaseService = VisitFirebaseService();
  final GeofenceRepository _geoRepo = GeofenceRepository();

  StreamSubscription<LocationData?>? _locationSub;
  StreamSubscription<Visit?>? _activeVisitSub;
  LocationData? _currentLocation;
  Visit? _activeVisit;
  List<Geofence> _zones = [];
  String? _deviceId;
  bool _autoCenter = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('tracker_paired_device_id');
    if (_deviceId == null) return;

    // Load zones for map display
    _zones = await _geoRepo.getAll();

    // Live location stream
    _locationSub = _firebaseService.locationStream(_deviceId!).listen(
      (data) async {
        if (data != null && mounted) {
          // Refresh zones periodically so new zones appear on map
          final freshZones = await _geoRepo.getAll();
          if (mounted) {
            setState(() {
              _currentLocation = data;
              _zones = freshZones;
            });
          }
          if (_autoCenter) {
            _mapController.move(
              LatLng(data.latitude, data.longitude),
              _mapController.camera.zoom,
            );
          }
        }
      },
      onError: (e) => debugPrint('[VIEWER] locationStream ERROR: $e'),
    );

    // Active visit stream
    _activeVisitSub =
        _visitFirebaseService.activeVisitStream(_deviceId!).listen(
      (visit) async {
        // Refresh zones so local zone resolution stays current
        final freshZones = await _geoRepo.getAll();
        if (mounted) {
          setState(() {
            _activeVisit = visit;
            _zones = freshZones;
          });
        }
      },
      onError: (_) {},
    );

  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _activeVisitSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    if (_deviceId == null) return;
    setState(() => _isLoading = true);

    // Send a locate-now command so a remote tracker sends a fresh GPS reading
    try {
      await FirebaseFirestore.instance
          .collection('commands')
          .doc(_deviceId!)
          .set({
        'locateNow': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    } catch (_) {}

    // Get GPS directly from this device (works when tracker & viewer
    // are on the same device, or as a fallback when BG service is down)
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        final battery = Battery();
        final batteryLevel = await battery.batteryLevel;
        final batteryState = await battery.batteryState;
        final isCharging = batteryState == BatteryState.charging;

        // Write fresh location to Firebase
        await FirebaseFirestore.instance
            .collection('locations')
            .doc(_deviceId!)
            .set({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'batteryLevel': batteryLevel,
          'isCharging': isCharging,
        });

        // Update UI immediately without waiting for Firebase roundtrip
        if (mounted) {
          final locData = LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
            speed: position.speed,
            heading: position.heading,
            accuracy: position.accuracy,
            batteryLevel: batteryLevel,
            isCharging: isCharging,
          );
          setState(() {
            _currentLocation = locData;
            _isLoading = false;
          });
          _mapController.move(
              LatLng(position.latitude, position.longitude), 16);
          _showDetailSheet(locData);
        }
        return;
      }
    } catch (e) {
      debugPrint('[VIEWER] Direct GPS failed: $e');
    }

    // Fallback: wait for remote tracker to respond via Firebase
    await Future.delayed(const Duration(seconds: 5));
    final data = await _firebaseService.getLatestLocation(_deviceId!);
    if (data != null && mounted) {
      setState(() {
        _currentLocation = data;
        _isLoading = false;
      });
      _mapController.move(LatLng(data.latitude, data.longitude), 16);
      _showDetailSheet(data);
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(LocationData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationDetailSheet(location: data),
    );
  }

  void _copyCoordinates() {
    if (_currentLocation == null) return;
    final coords =
        '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $coords'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _timeAgo() {
    if (_currentLocation == null) return '';
    final diff = DateTime.now().difference(_currentLocation!.timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  /// Resolve zone name locally: check if coordinates fall within any known zone.
  String? _resolveZoneName(double lat, double lng) {
    for (final zone in _zones) {
      final dLat = (lat - zone.center.latitude) * 111320;
      final dLng = (lng - zone.center.longitude) *
          111320 *
          math.cos(zone.center.latitude * math.pi / 180);
      final distance = math.sqrt(dLat * dLat + dLng * dLng);
      if (distance <= zone.radiusMeters) return zone.name;
    }
    return null;
  }

  String _activeVisitLabel() {
    if (_activeVisit == null) return '';
    // Use Firebase zone name, or resolve locally from zones list
    final name = _activeVisit!.zoneName ??
        _resolveZoneName(_activeVisit!.latitude, _activeVisit!.longitude) ??
        'Unknown location';
    final dur = DateTime.now().difference(_activeVisit!.arrivalTime);
    if (dur.inHours > 0) {
      return 'At $name for ${dur.inHours}h ${dur.inMinutes % 60}m';
    }
    return 'At $name for ${dur.inMinutes}m';
  }

  /// Reload zones from local DB (call after adding/editing zones).
  Future<void> reloadZones() async {
    final zones = await _geoRepo.getAll();
    if (mounted) setState(() => _zones = zones);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation != null
                ? LatLng(
                    _currentLocation!.latitude, _currentLocation!.longitude)
                : const LatLng(20.5937, 78.9629),
            initialZoom: 15,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) _autoCenter = false;
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.financesensei',
            ),
            // Zone circles
            if (_zones.isNotEmpty)
              CircleLayer(
                circles: _zones
                    .map((z) => CircleMarker(
                          point: z.center,
                          radius: z.radiusMeters,
                          useRadiusInMeter: true,
                          color: Colors.black.withValues(alpha: 0.04),
                          borderColor: Colors.black.withValues(alpha: 0.15),
                          borderStrokeWidth: 1,
                        ))
                    .toList(),
              ),
            // Zone labels
            if (_zones.isNotEmpty)
              MarkerLayer(
                markers: _zones
                    .map((z) => Marker(
                          point: z.center,
                          width: 100,
                          height: 20,
                          child: Center(
                            child: Text(
                              z.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            // Accuracy circle
            if (_currentLocation != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(_currentLocation!.latitude,
                        _currentLocation!.longitude),
                    radius: _currentLocation!.accuracy,
                    useRadiusInMeter: true,
                    color: Colors.black.withValues(alpha: 0.05),
                    borderColor: Colors.black.withValues(alpha: 0.2),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),
            // Location marker
            if (_currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: const _PulsingDot(),
                  ),
                ],
              ),
          ],
        ),

        // Top-left: status info
        Positioned(
          top: 16,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentLocation != null)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_currentLocation!.isLocationServiceEnabled)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE53935),
                              ),
                            )
                          else if (!_currentLocation!.isNetworkAvailable)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          Text(
                            'Updated ${_timeAgo()}'
                            '${_currentLocation!.pendingQueueCount > 0 ? ' · ${_currentLocation!.pendingQueueCount} queued' : ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyCoordinates,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: const Icon(Icons.copy,
                            size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              // Active visit banner
              if (_activeVisit != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _activeVisitLabel(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Top-right: battery badge
        if (_currentLocation != null &&
            _currentLocation!.batteryLevel >= 0)
          Positioned(
            top: 16,
            right: 16,
            child: BatteryBadge(
              level: _currentLocation!.batteryLevel,
              isCharging: _currentLocation!.isCharging,
            ),
          ),

        // Speed badge
        if (_currentLocation != null && _currentLocation!.speedKmh > 1)
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Text(
                '${_currentLocation!.speedKmh.toStringAsFixed(1)} km/h',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),

        // No data state
        if (_currentLocation == null && !_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_searching,
                      size: 32, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 12),
                  Text(
                    'Waiting for location...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Bottom buttons
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Locate button
              GestureDetector(
                onTap: _isLoading ? null : _refreshLocation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.my_location,
                                size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Locate',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),

        // Re-center button
        if (!_autoCenter)
          Positioned(
            bottom: 24,
            left: 16,
            child: GestureDetector(
              onTap: () {
                setState(() => _autoCenter = true);
                if (_currentLocation != null) {
                  _mapController.move(
                    LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    _mapController.camera.zoom,
                  );
                }
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: const Icon(
                  Icons.gps_fixed,
                  size: 20,
                  color: Colors.black,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 40 * (0.5 + _controller.value * 0.5),
              height: 40 * (0.5 + _controller.value * 0.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black
                    .withValues(alpha: 0.15 * (1 - _controller.value)),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

