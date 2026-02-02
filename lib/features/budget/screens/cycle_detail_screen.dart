import 'package:flutter/material.dart';
import '../../../core/models/cycle_history.dart';
import '../../../core/models/expense.dart';
import '../../../core/repositories/expense_repository.dart';

const _white60 = Color(0x99FFFFFF);
const _white50 = Color(0x80FFFFFF);
const _white40 = Color(0x66FFFFFF);
const _white80 = Color(0xCCFFFFFF);

class CycleDetailScreen extends StatefulWidget {
  final CycleHistory cycle;

  const CycleDetailScreen({
    super.key,
    required this.cycle,
  });

  @override
  State<CycleDetailScreen> createState() => _CycleDetailScreenState();
}

class _CycleDetailScreenState extends State<CycleDetailScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<Expense> _expenses = [];
  bool _isLoading = true;

  CycleHistory get cycle => widget.cycle;

  double get _needsPercent =>
      cycle.totalSpent > 0 ? cycle.needsSpent / cycle.totalSpent : 0;
  double get _wantsPercent =>
      cycle.totalSpent > 0 ? cycle.wantsSpent / cycle.totalSpent : 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final expenses = await _expenseRepository.getByDateRange(
      cycle.cycleStart,
      cycle.cycleEnd,
    );
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Cycle name
                      Center(
                        child: Text(
                          cycle.cycleName,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          '${_formatDate(cycle.cycleStart)} – ${_formatDate(cycle.cycleEnd)}',
                          style: TextStyle(
                            fontSize: 15,
                            color: _white50,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '₹${_formatAmount(cycle.remaining)}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              cycle.remaining >= 0 ? 'unspent' : 'overspent',
                              style: TextStyle(
                                fontSize: 15,
                                color: _white50,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Spending bar
                            _buildSpendingBar(),

                            const SizedBox(height: 24),

                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('Needs', Colors.white),
                                const SizedBox(width: 24),
                                _buildLegendItem('Wants', _white50),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Income',
                              '₹${_formatAmount(cycle.totalIncome)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Spent',
                              '₹${_formatAmount(cycle.totalSpent)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Saved',
                              '₹${_formatAmount(cycle.savingsAdded)}',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Breakdown
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildBreakdownRow(
                                'Needs', cycle.needsSpent, _getPercentOfIncome(cycle.needsSpent)),
                            const SizedBox(height: 16),
                            _buildBreakdownRow(
                                'Wants', cycle.wantsSpent, _getPercentOfIncome(cycle.wantsSpent)),
                            const SizedBox(height: 16),
                            _buildBreakdownRow(
                                'Savings', cycle.savingsAdded, _getPercentOfIncome(cycle.savingsAdded)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Transactions section
                      Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _white80,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Transactions list
                      _buildTransactionsList(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: _white40,
              ),
              const SizedBox(height: 12),
              Text(
                'No transactions',
                style: TextStyle(
                  fontSize: 16,
                  color: _white50,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: _expenses.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final isLast = index == _expenses.length - 1;

          return _TransactionItem(
            expense: expense,
            isLast: isLast,
            formatAmount: _formatAmount,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSpendingBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Flexible(
            flex: (_needsPercent * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Flexible(
            flex: (_wantsPercent * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: _white50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (_needsPercent + _wantsPercent < 1)
            Flexible(
              flex: ((1 - _needsPercent - _wantsPercent) * 100).round(),
              child: const SizedBox(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _white50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int amount, int percent) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: _white80,
            ),
          ),
        ),
        Text(
          '₹${_formatAmount(amount)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          alignment: Alignment.centerRight,
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 14,
              color: _white40,
            ),
          ),
        ),
      ],
    );
  }

  int _getPercentOfIncome(int amount) {
    if (cycle.totalIncome == 0) return 0;
    return ((amount / cycle.totalIncome) * 100).round();
  }

  String _formatAmount(int amountInPaise) {
    final value = amountInPaise / 100;
    final absValue = value.abs();
    String formatted;
    if (absValue == absValue.truncate()) {
      formatted = absValue.truncate().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } else {
      formatted = absValue.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return amountInPaise < 0 ? '-$formatted' : formatted;
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _TransactionItem extends StatelessWidget {
  final Expense expense;
  final bool isLast;
  final String Function(int) formatAmount;

  const _TransactionItem({
    required this.expense,
    required this.isLast,
    required this.formatAmount,
  });

  String get _typeLabel {
    switch (expense.type) {
      case 'needs':
        return 'Needs';
      case 'wants':
        return 'Wants';
      case 'savings':
        return 'Savings';
      case 'income':
        return 'Income';
      default:
        return expense.type;
    }
  }

  Color get _typeColor {
    switch (expense.type) {
      case 'needs':
        return const Color(0xFF007AFF);
      case 'wants':
        return const Color(0xFFFF9500);
      case 'savings':
        return const Color(0xFF34C759);
      case 'income':
        return const Color(0xFF34C759);
      default:
        return _white50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = expense.type == 'income';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFF2C2C2E),
                  width: 1,
                ),
              ),
      ),
      child: Row(
        children: [
          // Type indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _typeColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),

          // Transaction info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.categoryName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_typeLabel · ${_formatTransactionDate(expense.date)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: _white50,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isIncome ? '+' : '-'}₹${formatAmount(expense.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isIncome ? const Color(0xFF34C759) : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTransactionDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
