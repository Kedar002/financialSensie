import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import 'add_fund_screen.dart';

/// Emergency Fund screen - the Safety tab.
/// Shows runway and progress towards emergency fund goal.
/// Clean, focused on the key metric: months of safety.
class EmergencyFundScreen extends StatefulWidget {
  const EmergencyFundScreen({super.key});

  @override
  State<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  final EmergencyFundRepository _fundRepo = EmergencyFundRepository();
  final SettingsRepository _settingsRepo = SettingsRepository();

  // Loaded from database
  int _currentAmount = 0;
  int _targetMonths = 6;
  int _monthlyEssentials = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final currentAmount = await _fundRepo.getCurrentAmount();
    final targetMonths = await _fundRepo.getTargetMonths();
    final monthlyEssentials = await _settingsRepo.calculateMonthlyEssentials();

    // Sync monthly essentials to fund
    await _fundRepo.syncMonthlyEssentials(monthlyEssentials);

    if (mounted) {
      setState(() {
        _currentAmount = currentAmount;
        _targetMonths = targetMonths;
        _monthlyEssentials = monthlyEssentials;
        _isLoading = false;
      });
    }
  }

  int get _targetAmount => _monthlyEssentials * _targetMonths;
  double get _runway =>
      _monthlyEssentials > 0 ? _currentAmount / _monthlyEssentials : 0;
  double get _progress =>
      _targetAmount > 0 ? (_currentAmount / _targetAmount * 100).clamp(0, 100) : 0;
  int get _remaining => (_targetAmount - _currentAmount).clamp(0, _targetAmount);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.black,
              ),
            )
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppTheme.spacing24),
                  Text(
                    'Safety',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing32),
                  _buildRunwayCard(context),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildProgressCard(context),
                  const SizedBox(height: AppTheme.spacing24),
                  _buildDetailsCard(context),
                  const SizedBox(height: AppTheme.spacing32),
                  _buildAddButton(context),
                  const SizedBox(height: AppTheme.spacing64),
                ],
              ),
            ),
    );
  }

  Widget _buildRunwayCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can survive',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.months(_runway),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'without income',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                Formatters.percentage(_progress),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: _progress),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(
                    AmountConverter.toRupees(_currentAmount)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.currencyCompact(
                    AmountConverter.toRupees(_targetAmount)),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Target ($_targetMonths months)',
            Formatters.currency(AmountConverter.toRupees(_targetAmount)),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            context,
            'Monthly essentials',
            Formatters.currency(AmountConverter.toRupees(_monthlyEssentials)),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            context,
            'Still needed',
            Formatters.currency(AmountConverter.toRupees(_remaining)),
            bold: true,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.gray600),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Based on ${Formatters.currency(AmountConverter.toRupees(_monthlyEssentials))}/month essential expenses x $_targetMonths months',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: bold
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _addToFund(context),
      child: const Text('Add to Fund'),
    );
  }

  void _addToFund(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const AddFundScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && context.mounted) {
      final amount = result['amount'] as double;

      // Add contribution to database
      await _fundRepo.addContribution(amount: amount);

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Added ${Formatters.currency(amount)} to emergency fund'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
