import 'package:flutter/material.dart';
import '../screens/goal_details_screen.dart';

class SavingsTab extends StatelessWidget {
  final VoidCallback onMenuTap;

  const SavingsTab({super.key, required this.onMenuTap});

  final List<Map<String, dynamic>> _goals = const [
    {
      'name': 'Emergency Fund',
      'target': 50000,
      'saved': 4800,
      'monthly': 400,
      'targetDate': '2025-12-31',
      'icon': Icons.shield_outlined,
    },
    {
      'name': 'Vacation',
      'target': 25000,
      'saved': 900,
      'monthly': 150,
      'targetDate': '2025-06-15',
      'icon': Icons.flight_outlined,
    },
    {
      'name': 'Retirement',
      'target': 500000,
      'saved': 2400,
      'monthly': 100,
      'targetDate': '2045-01-01',
      'icon': Icons.trending_up_outlined,
    },
    {
      'name': 'New Car',
      'target': 300000,
      'saved': 0,
      'monthly': 0,
      'targetDate': '2026-12-31',
      'icon': Icons.directions_car_outlined,
    },
  ];

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
                    onTap: () => _showAddGoal(context),
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
                  // Title Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Saved',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '₹8,100',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF34C759),
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'This cycle',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              Text(
                                '+₹650',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF34C759),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Goals Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return GestureDetector(
                        onTap: () => _showGoalDetails(context, goal),
                        child: _SavingsCard(
                          name: goal['name'],
                          target: goal['target'],
                          saved: goal['saved'],
                          icon: goal['icon'],
                        ),
                      );
                    },
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

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddGoalSheet(),
    );
  }

  void _showGoalDetails(BuildContext context, Map<String, dynamic> goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailsScreen(goal: goal),
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  final String name;
  final int target;
  final int saved;
  final IconData icon;

  const _SavingsCard({
    required this.name,
    required this.target,
    required this.saved,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();
    final hasActivity = saved > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasActivity ? const Color(0xFFE8F5E9) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasActivity ? const Color(0xFF34C759) : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasActivity ? const Color(0xFF34C759) : const Color(0xFFC7C7CC),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            hasActivity ? '₹$saved / ₹$target' : 'No savings yet',
            style: TextStyle(
              fontSize: 13,
              color: hasActivity ? Colors.black54 : const Color(0xFFC7C7CC),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends StatelessWidget {
  const _AddGoalSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'New Savings Goal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Specific - Goal name
              const Text(
                'WHAT ARE YOU SAVING FOR?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Emergency Fund, Vacation',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Measurable - Target amount
              const Text(
                'TARGET AMOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Time-bound - Target date
              const Text(
                'TARGET DATE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select date',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 20,
                        color: Color(0xFF8E8E93),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Achievable - Monthly contribution
              const Text(
                'MONTHLY CONTRIBUTION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Create Goal',
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
    );
  }
}

