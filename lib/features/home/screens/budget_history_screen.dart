import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import 'budget_history_detail_screen.dart';

/// Budget history screen.
/// Shows past months at a glance.
/// Clean list. Minimal information. Steve Jobs approved.
class BudgetHistoryScreen extends StatelessWidget {
  const BudgetHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with actual data from database
    final historyData = _getMockHistoryData();
    final groupedByYear = _groupByYear(historyData);
    final years = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: historyData.isEmpty
                  ? _buildEmptyState(context)
                  : _buildHistoryList(context, years, groupedByYear),
            ),
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
            'Budget History',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your past budgets will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray500,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    List<int> years,
    Map<int, List<MonthlyBudgetSummary>> groupedByYear,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final months = groupedByYear[year]!;
        return _buildYearSection(context, year, months);
      },
    );
  }

  Widget _buildYearSection(
    BuildContext context,
    int year,
    List<MonthlyBudgetSummary> months,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.spacing24,
            bottom: AppTheme.spacing16,
          ),
          child: Text(
            year.toString(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ...months.map((month) => _buildMonthCard(context, month)),
        const SizedBox(height: AppTheme.spacing8),
      ],
    );
  }

  Widget _buildMonthCard(BuildContext context, MonthlyBudgetSummary summary) {
    final isPositive = summary.remaining >= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetHistoryDetailScreen(summary: summary),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.monthName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Budget: ${Formatters.currency(summary.totalBudget)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPositive
                      ? '+${Formatters.currency(summary.remaining)}'
                      : Formatters.currency(summary.remaining),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isPositive ? AppTheme.black : AppTheme.gray500,
                      ),
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  isPositive ? 'Saved' : 'Over',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray500,
                      ),
                ),
              ],
            ),
            const SizedBox(width: AppTheme.spacing12),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<MonthlyBudgetSummary>> _groupByYear(
    List<MonthlyBudgetSummary> data,
  ) {
    final grouped = <int, List<MonthlyBudgetSummary>>{};
    for (final item in data) {
      grouped.putIfAbsent(item.year, () => []);
      grouped[item.year]!.add(item);
    }
    // Sort months within each year (most recent first)
    for (final year in grouped.keys) {
      grouped[year]!.sort((a, b) => b.month.compareTo(a.month));
    }
    return grouped;
  }

  /// Mock data for UI preview.
  /// TODO: Replace with actual database query.
  List<MonthlyBudgetSummary> _getMockHistoryData() {
    return [
      MonthlyBudgetSummary(
        year: 2026,
        month: 1,
        monthName: 'January',
        totalBudget: 50000,
        totalSpent: 45000,
        remaining: 5000,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 12,
        monthName: 'December',
        totalBudget: 50000,
        totalSpent: 52000,
        remaining: -2000,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 11,
        monthName: 'November',
        totalBudget: 50000,
        totalSpent: 48000,
        remaining: 2000,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 10,
        monthName: 'October',
        totalBudget: 50000,
        totalSpent: 47500,
        remaining: 2500,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 9,
        monthName: 'September',
        totalBudget: 48000,
        totalSpent: 46000,
        remaining: 2000,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 8,
        monthName: 'August',
        totalBudget: 48000,
        totalSpent: 49500,
        remaining: -1500,
      ),
      MonthlyBudgetSummary(
        year: 2025,
        month: 7,
        monthName: 'July',
        totalBudget: 48000,
        totalSpent: 44000,
        remaining: 4000,
      ),
      MonthlyBudgetSummary(
        year: 2024,
        month: 12,
        monthName: 'December',
        totalBudget: 45000,
        totalSpent: 47000,
        remaining: -2000,
      ),
      MonthlyBudgetSummary(
        year: 2024,
        month: 11,
        monthName: 'November',
        totalBudget: 45000,
        totalSpent: 43000,
        remaining: 2000,
      ),
      MonthlyBudgetSummary(
        year: 2024,
        month: 10,
        monthName: 'October',
        totalBudget: 45000,
        totalSpent: 44500,
        remaining: 500,
      ),
    ];
  }
}

/// Summary of a single month's budget.
/// Lightweight model for the history list.
class MonthlyBudgetSummary {
  final int year;
  final int month;
  final String monthName;
  final double totalBudget;
  final double totalSpent;
  final double remaining;

  const MonthlyBudgetSummary({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
  });
}
