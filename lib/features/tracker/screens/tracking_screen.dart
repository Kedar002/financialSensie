import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/services/background_service.dart';
import '../core/tracker_constants.dart';
import 'role_selection_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isTracking = false;
  String _lastUpdate = 'Never';
  int _batteryLevel = 0;
  bool _isCharging = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _loadState();
    _updateBattery();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final tracking = prefs.getBool('tracker_is_tracking') ?? false;
    if (mounted) {
      setState(() => _isTracking = tracking);
      if (tracking) _startLocationUpdates();
    }
  }

  Future<void> _updateBattery() async {
    final battery = Battery();
    final level = await battery.batteryLevel;
    final state = await battery.batteryState;
    if (mounted) {
      setState(() {
        _batteryLevel = level;
        _isCharging = state == BatteryState.charging;
      });
    }
  }

  Future<bool> _ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> _sendLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _updateBattery();

      final data = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'batteryLevel': _batteryLevel,
        'isCharging': _isCharging,
      };

      final firestore = FirebaseFirestore.instance;
      await firestore
          .collection('locations')
          .doc(kSharedDeviceId)
          .set(data);

      await firestore
          .collection('location_history')
          .doc(kSharedDeviceId)
          .collection('points')
          .add(data);

      if (mounted) {
        setState(() {
          _lastUpdate = _formatTime(DateTime.now());
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _startLocationUpdates() {
    _sendLocation();
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(
      TrackerConstants.locationInterval,
      (_) => _sendLocation(),
    );
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> _toggleTracking() async {
    if (!_isTracking) {
      final hasPermission = await _ensurePermissions();
      if (!hasPermission) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracker_is_tracking', true);
      // Ensure device ID is set for background service
      await prefs.setString('tracker_device_id', kSharedDeviceId);
      await prefs.setString('tracker_paired_device_id', kSharedDeviceId);
      setState(() => _isTracking = true);

      // Direct Timer for foreground reliability
      _startLocationUpdates();

      // Request battery optimization exemption, then start background service
      try {
        await TrackerBackgroundService.requestBatteryOptimizationExemption();
        await TrackerBackgroundService.startService();
        // One-time prompt for OEM autostart whitelist (OnePlus, Oppo, etc.)
        final shown = prefs.getBool('tracker_oem_dialog_shown') ?? false;
        if (!shown && mounted) {
          await prefs.setBool('tracker_oem_dialog_shown', true);
          await _showOemBatteryDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('BG service error: $e'),
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tracker_is_tracking', false);
      setState(() => _isTracking = false);

      _stopLocationUpdates();

      try {
        await TrackerBackgroundService.stopService();
      } catch (e) {
        debugPrint('Stop service error: $e');
      }
    }
  }

  Future<void> _showOemBatteryDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keep tracking alive'),
        content: const Text(
          'OnePlus and Oppo devices aggressively stop background apps. '
          'To keep location tracking running after you close the app:\n\n'
          '1. Tap "Open Settings" below\n'
          '2. Find this app and enable Autostart\n'
          '3. Also go to Battery → App battery management → set this app to "Unrestricted"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final opened =
                  await TrackerBackgroundService.openOemBatterySettings();
              if (!opened && mounted) {
                // Fallback: open generic app settings
                await openAppSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _resetRole() async {
    final prefs = await SharedPreferences.getInstance();
    _stopLocationUpdates();
    try {
      await TrackerBackgroundService.stopService();
    } catch (_) {}
    await prefs.remove('tracker_role');
    await prefs.remove('tracker_device_id');
    await prefs.remove('tracker_is_tracking');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 22),
                    onPressed: _resetRole,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: const Color(0xFF888888),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Location Tracker',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _toggleTracking,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isTracking ? Colors.black : const Color(0xFFFAFAFA),
                  border: Border.all(
                    color: _isTracking
                        ? Colors.black
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _isTracking
                      ? Icons.location_on
                      : Icons.location_off_outlined,
                  size: 40,
                  color: _isTracking ? Colors.white : const Color(0xFFCCCCCC),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isTracking ? 'Tracking Active' : 'Tracking Paused',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _isTracking
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last update: $_lastUpdate',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCharging
                        ? Icons.battery_charging_full
                        : Icons.battery_full,
                    size: 16,
                    color: const Color(0xFF888888),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sharing battery: $_batteryLevel%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
