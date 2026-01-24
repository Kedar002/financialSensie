import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/safe_to_spend_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'log_spending_screen.dart';
import 'budget_sheet_screen.dart';
import 'transaction_history_screen.dart';

/// Home screen - THE core screen.
/// Shows safe-to-spend prominently. Nothing else competes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userRepo = UserRepository();
  final _safeToSpendService = SafeToSpendService();

  int _currentIndex = 0;
  int? _userId;
  SafeToSpendStatus? _status;
  List<RecentTransaction> _recentTransactions = [];
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
        _userId = user.id;
        _status = await _safeToSpendService.getStatus(user.id!);
        _recentTransactions = await _safeToSpendService.getRecentTransactions(user.id!, limit: 3);
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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const EmergencyFundScreen(),
          const GoalsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _logSpending,
              backgroundColor: AppTheme.black,
              child: const Icon(Icons.add, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.black),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing24),
              _buildCycleInfo(),
              const SizedBox(height: AppTheme.spacing16),
              if (_status?.isWarning == true || _status?.isOverBudget == true)
                _buildWarningBanner(),
              _buildSafeToSpendCard(),
              const SizedBox(height: AppTheme.spacing32),
              _buildQuickStats(),
              if (_recentTransactions.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacing32),
                _buildRecentTransactions(),
              ],
              const SizedBox(height: AppTheme.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCycleInfo() {
    final salaryDay = _status?.salaryDay ?? 1;
    final cycleStart = _status?.cycleStart;

    String cycleText;
    if (salaryDay == 1) {
      cycleText = DateFormat('MMMM yyyy').format(DateTime.now());
    } else if (cycleStart != null) {
      final cycleEnd = _status?.cycleEnd;
      if (cycleEnd != null) {
        cycleText = '${DateFormat('d MMM').format(cycleStart)} - ${DateFormat('d MMM').format(cycleEnd)}';
      } else {
        cycleText = 'Cycle from ${DateFormat('d MMM').format(cycleStart)}';
      }
    } else {
      cycleText = DateFormat('MMMM yyyy').format(DateTime.now());
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          cycleText,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1,
              ),
        ),
        if (salaryDay != 1)
          Text(
            'Salary: ${_getOrdinal(salaryDay)}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
      ],
    );
  }

  String _getOrdinal(int day) {
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

  Widget _buildWarningBanner() {
    final isOver = _status?.isOverBudget == true;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: isOver ? AppTheme.black : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            isOver ? Icons.warning_amber_rounded : Icons.info_outline,
            color: isOver ? AppTheme.white : AppTheme.black,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              isOver
                  ? 'You\'ve exceeded your budget'
                  : 'You\'ve spent ${_status?.percentSpent.toStringAsFixed(0)}% with ${_status?.daysRemaining} days left',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isOver ? AppTheme.white : AppTheme.black,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeToSpendCard() {
    final daily = _status?.dailyAmount ?? 0;
    final weekly = _status?.weeklyAmount ?? 0;
    final isOver = _status?.isOverBudget == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today you can spend',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          daily < 0 ? '₹0' : Formatters.currency(daily),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: isOver ? AppTheme.gray400 : AppTheme.black,
              ),
        ),
        if (isOver) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Over by ${Formatters.currency((_status?.remaining ?? 0).abs())}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: AppTheme.spacing24),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'This week',
                  value: weekly < 0 ? '₹0' : Formatters.currency(weekly),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.gray200,
              ),
              Expanded(
                child: _StatItem(
                  label: 'Days left',
                  value: '${_status?.daysRemaining ?? 0}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final spent = _status?.spentThisCycle ?? 0;
    final budget = _status?.monthlyBudget ?? 0;
    final remaining = _status?.remaining ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'This cycle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            GestureDetector(
              onTap: _viewBudgetSheet,
              child: Text(
                'View budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        AppCard(
          child: Column(
            children: [
              _buildStatRow('Budget', Formatters.currency(budget)),
              const Divider(height: AppTheme.spacing24),
              _buildStatRow('Spent', Formatters.currency(spent)),
              const Divider(height: AppTheme.spacing24),
              _buildStatRow(
                'Remaining',
                Formatters.currency(remaining),
                bold: true,
                isNegative: remaining < 0,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            GestureDetector(
              onTap: _viewTransactionHistory,
              child: Text(
                'See all',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...List.generate(_recentTransactions.length, (index) {
          final t = _recentTransactions[index];
          return _buildRecentTransactionItem(t);
        }),
      ],
    );
  }

  Widget _buildRecentTransactionItem(RecentTransaction t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              _getCategoryIcon(t.category),
              color: AppTheme.black,
              size: 18,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatCategory(t.category),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  _formatTime(t.date),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Text(
            '- ${Formatters.currency(t.amount)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.medical_services;
      default:
        return Icons.receipt;
    }
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return DateFormat('d MMM').format(date);
    }
  }

  Widget _buildStatRow(String label, String value, {bool bold = false, bool isNegative = false}) {
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
                    color: isNegative ? const Color(0xFFB00020) : null,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _logSpending() async {
    if (_userId == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LogSpendingScreen(userId: _userId!),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _viewBudgetSheet() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BudgetSheetScreen(),
      ),
    );
  }

  void _viewTransactionHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const TransactionHistoryScreen(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
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
}
