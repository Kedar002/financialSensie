import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/tracker_settings.dart';
import '../core/services/foreground_tracker.dart';
import '../core/services/background_service.dart';
import '../../../../core/database/database_service.dart';
import '../widgets/glass_card.dart';
import 'tracker_dev_tools_screen.dart';

class TrackerSettingsScreen extends StatefulWidget {
  const TrackerSettingsScreen({super.key});

  @override
  State<TrackerSettingsScreen> createState() => _TrackerSettingsScreenState();
}

class _TrackerSettingsScreenState extends State<TrackerSettingsScreen> {
  TrackerSettings _settings = const TrackerSettings();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await TrackerSettings.load();
    setState(() => _settings = settings);
  }

  Future<void> _update(TrackerSettings Function(TrackerSettings) updater) async {
    setState(() => _settings = updater(_settings));
    await _settings.save();
    // Sync to Firebase so the background service picks it up immediately
    // (SharedPreferences.reload() across isolates is unreliable)
    _syncToFirebase();
  }

  Future<void> _syncToFirebase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('tracker_paired_device_id') ?? '';
      if (deviceId.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('tracker_settings')
          .doc(deviceId)
          .set(_settings.toJson());
    } catch (_) {}
  }

  Future<void> _togglePause() async {
    final wasPaused = _settings.isPaused;
    await _update((s) => s.copyWith(isPaused: !wasPaused));
    if (!wasPaused) {
      // Pausing — stop the foreground tracker's timer
      await ForegroundTracker.instance.pause();
    } else {
      // Resuming — restart the foreground tracker
      await ForegroundTracker.instance.resume();
    }
  }

  // Disconnect — hidden, functionality preserved for future use
  // Future<void> _disconnect() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.remove('tracker_role');
  //   await prefs.remove('tracker_paired_device_id');
  //   if (mounted) Navigator.of(context).pop();
  // }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete all data?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: const Text(
          'This will delete all visits, location history, and tracking data. Zones will be kept. Tracking will be stopped and restarted fresh.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Stop tracking
    await ForegroundTracker.instance.stop();
    try {
      await TrackerBackgroundService.stopService();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('tracker_paired_device_id') ?? '';

    // Clear Firebase data
    if (deviceId.isNotEmpty) {
      final firestore = FirebaseFirestore.instance;
      try {
        // Delete all completed visits
        final visitsDocs = await firestore
            .collection('visits')
            .doc(deviceId)
            .collection('records')
            .get();
        final batch = firestore.batch();
        for (final doc in visitsDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        // Delete active visit
        await firestore.collection('active_visit').doc(deviceId).delete();

        // Delete location history (in batches of 500)
        QuerySnapshot historySnap;
        do {
          historySnap = await firestore
              .collection('location_history')
              .doc(deviceId)
              .collection('points')
              .limit(500)
              .get();
          if (historySnap.docs.isNotEmpty) {
            final hBatch = firestore.batch();
            for (final doc in historySnap.docs) {
              hBatch.delete(doc.reference);
            }
            await hBatch.commit();
          }
        } while (historySnap.docs.length == 500);

        // Delete current location
        await firestore.collection('locations').doc(deviceId).delete();

        // Delete commands
        await firestore.collection('commands').doc(deviceId).delete();

        // Delete tracker settings from Firebase
        await firestore
            .collection('tracker_settings')
            .doc(deviceId)
            .delete();
      } catch (_) {}
    }

    // Clear local SQLite (visits + offline queue, keep geofences + zone_settings)
    try {
      final db = await DatabaseService().database;
      await db.delete('visits');
      try {
        await db.delete('offline_location_queue');
      } catch (_) {}
    } catch (_) {}

    // Reset tracking state in SharedPreferences
    await prefs.remove('tracker_is_tracking');
    await prefs.remove('tracker_detector_state');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data deleted'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 32),

        // Pause / Resume
        GestureDetector(
          onTap: _togglePause,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _settings.isPaused ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _settings.isPaused
                    ? const Color(0xFFE0E0E0)
                    : Colors.black,
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _settings.isPaused ? Icons.play_arrow : Icons.pause,
                  size: 20,
                  color: _settings.isPaused ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _settings.isPaused ? 'Resume Tracking' : 'Pause Tracking',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _settings.isPaused ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_settings.isPaused)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Tracking is paused. No GPS or location data is being collected.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF888888),
              ),
            ),
          ),

        const SizedBox(height: 32),

        // Update frequency
        _SectionTitle('Update Frequency'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _FrequencyOption(
                label: 'Smart',
                subtitle: '30s moving · 2min stationary · zone overrides',
                isSelected: _settings.updateFrequency == 'smart',
                onTap: () =>
                    _update((s) => s.copyWith(updateFrequency: 'smart')),
              ),
              if (_settings.updateFrequency == 'smart')
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    'Polls faster while moving, slows down when stationary to save battery. '
                    'Per-zone intervals override the stationary rate.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFAAAAAA),
                      height: 1.4,
                    ),
                  ),
                ),
              const _Divider(),
              _FrequencyOption(
                label: 'Real-time',
                subtitle: '10 seconds',
                isSelected: _settings.updateFrequency == 'realtime',
                onTap: () =>
                    _update((s) => s.copyWith(updateFrequency: 'realtime')),
              ),
              const _Divider(),
              _FrequencyOption(
                label: 'Normal',
                subtitle: '30 seconds',
                isSelected: _settings.updateFrequency == 'normal',
                onTap: () =>
                    _update((s) => s.copyWith(updateFrequency: 'normal')),
              ),
              const _Divider(),
              _FrequencyOption(
                label: 'Power Saver',
                subtitle: '2 minutes',
                isSelected: _settings.updateFrequency == 'power_saver',
                onTap: () =>
                    _update((s) => s.copyWith(updateFrequency: 'power_saver')),
              ),
              const _Divider(),
              _FrequencyOption(
                label: 'Custom',
                subtitle: _settings.updateFrequency == 'custom'
                    ? '${_settings.customFrequencySeconds}s'
                    : 'Set your own interval',
                isSelected: _settings.updateFrequency == 'custom',
                onTap: () =>
                    _update((s) => s.copyWith(updateFrequency: 'custom')),
              ),
            ],
          ),
        ),
        if (_settings.updateFrequency == 'custom') ...[
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Interval (seconds)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: TextEditingController(
                      text: '${_settings.customFrequencySeconds}',
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                    onSubmitted: (v) {
                      final seconds = int.tryParse(v);
                      if (seconds != null && seconds >= 5) {
                        _update(
                            (s) => s.copyWith(customFrequencySeconds: seconds));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Delete all data
        _SectionTitle('Data'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _deleteAllData,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE53935)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Delete All Data',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Deletes visits, location history, and tracking data. Zones are kept.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Color(0xFFAAAAAA),
          ),
        ),

        if (kDebugMode) ...[
          const SizedBox(height: 32),
          _SectionTitle('Developer'),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const TrackerDevToolsScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Open Dev Tools',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Debug-only harness for bug-fix verification.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],

        // // Disconnect — hidden, functionality preserved for future use
        // const SizedBox(height: 24),
        // GestureDetector(
        //   onTap: _disconnect,
        //   child: Container(
        //     width: double.infinity,
        //     padding: const EdgeInsets.symmetric(vertical: 16),
        //     decoration: BoxDecoration(
        //       color: const Color(0xFFE53935),
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     alignment: Alignment.center,
        //     child: const Text(
        //       'Disconnect',
        //       style: TextStyle(
        //         fontSize: 17,
        //         fontWeight: FontWeight.w600,
        //         color: Colors.white,
        //       ),
        //     ),
        //   ),
        // ),

        const SizedBox(height: 32),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF888888),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}


class _FrequencyOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : const Color(0xFFE0E0E0),
                width: isSelected ? 6 : 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
