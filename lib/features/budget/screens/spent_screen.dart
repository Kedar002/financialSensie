import 'package:flutter/material.dart';

class SpentScreen extends StatelessWidget {
  const SpentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data - in real app this would come from state management
    const income = 5850;
    const needs = 1200;
    const wants = 350;
    const savings = 650;
    const total = needs + wants + savings;

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
              child: ListView(
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
                        const Text(
                          '₹$total',
                          style: TextStyle(
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
                          amount: needs,
                          percentage: ((needs / income) * 100).round(),
                          color: const Color(0xFF007AFF),
                          subtitle: 'Resets each cycle',
                          onTap: () {},
                        ),
                        const _Divider(),
                        _SpendingCategoryItem(
                          name: 'Wants',
                          amount: wants,
                          percentage: ((wants / income) * 100).round(),
                          color: const Color(0xFFFF9500),
                          subtitle: 'Resets each cycle',
                          onTap: () {},
                        ),
                        const _Divider(),
                        _SpendingCategoryItem(
                          name: 'Savings',
                          amount: savings,
                          percentage: ((savings / income) * 100).round(),
                          color: const Color(0xFF34C759),
                          subtitle: 'Accumulates over time',
                          isLast: true,
                          onTap: () {},
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
                          actual: ((needs / income) * 100).round(),
                          color: const Color(0xFF007AFF),
                        ),
                        const SizedBox(height: 8),
                        _BudgetRule(
                          label: 'Wants',
                          recommended: 30,
                          actual: ((wants / income) * 100).round(),
                          color: const Color(0xFFFF9500),
                        ),
                        const SizedBox(height: 8),
                        _BudgetRule(
                          label: 'Savings',
                          recommended: 20,
                          actual: ((savings / income) * 100).round(),
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
  final int amount;
  final int percentage;
  final Color color;
  final String subtitle;
  final bool isLast;
  final VoidCallback onTap;

  const _SpendingCategoryItem({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.subtitle,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFC7C7CC),
            ),
          ],
        ),
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
