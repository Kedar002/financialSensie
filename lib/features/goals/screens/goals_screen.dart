import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Goals screen - list of planned expenses.
/// Shows progress towards each goal including emergency fund.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppTheme.spacing24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Goals',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () => _addGoal(context),
                      icon: const Icon(Icons.add, size: 24),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing24),
                _buildEmergencyFundCard(context),
                const SizedBox(height: AppTheme.spacing16),
                _buildAddMoreGoals(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyFundCard(BuildContext context) {
    // Placeholder values
    const runwayMonths = 2.3;
    const progress = 38.0;
    const current = 75000.0;
    const target = 200000.0;

    return GestureDetector(
      onTap: () {},
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: AppTheme.black,
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Fund',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${runwayMonths.toStringAsFixed(1)} months runway',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${progress.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
            const ProgressBar(progress: progress),
            const SizedBox(height: AppTheme.spacing12),
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
      ),
    );
  }

  Widget _buildAddMoreGoals(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppTheme.spacing24),
        Text(
          'Add more goals',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Plan for vacations, purchases, or any future expenses.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacing24),
        OutlinedButton(
          onPressed: () => _addGoal(context),
          child: const Text('Add Goal'),
        ),
      ],
    );
  }

  void _addGoal(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add goal - coming soon')),
    );
  }
}
