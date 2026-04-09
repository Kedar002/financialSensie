import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/tracker_settings.dart';
import '../core/services/background_service.dart';
import '../widgets/glass_card.dart';

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

  void _update(TrackerSettings Function(TrackerSettings) updater) {
    final old = _settings;
    setState(() => _settings = updater(_settings));
    _settings.save();
    if (_settings.updateFrequency != old.updateFrequency) {
      TrackerBackgroundService.updateFrequency(_settings.updateFrequency);
    }
  }

  Future<void> _disconnect() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tracker_role');
    await prefs.remove('tracker_paired_device_id');
    if (mounted) Navigator.of(context).pop();
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

        // Display
        _SectionTitle('Display'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _ToggleRow(
                label: 'Show speed on map',
                value: _settings.showSpeedOnMap,
                onChanged: (v) =>
                    _update((s) => s.copyWith(showSpeedOnMap: v)),
              ),
              const _Divider(),
              _ToggleRow(
                label: 'Show battery on map',
                value: _settings.showBatteryOnMap,
                onChanged: (v) =>
                    _update((s) => s.copyWith(showBatteryOnMap: v)),
              ),
              const _Divider(),
              _ToggleRow(
                label: 'Show accuracy circle',
                value: _settings.showAccuracyCircle,
                onChanged: (v) =>
                    _update((s) => s.copyWith(showAccuracyCircle: v)),
              ),
              const _Divider(),
              _ToggleRow(
                label: 'Show location trail',
                value: _settings.showTrail,
                onChanged: (v) => _update((s) => s.copyWith(showTrail: v)),
              ),
              const _Divider(),
              _ToggleRow(
                label: 'Pulsing animation',
                value: _settings.pulsingAnimation,
                onChanged: (v) =>
                    _update((s) => s.copyWith(pulsingAnimation: v)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Units
        _SectionTitle('Units'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _ToggleRow(
                label: 'Use kilometers',
                value: _settings.useKm,
                onChanged: (v) => _update((s) => s.copyWith(useKm: v)),
              ),
              const _Divider(),
              _ToggleRow(
                label: '24-hour time',
                value: _settings.use24hr,
                onChanged: (v) => _update((s) => s.copyWith(use24hr: v)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Alerts
        _SectionTitle('Alerts'),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            children: [
              _OptionRow(
                label: 'Movement alert',
                value: _settings.movementAlertMinutes == 0
                    ? 'Off'
                    : '${_settings.movementAlertMinutes} min',
                options: ['Off', '5 min', '10 min', '15 min', '30 min'],
                onSelected: (v) {
                  final mins =
                      v == 'Off' ? 0 : int.parse(v.replaceAll(' min', ''));
                  _update((s) => s.copyWith(movementAlertMinutes: mins));
                },
              ),
              const _Divider(),
              _OptionRow(
                label: 'Low battery alert',
                value: _settings.lowBatteryThreshold == 0
                    ? 'Off'
                    : '${_settings.lowBatteryThreshold}%',
                options: ['Off', '10%', '15%', '20%', '25%'],
                onSelected: (v) {
                  final pct =
                      v == 'Off' ? 0 : int.parse(v.replaceAll('%', ''));
                  _update((s) => s.copyWith(lowBatteryThreshold: pct));
                },
              ),
              const _Divider(),
              _OptionRow(
                label: 'Connection lost',
                value: _settings.connectionLostMinutes == 0
                    ? 'Off'
                    : '${_settings.connectionLostMinutes} min',
                options: ['Off', '5 min', '10 min', '15 min'],
                onSelected: (v) {
                  final mins =
                      v == 'Off' ? 0 : int.parse(v.replaceAll(' min', ''));
                  _update((s) => s.copyWith(connectionLostMinutes: mins));
                },
              ),
            ],
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
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Disconnect
        GestureDetector(
          onTap: _disconnect,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Disconnect',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

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

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 26,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              color: value ? Colors.black : const Color(0xFFE0E0E0),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}

class _OptionRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;

  const _OptionRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((option) => GestureDetector(
                      onTap: () {
                        onSelected(option);
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        color: option == value
                            ? const Color(0xFFFAFAFA)
                            : Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: option == value
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: Colors.black,
                              ),
                            ),
                            if (option == value)
                              const Icon(Icons.check,
                                  size: 18, color: Colors.black),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: Color(0xFFCCCCCC)),
            ],
          ),
        ],
      ),
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
