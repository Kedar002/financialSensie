import 'package:flutter/material.dart';
import '../screens/income_screen.dart';
import '../screens/transactions_screen.dart';
import '../sheets/add_expense_sheet.dart';

class ExpensesTab extends StatelessWidget {
  final VoidCallback onMenuTap;

  const ExpensesTab({super.key, required this.onMenuTap});

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
                    onTap: onMenuTap,
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
              child: ListView(
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
                        const Text(
                          'January 2025',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '₹2,450',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Remaining this month',
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
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const IncomeScreen()),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Income',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹5,000',
                                        style: TextStyle(
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
                                onTap: () => _showSpendingBreakdown(context),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Spent',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹2,550',
                                        style: TextStyle(
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
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TransactionsScreen(),
                            ),
                          ),
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

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _TransactionTile(
                          title: 'Groceries',
                          subtitle: 'Needs · Today',
                          amount: '-₹45.20',
                          isFirst: true,
                        ),
                        _TransactionTile(
                          title: 'Coffee',
                          subtitle: 'Wants · Today',
                          amount: '-₹4.50',
                        ),
                        _TransactionTile(
                          title: 'Salary',
                          subtitle: 'Income · Yesterday',
                          amount: '+₹5,000',
                          isPositive: true,
                          isLast: true,
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

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddExpenseSheet(),
    );
  }

  void _showSpendingBreakdown(BuildContext context) {
    const income = 5000.0;
    const needs = 1200.0;
    const wants = 350.0;
    const savings = 650.0;
    const total = needs + wants + savings;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Spending Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SpendingCategory(
                  name: 'Needs',
                  amount: needs,
                  income: income,
                  color: const Color(0xFF007AFF),
                ),
                const SizedBox(height: 16),
                _SpendingCategory(
                  name: 'Wants',
                  amount: wants,
                  income: income,
                  color: const Color(0xFFFF9500),
                ),
                const SizedBox(height: 16),
                _SpendingCategory(
                  name: 'Savings',
                  amount: savings,
                  income: income,
                  color: const Color(0xFF34C759),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpendingCategory extends StatelessWidget {
  final String name;
  final double amount;
  final double income;
  final Color color;

  const _SpendingCategory({
    required this.name,
    required this.amount,
    required this.income,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (amount / income * 100).round();
    final barWidth = amount / income;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(color.r.toInt(), color.g.toInt(), color.b.toInt(), 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: barWidth.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isPositive;
  final bool isFirst;
  final bool isLast;

  const _TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isPositive = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  title,
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
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF34C759) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
