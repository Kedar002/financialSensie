import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../models/expense.dart';

/// Monthly budget screen.
/// Shows the 50-30-20 breakdown.
/// Three buckets. Clear progress. Steve Jobs approved.
class MonthlyBudgetScreen extends StatelessWidget {
  final double totalBudget;
  final List<Expense> expenses;

  const MonthlyBudgetScreen({
    super.key,
    required this.totalBudget,
    required this.expenses,
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
                    _buildBreakdown(context),
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
            'Monthly Budget',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final remaining = totalBudget - totalSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Budget',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          Formatters.currency(totalBudget),
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppTheme.spacing24),
        Row(
          children: [
            Expanded(
              child: _buildOverviewStat(
                context,
                label: 'Spent',
                value: Formatters.currency(totalSpent),
              ),
            ),
            const SizedBox(width: AppTheme.spacing24),
            Expanded(
              child: _buildOverviewStat(
                context,
                label: 'Remaining',
                value: remaining >= 0
                    ? Formatters.currency(remaining)
                    : '-${Formatters.currency(remaining.abs())}',
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
    // 50-30-20 rule
    final needsBudget = totalBudget * 0.50;
    final wantsBudget = totalBudget * 0.30;
    final savingsBudget = totalBudget * 0.20;

    final needsSpent = _getSpentByCategory(ExpenseCategory.needs);
    final wantsSpent = _getSpentByCategory(ExpenseCategory.wants);
    final savingsSpent = _getSpentByCategory(ExpenseCategory.savings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The 50-30-20 Rule',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Your budget split across three buckets',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        _buildBucket(
          context,
          category: 'Needs',
          percentage: '50%',
          description: 'Essentials like food, transport, bills',
          budget: needsBudget,
          spent: needsSpent,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildBucket(
          context,
          category: 'Wants',
          percentage: '30%',
          description: 'Lifestyle like dining, entertainment',
          budget: wantsBudget,
          spent: wantsSpent,
        ),
        const SizedBox(height: AppTheme.spacing16),
        _buildBucket(
          context,
          category: 'Savings',
          percentage: '20%',
          description: 'Future like investments, emergency fund',
          budget: savingsBudget,
          spent: savingsSpent,
        ),
      ],
    );
  }

  Widget _buildBucket(
    BuildContext context, {
    required String category,
    required String percentage,
    required String description,
    required double budget,
    required double spent,
  }) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final remaining = budget - spent;
    final isOver = remaining < 0;

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
              Row(
                children: [
                  Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
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
                      percentage,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.black,
                          ),
                    ),
                  ),
                ],
              ),
              Text(
                Formatters.currency(budget),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildProgressBar(progress),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${Formatters.currency(spent)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                isOver
                    ? 'Over: ${Formatters.currency(remaining.abs())}'
                    : 'Left: ${Formatters.currency(remaining)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOver ? AppTheme.gray500 : AppTheme.black,
                      fontWeight: FontWeight.w600,
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

  Widget _buildBreakdown(BuildContext context) {
    final needsSpent = _getSpentByCategory(ExpenseCategory.needs);
    final wantsSpent = _getSpentByCategory(ExpenseCategory.wants);
    final savingsSpent = _getSpentByCategory(ExpenseCategory.savings);
    final totalSpent = needsSpent + wantsSpent + savingsSpent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Spending',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'How you\'ve actually spent this month',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        if (totalSpent == 0)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Center(
              child: Text(
                'No expenses yet this month',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ),
          )
        else
          Column(
            children: [
              _buildSpendingBar(context, needsSpent, wantsSpent, savingsSpent),
              const SizedBox(height: AppTheme.spacing16),
              _buildSpendingLegend(context, needsSpent, wantsSpent, savingsSpent),
            ],
          ),
      ],
    );
  }

  Widget _buildSpendingBar(
    BuildContext context,
    double needs,
    double wants,
    double savings,
  ) {
    final total = needs + wants + savings;
    if (total == 0) return const SizedBox.shrink();

    final needsPercent = needs / total;
    final wantsPercent = wants / total;
    final savingsPercent = savings / total;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          if (needsPercent > 0)
            Expanded(
              flex: (needsPercent * 100).round(),
              child: Container(color: AppTheme.black),
            ),
          if (wantsPercent > 0)
            Expanded(
              flex: (wantsPercent * 100).round(),
              child: Container(color: AppTheme.gray400),
            ),
          if (savingsPercent > 0)
            Expanded(
              flex: (savingsPercent * 100).round(),
              child: Container(color: AppTheme.gray200),
            ),
        ],
      ),
    );
  }

  Widget _buildSpendingLegend(
    BuildContext context,
    double needs,
    double wants,
    double savings,
  ) {
    final total = needs + wants + savings;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildLegendItem(
          context,
          color: AppTheme.black,
          label: 'Needs',
          value: needs,
          total: total,
        ),
        _buildLegendItem(
          context,
          color: AppTheme.gray400,
          label: 'Wants',
          value: wants,
          total: total,
        ),
        _buildLegendItem(
          context,
          color: AppTheme.gray200,
          label: 'Savings',
          value: savings,
          total: total,
        ),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
    required double value,
    required double total,
  }) {
    final percent = total > 0 ? ((value / total) * 100).round() : 0;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppTheme.spacing8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '$percent%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ],
    );
  }

  double _getSpentByCategory(ExpenseCategory category) {
    return expenses
        .where((e) => e.category == category)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}
