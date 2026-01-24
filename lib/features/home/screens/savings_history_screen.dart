import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/savings_tracker_service.dart';
import '../../../core/models/savings_tracker.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';

/// Savings History Screen - Track total savings over time.
/// Shows emergency fund, investments, goals, and total savings.
class SavingsHistoryScreen extends StatefulWidget {
  const SavingsHistoryScreen({super.key});

  @override
  State<SavingsHistoryScreen> createState() => _SavingsHistoryScreenState();
}

class _SavingsHistoryScreenState extends State<SavingsHistoryScreen> {
  final _userRepo = UserRepository();
  final _savingsService = SavingsTrackerService();

  SavingsTotals? _currentTotals;
  SavingsGrowth? _growth;
  List<SavingsTracker> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        // Record current month's savings
        await _savingsService.recordCurrentMonth(user.id!);

        // Load data
        _currentTotals = await _savingsService.calculateCurrentTotals(user.id!);
        _growth = await _savingsService.getSavingsGrowth(user.id!);
        _history = await _savingsService.getHistory(user.id!, limit: 24);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
        title: const Text('Savings History'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.black),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.black,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalSavingsCard(),
            const SizedBox(height: AppTheme.spacing24),
            _buildBreakdownCard(),
            const SizedBox(height: AppTheme.spacing24),
            if (_growth != null) _buildGrowthCard(),
            const SizedBox(height: AppTheme.spacing24),
            _buildHistorySection(),
            const SizedBox(height: AppTheme.spacing48),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSavingsCard() {
    final total = _currentTotals?.totalSavings ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            'Total Savings',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.white,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(total),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.white,
                ),
          ),
          if (_growth != null && _growth!.monthlyChange != 0) ...[
            const SizedBox(height: AppTheme.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _growth!.isGrowing ? Icons.trending_up : Icons.trending_down,
                  color: _growth!.isGrowing ? Colors.greenAccent : Colors.redAccent,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_growth!.isGrowing ? '+' : ''}${Formatters.currency(_growth!.monthlyChange)} this month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _growth!.isGrowing
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreakdownCard() {
    final totals = _currentTotals;
    if (totals == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Breakdown',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildBreakdownRow(
            'Emergency Fund',
            totals.emergencyFundBalance,
            Icons.shield_outlined,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow(
            'Monthly Investments',
            totals.investmentTotal,
            Icons.trending_up,
            subtitle: 'SIP & others',
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow(
            'Active Goals',
            totals.goalsTotal,
            Icons.flag_outlined,
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildBreakdownRow(
            'Completed Goals',
            totals.completedGoalsTotal,
            Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double amount, IconData icon,
      {String? subtitle}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppTheme.black, size: 18),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.gray500,
                      ),
                ),
            ],
          ),
        ),
        Text(
          Formatters.currency(amount),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildGrowthCard() {
    final growth = _growth!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Growth',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Expanded(
                child: _buildGrowthItem(
                  'Monthly Avg',
                  growth.averageMonthly,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.gray200,
              ),
              Expanded(
                child: _buildGrowthItem(
                  'This Year',
                  growth.yearlyChange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthItem(String label, double amount) {
    final isPositive = amount >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing8),
      child: Column(
        children: [
          Text(
            '${isPositive ? '+' : ''}${Formatters.currency(amount)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isPositive ? Colors.green : const Color(0xFFB00020),
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return _buildEmptyHistory();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly History',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...List.generate(_history.length, (index) {
          final current = _history[index];
          final previous = index < _history.length - 1 ? _history[index + 1] : null;
          return _buildHistoryItem(current, previous);
        }),
      ],
    );
  }

  Widget _buildHistoryItem(SavingsTracker current, SavingsTracker? previous) {
    final change = previous != null
        ? current.totalSavings - previous.totalSavings
        : 0.0;
    final isGrowth = change >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Center(
                child: Text(
                  _getMonthAbbrev(current.month),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    current.shortMonthDisplay,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Total: ${Formatters.currency(current.totalSavings)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (previous != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isGrowth
                      ? Colors.green.withValues(alpha: 0.1)
                      : const Color(0xFFB00020).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isGrowth ? '+' : ''}${Formatters.currency(change)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isGrowth ? Colors.green : const Color(0xFFB00020),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          children: [
            const Icon(
              Icons.savings_outlined,
              size: 64,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your monthly savings will be tracked here automatically.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbrev(String month) {
    try {
      final monthNum = int.parse(month.split('-')[1]);
      const abbrevs = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      return abbrevs[monthNum - 1];
    } catch (_) {
      return '?';
    }
  }
}
