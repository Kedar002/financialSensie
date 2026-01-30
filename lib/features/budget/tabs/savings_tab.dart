import 'package:flutter/material.dart';

class SavingsTab extends StatelessWidget {
  final VoidCallback onMenuTap;

  const SavingsTab({super.key, required this.onMenuTap});

  final List<Map<String, dynamic>> _goals = const [
    {'name': 'Emergency Fund', 'thisMonth': 400, 'total': 4800, 'icon': Icons.shield_outlined},
    {'name': 'Vacation', 'thisMonth': 150, 'total': 900, 'icon': Icons.flight_outlined},
    {'name': 'Retirement', 'thisMonth': 100, 'total': 2400, 'icon': Icons.trending_up_outlined},
    {'name': 'New Car', 'thisMonth': 0, 'total': 0, 'icon': Icons.directions_car_outlined},
    {'name': 'Education', 'thisMonth': 0, 'total': 0, 'icon': Icons.school_outlined},
    {'name': 'Investments', 'thisMonth': 0, 'total': 0, 'icon': Icons.show_chart_outlined},
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
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _goals.length,
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return GestureDetector(
                        onTap: () => _showEditGoal(context, goal['name'], goal['total']),
                        child: _SavingsCard(
                          name: goal['name'],
                          thisMonth: goal['thisMonth'],
                          total: goal['total'],
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

  void _showEditGoal(BuildContext context, String name, int total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGoalSheet(name: name, total: total),
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
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Savings Goal',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextField(
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Goal name',
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
              const SizedBox(height: 12),

              // Amount field
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Monthly contribution',
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
    );
  }
}

class _EditGoalSheet extends StatelessWidget {
  final String name;
  final int total;

  const _EditGoalSheet({required this.name, required this.total});

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
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E5E5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Amount field
              TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Add to savings',
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

              const SizedBox(height: 12),

              // Delete button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Delete',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF3B30),
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

class _SavingsCard extends StatelessWidget {
  final String name;
  final int thisMonth;
  final int total;
  final IconData icon;

  const _SavingsCard({
    required this.name,
    required this.thisMonth,
    required this.total,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasActivity = total > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (hasActivity)
                  Text(
                    '₹$total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF34C759),
                    ),
                  )
                else
                  const Text(
                    'No savings yet',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFFC7C7CC),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
