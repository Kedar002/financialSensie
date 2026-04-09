import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/location_data.dart';
import '../core/models/tracker_settings.dart';
import '../core/services/firebase_service.dart';
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
  StreamSubscription<LocationData?>? _locationSub;
  StreamSubscription<List<LocationData>>? _trailSub;
  LocationData? _currentLocation;
  List<LatLng> _trailPoints = [];
  String? _deviceId;
  bool _autoCenter = true;
  bool _isLoading = false;
  TrackerSettings _settings = const TrackerSettings();
  Timer? _connectionTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _settings = await TrackerSettings.load();
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('tracker_paired_device_id');
    debugPrint('[VIEWER] _init: deviceId=$_deviceId');
    if (_deviceId == null) return;

    _locationSub = _firebaseService.locationStream(_deviceId!).listen(
      (data) {
        debugPrint('[VIEWER] locationStream got data: $data');
        if (data != null && mounted) {
          setState(() => _currentLocation = data);
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

    // Trail data
    _trailSub =
        _firebaseService.locationHistory(_deviceId!, limit: 50).listen(
      (list) {
        debugPrint('[VIEWER] historyStream got ${list.length} points');
        if (mounted) {
          setState(() {
            _trailPoints = list.reversed
                .map((d) => LatLng(d.latitude, d.longitude))
                .toList();
          });
        }
      },
      onError: (e) => debugPrint('[VIEWER] historyStream ERROR: $e'),
    );

    // Connection lost check
    _startConnectionCheck();
  }

  void _startConnectionCheck() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_settings.connectionLostMinutes > 0 && _currentLocation != null) {
        final diff = DateTime.now().difference(_currentLocation!.timestamp);
        if (diff.inMinutes >= _settings.connectionLostMinutes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'No update for ${diff.inMinutes} minutes'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _trailSub?.cancel();
    _connectionTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _refreshLocation() async {
    if (_deviceId == null) return;
    setState(() => _isLoading = true);

    final data = await _firebaseService.getLatestLocation(_deviceId!);
    if (data != null && mounted) {
      setState(() {
        _currentLocation = data;
        _isLoading = false;
      });
      _mapController.move(LatLng(data.latitude, data.longitude), 16);
      _showDetailSheet(data);
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(LocationData data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationDetailSheet(
        location: data,
        useKm: _settings.useKm,
      ),
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
            // Trail polyline
            if (_settings.showTrail && _trailPoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _trailPoints,
                    color: Colors.black.withValues(alpha: 0.4),
                    strokeWidth: 3,
                  ),
                ],
              ),
            // Accuracy circle
            if (_settings.showAccuracyCircle && _currentLocation != null)
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
                    child: _settings.pulsingAnimation
                        ? const _PulsingDot()
                        : const _StaticDot(),
                  ),
                ],
              ),
          ],
        ),

        // Top-left: last updated + copy
        if (_currentLocation != null)
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Text(
                    'Updated ${_timeAgo()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF888888),
                    ),
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
                    child: const Icon(Icons.copy, size: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),

        // Top-right: battery badge
        if (_settings.showBatteryOnMap &&
            _currentLocation != null &&
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
        if (_settings.showSpeedOnMap &&
            _currentLocation != null &&
            _currentLocation!.speedKmh > 1)
          Positioned(
            bottom: 100,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Text(
                _settings.useKm
                    ? '${_currentLocation!.speedKmh.toStringAsFixed(1)} km/h'
                    : '${_currentLocation!.speedMph.toStringAsFixed(1)} mph',
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

        // FAB: Get current location
        Positioned(
          bottom: 24,
          right: 16,
          child: GestureDetector(
            onTap: _isLoading ? null : _refreshLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        Icon(Icons.my_location, size: 18, color: Colors.white),
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

class _StaticDot extends StatelessWidget {
  const _StaticDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }
}
