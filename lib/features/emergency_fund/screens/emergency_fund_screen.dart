import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import 'add_fund_screen.dart';

/// Emergency Fund screen - shows runway and progress.
/// Clean, focused on the key metric: months of safety.
class EmergencyFundScreen extends StatelessWidget {
  const EmergencyFundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Emergency Fund'),
        actions: [
          TextButton(
            onPressed: () => _addToFund(context),
            child: const Text(
              'Add',
              style: TextStyle(
                color: AppTheme.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRunwayCard(context),
              const SizedBox(height: AppTheme.spacing24),
              _buildProgressCard(context),
              const SizedBox(height: AppTheme.spacing24),
              _buildDetailsCard(context),
              const SizedBox(height: AppTheme.spacing32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: ElevatedButton(
            onPressed: () => _addToFund(context),
            child: const Text('Add to Fund'),
          ),
        ),
      ),
    );
  }

  Widget _buildRunwayCard(BuildContext context) {
    // Placeholder values
    const runway = 2.3;

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
            Formatters.months(runway),
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
    // Placeholder values
    const progress = 38.0;
    const current = 75000.0;
    const target = 200000.0;

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
                Formatters.percentage(progress),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          const ProgressBar(progress: progress),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(current),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.currencyCompact(target),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    // Placeholder values
    const targetMonths = 6;
    const monthlyExpenses = 33000.0;
    const target = 200000.0;
    const remaining = 125000.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Target ($targetMonths months)',
            Formatters.currency(target),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            context,
            'Monthly essentials',
            Formatters.currency(monthlyExpenses),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            context,
            'Still needed',
            Formatters.currency(remaining),
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
                const Icon(Icons.info_outline, size: 16, color: AppTheme.gray600),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Based on ${Formatters.currency(monthlyExpenses)}/month essential expenses x $targetMonths months',
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

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool bold = false}) {
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

  void _addToFund(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const AddFundScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && context.mounted) {
      // TODO: Save to database when implemented
      final amount = result['amount'] as double;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${Formatters.currency(amount)} to emergency fund'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
