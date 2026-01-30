import 'package:flutter/material.dart';
import '../../../core/models/expense.dart';
import '../../../core/repositories/expense_repository.dart';
import '../screens/cycle_complete_screen.dart';
import '../screens/income_screen.dart';
import '../screens/spent_screen.dart';
import '../screens/transactions_screen.dart';
import '../sheets/add_expense_sheet.dart';
import '../widgets/cycle_indicator.dart';

class ExpensesTab extends StatefulWidget {
  final VoidCallback onMenuTap;

  const ExpensesTab({super.key, required this.onMenuTap});

  @override
  State<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends State<ExpensesTab> {
  final ExpenseRepository _repository = ExpenseRepository();
  List<Expense> _recentExpenses = [];
  bool _isLoading = true;
  int _totalIncome = 0;
  int _totalSpent = 0;

  // Cycle dates (can be made configurable later)
  late DateTime _cycleStart;
  late DateTime _cycleEnd;
  int _payCycleDay = 1;

  @override
  void initState() {
    super.initState();
    _calculateCycleDates();
    _loadData();
  }

  void _calculateCycleDates() {
    final now = DateTime.now();
    if (now.day >= _payCycleDay) {
      _cycleStart = DateTime(now.year, now.month, _payCycleDay);
      _cycleEnd = DateTime(now.year, now.month + 1, _payCycleDay - 1);
    } else {
      _cycleStart = DateTime(now.year, now.month - 1, _payCycleDay);
      _cycleEnd = DateTime(now.year, now.month, _payCycleDay - 1);
    }
  }

  Future<void> _loadData() async {
    final expenses = await _repository.getRecent(limit: 5);
    final income = await _repository.getTotalIncome(start: _cycleStart, end: _cycleEnd);
    final spent = await _repository.getTotalSpent(start: _cycleStart, end: _cycleEnd);

    setState(() {
      _recentExpenses = expenses;
      _totalIncome = income;
      _totalSpent = spent;
      _isLoading = false;
    });
  }

  int get _remaining => _totalIncome - _totalSpent;

  double get _cycleProgress {
    final now = DateTime.now();
    final total = _cycleEnd.difference(_cycleStart).inDays;
    final elapsed = now.difference(_cycleStart).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF2F2F7),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onMenuTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.menu, size: 20, color: Colors.black),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddSheet(context),
                    child: const Icon(
                      Icons.add,
                      size: 28,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Balance Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _showCycleSettings(context),
                                onLongPress: () => _showCycleComplete(context),
                                child: CycleIndicator(
                                  cycleStart: _cycleStart,
                                  cycleEnd: _cycleEnd,
                                  progress: _cycleProgress,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '₹${_formatAmount(_remaining)}',
                                style: TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w700,
                                  color: _remaining >= 0 ? Colors.black : const Color(0xFFFF3B30),
                                  letterSpacing: -1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Remaining this cycle',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const IncomeScreen()),
                                        );
                                        _loadData();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Income',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF8E8E93),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${_formatAmount(_totalIncome)}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF34C759),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => const SpentScreen()),
                                        );
                                        _loadData();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F7),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Spent',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF8E8E93),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '₹${_formatAmount(_totalSpent)}',
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Recent Transactions
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const TransactionsScreen(),
                                    ),
                                  );
                                  _loadData();
                                },
                                child: const Text(
                                  'View All',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF007AFF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_recentExpenses.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Color(0xFFC7C7CC),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showAddSheet(context),
                                  child: const Text(
                                    'Add your first expense',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: _recentExpenses.asMap().entries.map((entry) {
                                final index = entry.key;
                                final expense = entry.value;
                                final isLast = index == _recentExpenses.length - 1;
                                return _TransactionTile(
                                  expense: expense,
                                  formatAmount: _formatAmount,
                                  formatDate: _formatDate,
                                  isLast: isLast,
                                  onTap: () => _showExpenseDetails(expense),
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        onSaved: () {},
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showExpenseDetails(Expense expense) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseDetailSheet(
        expense: expense,
        formatAmount: _formatAmount,
        formatDate: _formatDate,
        onEdit: () async {
          Navigator.pop(context);
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AddExpenseSheet(
              expense: expense,
              onSaved: _loadData,
            ),
          );
          _loadData();
        },
        onDelete: () async {
          await _repository.delete(expense.id!);
          if (mounted) Navigator.pop(context, true);
          _loadData();
        },
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showCycleComplete(BuildContext context) async {
    final spentByType = await _repository.getSpentByType(start: _cycleStart, end: _cycleEnd);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleCompleteScreen(
          cycleName: _getCycleName(),
          cycleStart: _cycleStart,
          cycleEnd: _cycleEnd,
          totalIncome: _totalIncome,
          totalSpent: _totalSpent,
          needsSpent: spentByType['needs'] ?? 0,
          wantsSpent: spentByType['wants'] ?? 0,
          savingsAdded: spentByType['savings'] ?? 0,
          onStartNewCycle: () => Navigator.pop(context),
        ),
      ),
    );
  }

  String _getCycleName() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[_cycleStart.month - 1];
  }

  void _showCycleSettings(BuildContext context) {
    int selectedDay = _payCycleDay;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                  const Text(
                    'Pay Cycle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When do you receive your paycheck?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Every month on the',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDayPicker(context, selectedDay, (day) {
                          setState(() => selectedDay = day);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatDayWithSuffix(selectedDay),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      this.setState(() {
                        _payCycleDay = selectedDay;
                        _calculateCycleDates();
                      });
                      _loadData();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  void _showDayPicker(BuildContext context, int currentDay, Function(int) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  const Text(
                    'Select Day',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(initialItem: currentDay - 1),
                onSelectedItemChanged: (index) => onSelect(index + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 28,
                  builder: (context, index) {
                    final day = index + 1;
                    return Center(
                      child: Text(
                        _formatDayWithSuffix(day),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Expense expense;
  final String Function(int) formatAmount;
  final String Function(DateTime) formatDate;
  final bool isLast;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.expense,
    required this.formatAmount,
    required this.formatDate,
    required this.isLast,
    required this.onTap,
  });

  String get _typeLabel {
    switch (expense.type) {
      case 'needs': return 'Needs';
      case 'wants': return 'Wants';
      case 'savings': return 'Savings';
      case 'income': return 'Income';
      default: return expense.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';

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
                    expense.categoryName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_typeLabel · ${formatDate(expense.date)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome ? '+' : '-'}₹${formatAmount(expense.amount)}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isIncome ? const Color(0xFF34C759) : Colors.black,
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
  final String Function(DateTime) formatDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExpenseDetailSheet({
    required this.expense,
    required this.formatAmount,
    required this.formatDate,
    required this.onEdit,
    required this.onDelete,
  });

  String get _typeLabel {
    switch (expense.type) {
      case 'needs': return 'Needs';
      case 'wants': return 'Wants';
      case 'savings': return 'Savings';
      case 'income': return 'Income';
      default: return expense.type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';

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
                '${isIncome ? '+' : '-'}₹${formatAmount(expense.amount)}',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? const Color(0xFF34C759) : Colors.black,
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
                '$_typeLabel · ${formatDate(expense.date)}',
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
