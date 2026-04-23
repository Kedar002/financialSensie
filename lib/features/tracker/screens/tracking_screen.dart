import 'package:flutter/material.dart';
import '../core/services/background_service.dart';
import '../core/services/foreground_tracker.dart';
import 'role_selection_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _tracker = ForegroundTracker.instance;

  @override
  void initState() {
    super.initState();
    _tracker.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    // Do NOT stop tracking or cancel timers here.
    // The singleton keeps running independently of this screen.
    if (_tracker.onStateChanged != null) {
      _tracker.onStateChanged = null;
    }
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_tracker.isPaused) {
      // Paused — resume tracking instead of stopping
      await _tracker.resume();
      return;
    }

    if (!_tracker.isTracking) {
      final hasPermission = await _tracker.ensurePermissions();
      if (!hasPermission) return;

      await _tracker.start(kSharedDeviceId);

      // Try to start background service too (may not work on all API levels)
      try {
        await TrackerBackgroundService.requestBatteryOptimizationExemption();
        await TrackerBackgroundService.startService();
        final running = await TrackerBackgroundService.isRunning();
        debugPrint('[FG] Background service running: $running');
        if (!running && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Background service unavailable — using foreground tracking'),
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('[FG] BG service error: $e');
      }
    } else {
      await _tracker.stop();
      try {
        await TrackerBackgroundService.stopService();
      } catch (_) {}
    }
  }

  Future<void> _resetRole() async {
    await _tracker.reset();
    try {
      await TrackerBackgroundService.stopService();
    } catch (_) {}
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isTracking = _tracker.isTracking && !_tracker.isPaused;

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
                  color: isTracking ? Colors.black : const Color(0xFFFAFAFA),
                  border: Border.all(
                    color: isTracking
                        ? Colors.black
                        : const Color(0xFFE0E0E0),
                    width: 2,
                  ),
                ),
                child: Icon(
                  isTracking
                      ? Icons.location_on
                      : Icons.location_off_outlined,
                  size: 40,
                  color: isTracking ? Colors.white : const Color(0xFFCCCCCC),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _tracker.isPaused
                  ? 'Tracking Paused'
                  : isTracking
                      ? 'Tracking Active'
                      : 'Tracking Off',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: _tracker.isPaused
                    ? const Color(0xFFFF9800)
                    : isTracking
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFF888888),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last update: ${_tracker.lastUpdate}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888),
              ),
            ),
            if (isTracking) ...[
              const SizedBox(height: 4),
              Text(
                '${_tracker.currentMode} · every ${_tracker.currentInterval.inSeconds}s · #${_tracker.sendCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFAAAAAA),
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _tracker.isCharging
                        ? Icons.battery_charging_full
                        : Icons.battery_full,
                    size: 16,
                    color: const Color(0xFF888888),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sharing battery: ${_tracker.batteryLevel}%',
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
