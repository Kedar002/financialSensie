import 'package:flutter/material.dart';
import '../../../core/models/expense.dart';
import '../../../core/repositories/expense_repository.dart';
import '../sheets/add_expense_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ExpenseRepository _repository = ExpenseRepository();
  String _selectedFilter = 'all';
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _showCalendar = false;
  List<Expense> _expenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _repository.getByMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  List<Expense> get _filteredExpenses {
    return _expenses.where((e) {
      // For savings filter, include both savings deposits and withdrawals
      final matchesFilter = _selectedFilter == 'all' ||
          e.type == _selectedFilter ||
          (_selectedFilter == 'savings' && e.type == 'savings_withdrawal');
      final matchesDate = _selectedDate == null ||
          (e.date.day == _selectedDate!.day &&
           e.date.month == _selectedDate!.month &&
           e.date.year == _selectedDate!.year);
      return matchesFilter && matchesDate;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDate = null;
      _isLoading = true;
    });
    _loadExpenses();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDate = null;
      _isLoading = true;
    });
    _loadExpenses();
  }

  String _formatAmount(int amount) {
    final value = amount / 100;
    if (value == value.truncate()) {
      return value.truncate().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return value.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMonthNavigator(),
            if (_showCalendar) _buildCalendarGrid(),
            _buildFilterChips(),
            const SizedBox(height: 8),
            if (_selectedDate != null) _buildSelectedDateChip(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExpenses.isEmpty
                      ? _buildEmptyState()
                      : _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            color: const Color(0xFF007AFF),
          ),
          const Expanded(
            child: Text(
              'Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          GestureDetector(
            onTap: _showAddExpense,
            child: const Icon(
              Icons.add,
              size: 24,
              color: Color(0xFF007AFF),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddExpense() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(onSaved: () {}),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  Widget _buildMonthNavigator() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.chevron_left,
                size: 24,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Row(
              children: [
                Text(
                  '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.chevron_right,
                size: 24,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => SizedBox(
              width: 36,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex + 1 - (startingWeekday - 1);

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final isSelected = _selectedDate?.day == dayNumber &&
                                    _selectedDate?.month == _selectedMonth.month &&
                                    _selectedDate?.year == _selectedMonth.year;
                  final isToday = today.day == dayNumber &&
                                 today.month == _selectedMonth.month &&
                                 today.year == _selectedMonth.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDate = null;
                        } else {
                          _selectedDate = date;
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : null,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'needs', 'label': 'Needs'},
      {'key': 'wants', 'label': 'Wants'},
      {'key': 'savings', 'label': 'Savings'},
      {'key': 'income', 'label': 'Income'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter['key']!),
              child: Container(
                margin: EdgeInsets.only(right: filter['key'] != 'income' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filter['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedDateChip() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedDate!.day} ${months[_selectedDate!.month - 1]}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = null),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showAddExpense,
            child: const Text(
              'Add a transaction',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    final grouped = <String, List<Expense>>{};
    for (final expense in _filteredExpenses) {
      final key = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(expense);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final transactions = grouped[dateKey]!;
        final date = transactions.first.date;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final expense = entry.value;
                  final isLast = entry.key == transactions.length - 1;
                  return _TransactionTile(
                    expense: expense,
                    formatAmount: _formatAmount,
                    isLast: isLast,
                    onTap: () => _showExpenseDetails(expense),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseDetails(Expense expense) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseDetailSheet(
        expense: expense,
        formatAmount: _formatAmount,
        onEdit: () async {
          Navigator.pop(context);
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddExpenseSheet(
              expense: expense,
              onSaved: _loadExpenses,
            ),
          );
          _loadExpenses();
        },
        onDelete: () async {
          await _repository.delete(expense.id!);
          if (mounted) Navigator.pop(context, true);
          _loadExpenses();
        },
      ),
    );
    if (result == true) {
      _loadExpenses();
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (dateOnly == todayOnly) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _TransactionTile extends StatelessWidget {
  final Expense expense;
  final String Function(int) formatAmount;
  final bool isLast;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.expense,
    required this.formatAmount,
    this.isLast = false,
    required this.onTap,
  });

  bool get _hasNote => expense.note != null && expense.note!.isNotEmpty;

  String get _typeLabel {
    switch (expense.type) {
      case 'needs': return 'Needs';
      case 'wants': return 'Wants';
      case 'savings': return 'Savings';
      case 'savings_withdrawal': return 'Withdrawal';
      case 'income': return 'Balance';
      default: return expense.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';
    final isWithdrawal = expense.type == 'savings_withdrawal';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF2F2F7), width: 1),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasNote ? expense.note! : expense.categoryName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _hasNote
                        ? '${expense.categoryName} · $_typeLabel'
                        : _typeLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome || isWithdrawal ? '+' : '-'}₹${formatAmount(expense.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isIncome || isWithdrawal ? const Color(0xFF34C759) : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDetailSheet extends StatelessWidget {
  final Expense expense;
  final String Function(int) formatAmount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseDetailSheet({
    required this.expense,
    required this.formatAmount,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (expense.type) {
      case 'needs': return 'Needs';
      case 'wants': return 'Wants';
      case 'savings': return 'Savings';
      case 'savings_withdrawal': return 'Withdrawal';
      case 'income': return 'Balance';
      default: return expense.type;
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';
    final isWithdrawal = expense.type == 'savings_withdrawal';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${isIncome || isWithdrawal ? '+' : '-'}₹${formatAmount(expense.amount)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: isIncome || isWithdrawal ? const Color(0xFF34C759) : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                expense.categoryName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_typeLabel · ${_formatDate(expense.date)}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
              if (expense.note != null && expense.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    expense.note!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Edit',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE5E5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );
  }
}
