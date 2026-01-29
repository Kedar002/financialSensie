import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/minimal_calendar.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

/// Home screen - THE core screen.
/// One focus: How much can you spend?
/// Steve Jobs would approve.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

  // In-memory expense storage (will connect to database later)
  final List<Expense> _expenses = [];

  // Placeholder budget
  static const double _budget = 25000.0;

  double get _totalSpent {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _expenses
        .where((e) =>
            e.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            e.date.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _remaining => _budget - _totalSpent;

  double get _dailyAllowance {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysLeft = endOfMonth.day - now.day + 1;
    if (daysLeft <= 0) return 0;
    return _remaining / daysLeft;
  }

  List<Expense> get _selectedDateExpenses {
    return _expenses
        .where((e) => _isSameDay(e.date, _selectedDate))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Expense> get _recentExpenses {
    final sorted = List<Expense>.from(_expenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
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
              elevation: 0,
              child: const Icon(Icons.add, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing24),
            MinimalCalendar(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            const SizedBox(height: AppTheme.spacing48),
            _buildHeroSection(),
            const SizedBox(height: AppTheme.spacing48),
            _buildCycleProgress(),
            const SizedBox(height: AppTheme.spacing32),
            _buildExpensesList(),
            const SizedBox(height: AppTheme.spacing64),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final selectedExpenses = _selectedDateExpenses;
    final dayTotal = selectedExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'You can spend' : _getDateLabel(_selectedDate),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          isToday
              ? Formatters.currency(_dailyAllowance.clamp(0, double.infinity))
              : Formatters.currency(dayTotal),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        if (isToday) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'today',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
        if (!isToday && selectedExpenses.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            '${selectedExpenses.length} ${selectedExpenses.length == 1 ? 'expense' : 'expenses'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildCycleProgress() {
    final progress = _totalSpent / _budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This month',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${(progress * 100).clamp(0, 100).toInt()}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildProgressBar(progress),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatColumn('Budget', Formatters.currency(_budget)),
            _buildStatColumn('Spent', Formatters.currency(_totalSpent)),
            _buildStatColumn(
              'Left',
              Formatters.currency(_remaining),
              highlight: true,
            ),
          ],
        ),
      ],
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
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {bool highlight = false}) {
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

  Widget _buildExpensesList() {
    final expenses = _recentExpenses;

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...expenses.map((expense) => _buildExpenseItem(expense)),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note ?? 'Expense',
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatExpenseDate(expense.date),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(expense.amount),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  String _formatExpenseDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expenseDay = DateTime(date.year, date.month, date.day);

    if (expenseDay == today) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (expenseDay == yesterday) {
      return 'Yesterday';
    }

    return '${date.day}/${date.month}';
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
            icon: Icon(Icons.circle_outlined),
            activeIcon: Icon(Icons.circle),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            activeIcon: Icon(Icons.lock),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.adjust_outlined),
            activeIcon: Icon(Icons.adjust),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, yesterday)) {
      return 'Spent yesterday';
    }

    if (date.isAfter(now)) {
      return 'Planned';
    }

    return 'Spent on ${date.day}/${date.month}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _logSpending() async {
    final expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(date: _selectedDate),
        fullscreenDialog: true,
      ),
    );

    if (expense != null) {
      setState(() {
        _expenses.add(expense);
      });
    }
  }
}
