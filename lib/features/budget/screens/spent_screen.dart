import 'package:flutter/material.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/repositories/income_repository.dart';

class SpentScreen extends StatefulWidget {
  const SpentScreen({super.key});

  @override
  State<SpentScreen> createState() => _SpentScreenState();
}

class _SpentScreenState extends State<SpentScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final IncomeRepository _incomeRepository = IncomeRepository();

  bool _isLoading = true;
  int _balance = 0;
  int _needsSpent = 0;
  int _wantsSpent = 0;
  int _savingsSpent = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Get current cycle dates
    final now = DateTime.now();
    const payCycleDay = 1;
    DateTime cycleStart;
    DateTime cycleEnd;

    if (now.day >= payCycleDay) {
      cycleStart = DateTime(now.year, now.month, payCycleDay);
      cycleEnd = DateTime(now.year, now.month + 1, payCycleDay - 1);
    } else {
      cycleStart = DateTime(now.year, now.month - 1, payCycleDay);
      cycleEnd = DateTime(now.year, now.month, payCycleDay - 1);
    }

    // Load balance from income categories
    final incomeCategories = await _incomeRepository.getAll();
    final balance = incomeCategories.fold<int>(0, (sum, cat) => sum + (cat.amount * 100));

    // Load spent by type
    final spentByType = await _expenseRepository.getSpentByType(start: cycleStart, end: cycleEnd);

    setState(() {
      _balance = balance;
      _needsSpent = spentByType['needs'] ?? 0;
      _wantsSpent = spentByType['wants'] ?? 0;
      _savingsSpent = spentByType['savings'] ?? 0;
      _isLoading = false;
    });
  }

  int get _totalSpent => _needsSpent + _wantsSpent + _savingsSpent;

  String _formatAmount(int amountInPaise) {
    final rupees = amountInPaise / 100;
    if (rupees == rupees.truncate()) {
      return rupees.truncate().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return rupees.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  int _calculatePercentage(int amount) {
    if (_balance <= 0) return 0;
    return ((amount / _balance) * 100).round();
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
                      'Spending',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Total Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total This Cycle',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${_formatAmount(_totalSpent)}',
                                style: const TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Section header
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Breakdown',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),

                        // Categories
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _SpendingCategoryItem(
                                name: 'Needs',
                                amount: _formatAmount(_needsSpent),
                                percentage: _calculatePercentage(_needsSpent),
                                color: const Color(0xFF007AFF),
                                subtitle: 'Essential expenses',
                              ),
                              const _Divider(),
                              _SpendingCategoryItem(
                                name: 'Wants',
                                amount: _formatAmount(_wantsSpent),
                                percentage: _calculatePercentage(_wantsSpent),
                                color: const Color(0xFFFF9500),
                                subtitle: 'Lifestyle expenses',
                              ),
                              const _Divider(),
                              _SpendingCategoryItem(
                                name: 'Savings',
                                amount: _formatAmount(_savingsSpent),
                                percentage: _calculatePercentage(_savingsSpent),
                                color: const Color(0xFF34C759),
                                subtitle: 'Withdrawn from goals',
                                isLast: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Budget recommendation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '50/30/20 Rule',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _BudgetRule(
                                label: 'Needs',
                                recommended: 50,
                                actual: _calculatePercentage(_needsSpent),
                                color: const Color(0xFF007AFF),
                              ),
                              const SizedBox(height: 8),
                              _BudgetRule(
                                label: 'Wants',
                                recommended: 30,
                                actual: _calculatePercentage(_wantsSpent),
                                color: const Color(0xFFFF9500),
                              ),
                              const SizedBox(height: 8),
                              _BudgetRule(
                                label: 'Savings',
                                recommended: 20,
                                actual: _calculatePercentage(_savingsSpent),
                                color: const Color(0xFF34C759),
                              ),
                            ],
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
}

class _SpendingCategoryItem extends StatelessWidget {
  final String name;
  final String amount;
  final int percentage;
  final Color color;
  final String subtitle;
  final bool isLast;

  const _SpendingCategoryItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹$amount',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Color(0xFFF2F2F7)),
    );
  }
}

class _BudgetRule extends StatelessWidget {
  final String label;
  final int recommended;
  final int actual;
  final Color color;

  const _BudgetRule({
    required this.label,
    required this.recommended,
    required this.actual,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isOnTrack = actual <= recommended;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (actual / 100).clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            '$actual% / $recommended%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isOnTrack ? const Color(0xFF34C759) : const Color(0xFFFF9500),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
