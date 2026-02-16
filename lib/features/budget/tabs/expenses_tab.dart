import 'package:flutter/material.dart';
import '../../../core/models/expense.dart';
import '../../../core/repositories/cycle_repository.dart';
import '../../../core/repositories/cycle_settings_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/repositories/income_repository.dart';
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
  final IncomeRepository _incomeRepository = IncomeRepository();
  final CycleRepository _cycleRepository = CycleRepository();
  final CycleSettingsRepository _cycleSettingsRepository = CycleSettingsRepository();
  List<Expense> _recentExpenses = [];
  bool _isLoading = true;
  int _totalBalance = 0;
  int _totalSpent = 0;
  int _cashSpent = 0;
  int _cardSpent = 0;

  // Cycle dates (loaded from database)
  late DateTime _cycleStart;
  late DateTime _cycleEnd;
  int _payCycleDay = 1;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadCycleSettings();
    await _loadData();
  }

  Future<void> _loadCycleSettings() async {
    final settings = await _cycleSettingsRepository.get();
    _cycleStart = settings.cycleStart;
    _cycleEnd = settings.cycleEnd;
    _payCycleDay = settings.payCycleDay;
  }

  Future<void> _loadData() async {
    final expenses = await _repository.getRecent(limit: 5);
    final spent = await _repository.getTotalSpent(start: _cycleStart, end: _cycleEnd);
    final spentByMethod = await _repository.getSpentByPaymentMethod(start: _cycleStart, end: _cycleEnd);

    // Balance = Sum of all income category amounts
    final incomeCategories = await _incomeRepository.getAll();
    final balance = incomeCategories.fold<int>(0, (sum, cat) => sum + (cat.amount * 100)); // Convert rupees to paise

    setState(() {
      _recentExpenses = expenses;
      _totalBalance = balance;
      _totalSpent = spent;
      _cashSpent = spentByMethod['cash'] ?? 0;
      _cardSpent = spentByMethod['card'] ?? 0;
      _isLoading = false;
    });
  }

  int get _remaining => _totalBalance - _totalSpent;

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
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                                'Balance',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF8E8E93),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${_formatAmount(_totalBalance)}',
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
                                              if (_cardSpent > 0) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  _cashSpent > 0
                                                      ? '₹${_formatAmount(_cashSpent)} cash · ₹${_formatAmount(_cardSpent)} card'
                                                      : '₹${_formatAmount(_cardSpent)} on card',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF8E8E93),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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

    final cycleName = _getCycleName();
    final needsSpent = spentByType['needs'] ?? 0;
    final wantsSpent = spentByType['wants'] ?? 0;
    final savingsAdded = spentByType['savings'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleCompleteScreen(
          cycleName: cycleName,
          cycleStart: _cycleStart,
          cycleEnd: _cycleEnd,
          totalIncome: _totalBalance,
          totalSpent: _totalSpent,
          needsSpent: needsSpent,
          wantsSpent: wantsSpent,
          savingsAdded: savingsAdded,
          onStartNewCycle: () => _startNewCycle(
            cycleName: cycleName,
            needsSpent: needsSpent,
            wantsSpent: wantsSpent,
            savingsAdded: savingsAdded,
          ),
        ),
      ),
    );
  }

  Future<void> _startNewCycle({
    required String cycleName,
    required int needsSpent,
    required int wantsSpent,
    required int savingsAdded,
  }) async {
    // Archive the current cycle and reset budget categories
    await _cycleRepository.completeCycle(
      cycleName: cycleName,
      cycleStart: _cycleStart,
      cycleEnd: _cycleEnd,
      totalIncome: _totalBalance,
      totalSpent: _totalSpent,
      needsSpent: needsSpent,
      wantsSpent: wantsSpent,
      savingsAdded: savingsAdded,
    );

    // Move to next cycle dates in database
    final nextCycle = await _cycleSettingsRepository.startNextCycle();
    _cycleStart = nextCycle.cycleStart;
    _cycleEnd = nextCycle.cycleEnd;

    if (!mounted) return;

    // Navigate back to expenses tab
    Navigator.pop(context);

    // Reload data to reflect the reset
    await _loadData();
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Saving will reset cycle dates to include today',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      // Save to database and update local state
                      final updated = await _cycleSettingsRepository.updatePayCycleDay(selectedDay);
                      this.setState(() {
                        _payCycleDay = updated.payCycleDay;
                        _cycleStart = updated.cycleStart;
                        _cycleEnd = updated.cycleEnd;
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
                        'Save & Reset Cycle',
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

  String get _subtitle {
    final parts = <String>[];
    if (_hasNote) parts.add(expense.categoryName);
    parts.add(_typeLabel);
    parts.add(formatDate(expense.date));
    if (expense.isExpense && expense.paymentMethod == 'card') {
      parts.add('Card');
    }
    return parts.join(' · ');
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
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isIncome || isWithdrawal ? '+' : '-'}₹${formatAmount(expense.amount)}',
              style: TextStyle(
                fontSize: 17,
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
      case 'savings_withdrawal': return 'Withdrawal';
      case 'income': return 'Balance';
      default: return expense.type;
    }
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
                '$_typeLabel · ${formatDate(expense.date)} · ${expense.paymentMethod == 'card' ? 'Card' : 'Cash'}',
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
