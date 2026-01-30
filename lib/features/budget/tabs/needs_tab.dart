import 'package:flutter/material.dart';
import '../sheets/add_expense_sheet.dart';
import '../screens/category_management_screen.dart';

class NeedsTab extends StatelessWidget {
  final VoidCallback onMenuTap;

  const NeedsTab({super.key, required this.onMenuTap});

  final List<Map<String, dynamic>> _categories = const [
    {'name': 'Rent', 'amount': 800, 'icon': Icons.home_outlined},
    {'name': 'Groceries', 'amount': 245, 'icon': Icons.shopping_cart_outlined},
    {'name': 'Utilities', 'amount': 155, 'icon': Icons.bolt_outlined},
    {'name': 'Insurance', 'amount': 0, 'icon': Icons.security_outlined},
    {'name': 'Transport', 'amount': 0, 'icon': Icons.directions_car_outlined},
    {'name': 'Healthcare', 'amount': 0, 'icon': Icons.medical_services_outlined},
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddExpenseSheet(preselectedType: 'needs'),
                      );
                    },
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
                        const Text(
                          'Needs',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '₹1,200 this month',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Essential expenses you can\'t skip',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const CategoryManagementScreen(
                                      type: 'needs',
                                      title: 'Needs',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF007AFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Categories Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryCard(
                        name: cat['name'],
                        amount: cat['amount'],
                        icon: cat['icon'],
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
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final int amount;
  final IconData icon;

  const _CategoryCard({
    required this.name,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount > 0 ? '₹$amount' : 'No expenses',
            style: TextStyle(
              fontSize: 13,
              color: amount > 0 ? Colors.black : const Color(0xFFC7C7CC),
              fontWeight: amount > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
