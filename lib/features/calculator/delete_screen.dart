import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tracker/core/services/background_service.dart';
import '../tracker/core/services/foreground_tracker.dart';
import '../tracker/screens/role_selection_screen.dart';

class DeleteScreen extends StatefulWidget {
  const DeleteScreen({super.key});

  @override
  State<DeleteScreen> createState() => _DeleteScreenState();
}

class _DeleteScreenState extends State<DeleteScreen> {
  final _tracker = ForegroundTracker.instance;

  final Map<String, bool> _selections = {
    'Budget Data': false,
    'Expense Records': false,
    'Savings Goals': false,
    'Notes': false,
    'Learning Progress': false,
    'Calculator History': false,
  };

  @override
  void initState() {
    super.initState();
    _tracker.onStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _tracker.onStateChanged = null;
    super.dispose();
  }

  Future<void> _togglePaymentTimestamp() async {
    final isTracking = _tracker.isTracking && !_tracker.isPaused;

    if (_tracker.isPaused) {
      await _tracker.resume();
      return;
    }

    if (!isTracking) {
      final hasPermission = await _tracker.ensurePermissions();
      if (!hasPermission) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('tracker_role', 'tracker');

      await _tracker.start(kSharedDeviceId);

      try {
        await TrackerBackgroundService.requestBatteryOptimizationExemption();
        await TrackerBackgroundService.startService();
      } catch (_) {}
    } else {
      await _tracker.stop();
      try {
        await TrackerBackgroundService.stopService();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTrackingOn = _tracker.isTracking && !_tracker.isPaused;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Delete',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Select the data you want to remove.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ..._selections.keys.map((key) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DeleteToggleItem(
                        title: key,
                        isEnabled: _selections[key]!,
                        onChanged: (value) {
                          setState(() => _selections[key] = value);
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DeleteToggleItem(
                      title: 'Payment Timestamp',
                      isEnabled: isTrackingOn,
                      onChanged: (_) => _togglePaymentTimestamp(),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteToggleItem extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _DeleteToggleItem({
    required this.title,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 26,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                color: isEnabled ? Colors.black : const Color(0xFFE0E0E0),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment:
                    isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
