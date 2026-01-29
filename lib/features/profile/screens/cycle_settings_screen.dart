import 'package:flutter/material.dart';
import '../../../core/models/cycle_settings.dart';
import '../../../core/theme/app_theme.dart';

/// Cycle settings screen.
/// Choose when your budget cycle starts.
/// Simple. Two options.
class CycleSettingsScreen extends StatefulWidget {
  final CycleSettings currentSettings;

  const CycleSettingsScreen({
    super.key,
    required this.currentSettings,
  });

  @override
  State<CycleSettingsScreen> createState() => _CycleSettingsScreenState();
}

class _CycleSettingsScreenState extends State<CycleSettingsScreen> {
  late CycleType _selectedType;
  late int _customDay;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.currentSettings.type;
    _customDay = widget.currentSettings.customStartDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'When does your budget cycle start?',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildOption(
                      context,
                      type: CycleType.calendarMonth,
                      title: 'Calendar month',
                      subtitle: '1st to end of month',
                    ),
                    const SizedBox(height: AppTheme.spacing12),
                    _buildOption(
                      context,
                      type: CycleType.customDay,
                      title: 'Paycheck cycle',
                      subtitle: 'Custom start day',
                    ),
                    if (_selectedType == CycleType.customDay) ...[
                      const SizedBox(height: AppTheme.spacing24),
                      _buildDaySelector(context),
                    ],
                    const SizedBox(height: AppTheme.spacing32),
                    _buildPreview(context),
                  ],
                ),
              ),
            ),
            _buildSaveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.black,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Text(
            'Budget Cycle',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required CycleType type,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.black : AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppTheme.black : AppTheme.gray200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isSelected ? AppTheme.white : AppTheme.black,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? AppTheme.gray300 : AppTheme.gray500,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.white : AppTheme.gray300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: AppTheme.black,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start day',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Row(
            children: [
              _buildDayButton(context, decrease: true),
              Expanded(
                child: Center(
                  child: Text(
                    _ordinal(_customDay),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              _buildDayButton(context, decrease: false),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Choose a day between 1st and 28th to avoid issues with short months.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
      ],
    );
  }

  Widget _buildDayButton(BuildContext context, {required bool decrease}) {
    final canDecrease = _customDay > 1;
    final canIncrease = _customDay < 28;
    final isEnabled = decrease ? canDecrease : canIncrease;

    return GestureDetector(
      onTap: isEnabled
          ? () {
              setState(() {
                if (decrease) {
                  _customDay--;
                } else {
                  _customDay++;
                }
              });
            }
          : null,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Center(
          child: Icon(
            decrease ? Icons.remove : Icons.add,
            color: isEnabled ? AppTheme.black : AppTheme.gray300,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final settings = CycleSettings(
      type: _selectedType,
      customStartDay: _customDay,
    );
    final dates = settings.getCurrentCycleDates();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current cycle',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '${_formatDate(dates.start)} → ${_formatDate(dates.end)}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            '${dates.end.difference(dates.start).inDays + 1} days',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: ElevatedButton(
        onPressed: _save,
        child: const Text('Save'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  String _ordinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  void _save() {
    final settings = CycleSettings(
      type: _selectedType,
      customStartDay: _customDay,
    );
    Navigator.pop(context, settings);
  }
}
