import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/models/budget_cycle.dart';
import '../../../core/models/cycle_settings.dart';
import '../../../core/services/budget_calculator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/minimal_calendar.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/models/goal.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'all_expenses_screen.dart';
import 'monthly_budget_screen.dart';

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

  // Repositories
  final SettingsRepository _settingsRepo = SettingsRepository();
  final ExpenseRepository _expenseRepo = ExpenseRepository();
  final GoalRepository _goalRepo = GoalRepository();

  // Data from database
  List<Expense> _expenses = [];
  List<Goal> _goals = [];
  double _monthlyVariableBudget = 0;
  CycleSettings _cycleSettings = CycleSettings.defaultSettings;
  bool _isLoading = true;

  // Current budget cycle - uses cycle settings
  BudgetCycle get _cycle => BudgetCycle.fromSettings(
        settings: _cycleSettings,
        budget: _monthlyVariableBudget,
      );

  // Budget snapshot (recalculated on each build)
  BudgetSnapshot get _snapshot => BudgetCalculator.calculate(
        cycle: _cycle,
        expenses: _expenses,
      );

  List<Expense> get _selectedDateExpenses {
    return BudgetCalculator.getExpensesForDate(_expenses, _selectedDate)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Expense> get _recentExpenses {
    final sorted = List<Expense>.from(_expenses)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load settings
    final income = await _settingsRepo.getMonthlyIncome();
    final fixedExpenses = await _settingsRepo.getTotalFixedExpenses();
    final wantsPercent = await _settingsRepo.getWantsPercent();
    final cycleType = await _settingsRepo.getCycleType();
    final cycleStartDay = await _settingsRepo.getCycleStartDay();

    // Calculate variable budget (wants portion after fixed expenses)
    final afterFixed = income - fixedExpenses;
    final variableBudget = afterFixed * wantsPercent / 100;

    // Load cycle settings
    final cycleSettings = cycleType == 'custom'
        ? CycleSettings.customDay(cycleStartDay)
        : CycleSettings.calendarMonth();

    // Load expenses for current cycle
    final expenseMaps = await _expenseRepo.getForCurrentCycle(cycleSettings);
    final expenses = expenseMaps.map((m) => Expense.fromMap(m)).toList();

    // Load goals
    final goalMaps = await _goalRepo.getActiveGoals();
    final goals = goalMaps.map((m) => Goal.fromMap(m)).toList();

    if (mounted) {
      setState(() {
        _monthlyVariableBudget = AmountConverter.toRupees(variableBudget.round());
        _cycleSettings = cycleSettings;
        _expenses = expenses;
        _goals = goals;
        _isLoading = false;
      });
    }
  }

  void _resetAllData() {
    setState(() {
      _expenses = [];
      _goals = [];
      _monthlyVariableBudget = 0;
      _cycleSettings = CycleSettings.defaultSettings;
      _isLoading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _isLoading ? _buildLoading() : _buildHomeContent(),
          const EmergencyFundScreen(),
          GoalsScreen(
            goals: _goals,
            onGoalAdded: _onGoalAdded,
            onGoalUpdated: _onGoalUpdated,
            onGoalDeleted: _onGoalDeleted,
          ),
          ProfileScreen(onDataReset: _resetAllData),
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

  Widget _buildLoading() {
    return const SafeArea(
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.black,
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final snapshot = _snapshot;

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
            _buildHeroSection(snapshot),
            const SizedBox(height: AppTheme.spacing48),
            _buildCycleProgress(snapshot),
            const SizedBox(height: AppTheme.spacing32),
            _buildExpensesList(),
            const SizedBox(height: AppTheme.spacing64),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BudgetSnapshot snapshot) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final isToday = selectedDay == today;
    final isPast = selectedDay.isBefore(today);
    final isFuture = selectedDay.isAfter(today);
    final isInCurrentCycle = _cycle.containsDate(_selectedDate);

    final selectedExpenses = _selectedDateExpenses;
    final dayTotal = selectedExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isToday) ...[
          // TODAY: Show rolling daily allowance
          Text(
            'You can spend',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(snapshot.rollingDailyAllowance),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: snapshot.isOverBudget ? AppTheme.gray400 : AppTheme.black,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'today',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            children: [
              Text(
                'Planned: ${Formatters.currency(snapshot.plannedDailyBudget)}/day',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(width: AppTheme.spacing12),
              Container(
                width: 3,
                height: 3,
                decoration: const BoxDecoration(
                  color: AppTheme.gray400,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Text(
                '${snapshot.remainingDays} days left',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          if (snapshot.isOverBudget) ...[
            const SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Over budget by ${Formatters.currency(snapshot.overBudgetAmount)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.black,
                    ),
              ),
            ),
          ],
        ] else if (isPast && isInCurrentCycle) ...[
          // PAST DATE IN CURRENT CYCLE: Show spent amount
          Text(
            _getDateLabel(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(dayTotal),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            selectedExpenses.isEmpty
                ? 'No expenses'
                : '${selectedExpenses.length} ${selectedExpenses.length == 1 ? 'expense' : 'expenses'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ] else if (isFuture && isInCurrentCycle) ...[
          // FUTURE DATE IN CURRENT CYCLE: Show planned allowance
          _buildFutureDateSection(snapshot, selectedDay),
        ] else if (isPast && !isInCurrentCycle) ...[
          // PAST DATE OUTSIDE CYCLE: Show historical data if any
          Text(
            _getDateLabel(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(dayTotal),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            selectedExpenses.isEmpty
                ? 'Previous cycle'
                : '${selectedExpenses.length} ${selectedExpenses.length == 1 ? 'expense' : 'expenses'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ] else ...[
          // FUTURE DATE OUTSIDE CYCLE: No budget yet
          Text(
            _getDateLabel(_selectedDate),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(0),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'Next cycle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ],
    );
  }

  /// Build section for future dates within the current cycle.
  /// Shows how much user can spend on that day based on remaining budget.
  Widget _buildFutureDateSection(BudgetSnapshot snapshot, DateTime selectedDay) {
    // Calculate allowance for the selected future date
    // remaining_budget / days_from_selected_to_cycle_end
    final cycleEnd = DateTime(_cycle.endDate.year, _cycle.endDate.month, _cycle.endDate.day);
    final daysFromSelectedToEnd = cycleEnd.difference(selectedDay).inDays + 1;

    double allowanceForDay = 0;
    if (daysFromSelectedToEnd > 0 && snapshot.remainingBudget > 0) {
      allowanceForDay = snapshot.remainingBudget / daysFromSelectedToEnd;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You can spend',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          Formatters.currency(allowanceForDay),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: snapshot.isOverBudget ? AppTheme.gray400 : AppTheme.black,
              ),
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          _getFutureDateLabel(_selectedDate),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          children: [
            Text(
              'Based on ${Formatters.currency(snapshot.remainingBudget)} remaining',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: AppTheme.gray400,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              '$daysFromSelectedToEnd days left',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        if (snapshot.isOverBudget) ...[
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'Over budget by ${Formatters.currency(snapshot.overBudgetAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.black,
                  ),
            ),
          ),
        ],
      ],
    );
  }

  String _getFutureDateLabel(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final selectedDay = DateTime(date.year, date.month, date.day);

    if (selectedDay == tomorrow) {
      return 'tomorrow';
    }
    return 'on ${date.day}/${date.month}';
  }

  Widget _buildCycleProgress(BudgetSnapshot snapshot) {
    return GestureDetector(
      onTap: _viewMonthlyBudget,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This month',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  Text(
                    '${(snapshot.spentProgress * 100).clamp(0, 999).toInt()}%',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.gray400,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          _buildProgressBar(snapshot.spentProgress),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatColumn(
                  'Budget', Formatters.currency(snapshot.totalBudget)),
              _buildStatColumn(
                  'Spent', Formatters.currency(snapshot.totalSpent)),
              _buildStatColumn(
                'Left',
                snapshot.isOverBudget
                    ? '-${Formatters.currency(snapshot.overBudgetAmount)}'
                    : Formatters.currency(snapshot.remainingBudget),
                highlight: true,
                negative: snapshot.isOverBudget,
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

  Widget _buildStatColumn(
    String label,
    String value, {
    bool highlight = false,
    bool negative = false,
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
              ? Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: negative ? AppTheme.gray400 : AppTheme.black,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildExpensesList() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final isToday = selectedDay == today;
    final isPastOrToday = !selectedDay.isAfter(today);

    // Show selected day's expenses for past dates, recent for today
    final expenses = isToday ? _recentExpenses : _selectedDateExpenses;

    // For future dates, don't show expenses section
    if (!isPastOrToday) {
      return const SizedBox.shrink();
    }

    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine title based on date
    String title;
    if (isToday) {
      title = 'Recent';
    } else if (_isSameDay(_selectedDate, DateTime.now().subtract(const Duration(days: 1)))) {
      title = 'Yesterday\'s expenses';
    } else {
      title = 'Expenses on ${_selectedDate.day}/${_selectedDate.month}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isToday)
              GestureDetector(
                onTap: _viewAllExpenses,
                child: Text(
                  'View all',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...expenses.map((expense) => _buildExpenseItem(expense, showDate: isToday)),
      ],
    );
  }

  Widget _buildExpenseItem(Expense expense, {bool showDate = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.note ?? expense.category.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Row(
                  children: [
                    Text(
                      expense.category.label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    if (showDate) ...[
                      const SizedBox(width: AppTheme.spacing8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          color: AppTheme.gray400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacing8),
                      Text(
                        _formatExpenseDate(expense.date),
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ],
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
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh home data when switching to Home tab
          if (index == 0) {
            _loadData();
          }
        },
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
        builder: (_) => AddExpenseScreen(
          date: _selectedDate,
          goals: _goals,
        ),
        fullscreenDialog: true,
      ),
    );

    if (expense != null) {
      // Save to database
      final expenseId = await _expenseRepo.insert(
        amount: expense.amount,
        category: expense.category.name,
        subcategory: expense.toMap()['subcategory'] as String,
        goalId: expense.savingsDestination?.goalId,
        isFundContribution:
            expense.savingsDestination?.isEmergencyFund ?? false,
        date: expense.date,
        note: expense.note,
      );

      // If this is a savings expense to a goal, add contribution
      if (expense.category == ExpenseCategory.savings &&
          expense.savingsDestination != null &&
          expense.savingsDestination!.isGoal) {
        await _goalRepo.addContribution(
          goalId: expense.savingsDestination!.goalId!,
          amount: expense.amount,
          expenseId: expenseId,
        );
      }

      // Reload data
      await _loadData();
    }
  }

  Future<void> _onGoalAdded(Goal goal) async {
    await _goalRepo.insert(
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      instrument: goal.instrument.name,
    );
    await _loadData();
  }

  Future<void> _onGoalUpdated(Goal goal) async {
    await _goalRepo.update(
      goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      targetDate: goal.targetDate,
      instrument: goal.instrument.name,
    );
    await _loadData();
  }

  Future<void> _onGoalDeleted(String goalId) async {
    await _goalRepo.delete(goalId);
    await _loadData();
  }

  void _viewMonthlyBudget() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MonthlyBudgetScreen(
          totalBudget: _monthlyVariableBudget,
          expenses: _expenses,
        ),
      ),
    );
  }

  void _viewAllExpenses() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllExpensesScreen(
          expenses: _expenses,
          goals: _goals,
          onExpenseUpdated: _onExpenseUpdated,
          onExpenseDeleted: _onExpenseDeleted,
        ),
      ),
    );
  }

  Future<void> _onExpenseUpdated(Expense updatedExpense) async {
    // Update in database
    await _expenseRepo.update(
      updatedExpense.id,
      amount: updatedExpense.amount,
      category: updatedExpense.category.name,
      subcategory: updatedExpense.toMap()['subcategory'] as String,
      goalId: updatedExpense.savingsDestination?.goalId,
      isFundContribution:
          updatedExpense.savingsDestination?.isEmergencyFund ?? false,
      date: updatedExpense.date,
      note: updatedExpense.note,
    );
    await _loadData();
  }

  Future<void> _onExpenseDeleted(String expenseId) async {
    await _expenseRepo.delete(expenseId);
    await _loadData();
  }
}
