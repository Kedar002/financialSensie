import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/advanced_date_picker.dart';
import '../../goals/models/goal.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

/// All expenses screen.
/// Filter by category and dates.
/// Clean list grouped by date.
/// Tap expense to edit or delete.
class AllExpensesScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Goal> goals;
  final void Function(Expense expense)? onExpenseUpdated;
  final void Function(String expenseId)? onExpenseDeleted;

  const AllExpensesScreen({
    super.key,
    required this.expenses,
    required this.goals,
    this.onExpenseUpdated,
    this.onExpenseDeleted,
  });

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  ExpenseCategory? _selectedCategory;
  DateSelectionMode _dateMode = DateSelectionMode.single;
  List<DateTime> _selectedDates = [];
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  bool _showCalendar = false;

  List<Expense> get _filteredExpenses {
    var filtered = widget.expenses.where((e) {
      // Filter by category
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }

      // Filter by date
      if (!_matchesDateFilter(e.date)) {
        return false;
      }

      return true;
    }).toList();

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  bool _matchesDateFilter(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    // If no date filter is active, show all
    if (_selectedDates.isEmpty && _rangeStart == null) {
      return true;
    }

    // Single or multiple date selection
    if (_selectedDates.isNotEmpty) {
      return _selectedDates.any((d) =>
          d.year == dateOnly.year &&
          d.month == dateOnly.month &&
          d.day == dateOnly.day);
    }

    // Range selection
    if (_rangeStart != null) {
      final start = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
      if (_rangeEnd != null) {
        final end = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
        return !dateOnly.isBefore(start) && !dateOnly.isAfter(end);
      }
      return dateOnly == start;
    }

    return true;
  }

  double get _filteredTotal {
    return _filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildFilters(context),
            if (_showCalendar) _buildCalendarSection(context),
            _buildSummary(context),
            Expanded(
              child: _buildExpensesList(context),
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
            'All Expenses',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category filter
          Row(
            children: [
              _buildFilterChip(context, label: 'All', category: null),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterChip(context, label: 'Needs', category: ExpenseCategory.needs),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterChip(context, label: 'Wants', category: ExpenseCategory.wants),
              const SizedBox(width: AppTheme.spacing8),
              _buildFilterChip(context, label: 'Savings', category: ExpenseCategory.savings),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          // Date filter toggle
          GestureDetector(
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: _showCalendar ? AppTheme.black : AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: _showCalendar ? AppTheme.white : AppTheme.gray600,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Text(
                    _getDateFilterLabel(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _showCalendar ? AppTheme.white : AppTheme.gray600,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  Icon(
                    _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: _showCalendar ? AppTheme.white : AppTheme.gray600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDateFilterLabel() {
    if (_selectedDates.isEmpty && _rangeStart == null) {
      return 'Filter by date';
    }

    if (_selectedDates.length == 1) {
      return _formatShortDate(_selectedDates.first);
    }

    if (_selectedDates.length > 1) {
      return '${_selectedDates.length} dates';
    }

    if (_rangeStart != null && _rangeEnd != null) {
      return '${_formatShortDate(_rangeStart!)} - ${_formatShortDate(_rangeEnd!)}';
    }

    if (_rangeStart != null) {
      return 'From ${_formatShortDate(_rangeStart!)}';
    }

    return 'Filter by date';
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required ExpenseCategory? category,
  }) {
    final isSelected = _selectedCategory == category;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.black : AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.white : AppTheme.gray600,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: AdvancedDatePicker(
          mode: _dateMode,
          selectedDates: _selectedDates,
          rangeStart: _rangeStart,
          rangeEnd: _rangeEnd,
          onDateSelected: (date) {
            setState(() {
              _dateMode = DateSelectionMode.single;
              _selectedDates = [date];
              _rangeStart = null;
              _rangeEnd = null;
            });
          },
          onMultipleDatesSelected: (dates) {
            setState(() {
              _dateMode = DateSelectionMode.multiple;
              _selectedDates = dates;
              _rangeStart = null;
              _rangeEnd = null;
            });
          },
          onRangeSelected: (start, end) {
            setState(() {
              _dateMode = DateSelectionMode.range;
              _selectedDates = [];
              _rangeStart = start;
              _rangeEnd = end;
            });
          },
          onClear: () {
            setState(() {
              _selectedDates = [];
              _rangeStart = null;
              _rangeEnd = null;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final count = _filteredExpenses.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing24,
        vertical: AppTheme.spacing16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$count ${count == 1 ? 'expense' : 'expenses'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            Formatters.currency(_filteredTotal),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildExpensesList(BuildContext context) {
    final expenses = _filteredExpenses;

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No expenses',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.gray400,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                _getEmptyMessage(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray400,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group expenses by date
    final groupedExpenses = <DateTime, List<Expense>>{};
    for (final expense in expenses) {
      final date = DateTime(expense.date.year, expense.date.month, expense.date.day);
      groupedExpenses.putIfAbsent(date, () => []).add(expense);
    }

    final sortedDates = groupedExpenses.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayExpenses = groupedExpenses[date]!;
        return _buildDateGroup(context, date, dayExpenses);
      },
    );
  }

  String _getEmptyMessage() {
    if (_selectedCategory != null && (_selectedDates.isNotEmpty || _rangeStart != null)) {
      return 'No ${_selectedCategory!.label.toLowerCase()} expenses for selected dates';
    }
    if (_selectedCategory != null) {
      return 'No ${_selectedCategory!.label.toLowerCase()} expenses found';
    }
    if (_selectedDates.isNotEmpty || _rangeStart != null) {
      return 'No expenses for selected dates';
    }
    return 'No expenses recorded yet';
  }

  Widget _buildDateGroup(
    BuildContext context,
    DateTime date,
    List<Expense> expenses,
  ) {
    final dayTotal = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.spacing16,
            bottom: AppTheme.spacing12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(date),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                Formatters.currency(dayTotal),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
        ...expenses.map((expense) => _buildExpenseItem(context, expense)),
        const SizedBox(height: AppTheme.spacing8),
      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, Expense expense) {
    return GestureDetector(
      onTap: () => _showExpenseOptions(context, expense),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: _getCategoryColor(expense.category),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
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
                  Text(
                    expense.destinationLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.currency(expense.amount),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppTheme.spacing8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.gray300,
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseOptions(BuildContext context, Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(expense.category),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.note ?? expense.category.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacing4),
                        Text(
                          '${expense.destinationLabel} • ${_formatDate(expense.date)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.gray500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.currency(expense.amount),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editExpense(expense);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(expense);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.gray600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editExpense(Expense expense) async {
    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          date: expense.date,
          goals: widget.goals,
          existingExpense: expense,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      widget.onExpenseUpdated?.call(result);
    }
  }

  void _confirmDelete(Expense expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delete expense?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'This will permanently remove "${expense.note ?? expense.category.label}" (${Formatters.currency(expense.amount)}).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onExpenseDeleted?.call(expense.id);
                      },
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.needs:
        return AppTheme.black;
      case ExpenseCategory.wants:
        return AppTheme.gray400;
      case ExpenseCategory.savings:
        return AppTheme.gray200;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    }
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}
