import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import 'budget_history_screen.dart';

/// Detail view for a historical month's budget.
/// Shows the 50-30-20 breakdown for that month.
/// Read-only. Clean. Steve Jobs approved.
class BudgetHistoryDetailScreen extends StatelessWidget {
  final MonthlyBudgetSummary summary;

  const BudgetHistoryDetailScreen({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverview(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildBuckets(context),
                    const SizedBox(height: AppTheme.spacing48),
                    _buildResult(context),
                    const SizedBox(height: AppTheme.spacing64),
                  ],
                ),
              ),
            ],
          ),
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
            '${summary.monthName} ${summary.year}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final remaining = summary.remaining;
    final isPositive = remaining >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Budget',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          Formatters.currency(summary.totalBudget),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppTheme.spacing24),
        Row(
          children: [
            Expanded(
              child: _buildOverviewStat(
                context,
                label: 'Spent',
                value: Formatters.currency(summary.totalSpent),
              ),
            ),
            const SizedBox(width: AppTheme.spacing24),
            Expanded(
              child: _buildOverviewStat(
                context,
                label: isPositive ? 'Saved' : 'Over',
                value: isPositive
                    ? Formatters.currency(remaining)
                    : Formatters.currency(remaining.abs()),
                highlight: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewStat(
    BuildContext context, {
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: highlight
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildBuckets(BuildContext context) {
    // TODO: Replace with actual data from database
    // Mock spent amounts (will be replaced with real data)
    final needsSpent = summary.totalSpent * 0.55;
    final wantsSpent = summary.totalSpent * 0.35;
    final savingsSpent = summary.totalSpent * 0.10;

    // Calculate actual percentages from total spent
    final totalSpent = summary.totalSpent;
    final needsActualPercent = totalSpent > 0 ? (needsSpent / totalSpent * 100).round() : 0;
    final wantsActualPercent = totalSpent > 0 ? (wantsSpent / totalSpent * 100).round() : 0;
    final savingsActualPercent = totalSpent > 0 ? (savingsSpent / totalSpent * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Your actual spending vs recommended 50-30-20',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        _buildBucket(
          context,
          category: 'Needs',
          actualPercent: needsActualPercent,
          targetPercent: 50,
          spent: needsSpent,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildBucket(
          context,
          category: 'Wants',
          actualPercent: wantsActualPercent,
          targetPercent: 30,
          spent: wantsSpent,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildBucket(
          context,
          category: 'Savings',
          actualPercent: savingsActualPercent,
          targetPercent: 20,
          spent: savingsSpent,
        ),
      ],
    );
  }

  Widget _buildBucket(
    BuildContext context, {
    required String category,
    required int actualPercent,
    required int targetPercent,
    required double spent,
  }) {
    final isOverTarget = actualPercent > targetPercent;
    final isUnderTarget = actualPercent < targetPercent;
    // For savings, under target is bad; for needs/wants, over target is bad
    final isSavings = category == 'Savings';
    final needsAttention = isSavings ? isUnderTarget : isOverTarget;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                Formatters.currency(spent),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildProgressBar(actualPercent / 100),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$actualPercent%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: needsAttention ? AppTheme.gray500 : AppTheme.black,
                        ),
                  ),
                  const SizedBox(width: AppTheme.spacing4),
                  Text(
                    'spent',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '$targetPercent% target',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.gray500,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final isPositive = summary.remaining >= 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            isPositive ? 'You saved' : 'You overspent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            isPositive
                ? '+${Formatters.currency(summary.remaining)}'
                : Formatters.currency(summary.remaining),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: isPositive ? AppTheme.black : AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'this month',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }
}
