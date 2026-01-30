import 'package:flutter/material.dart';

class GoalDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final saved = goal['saved'] as int;
    final target = goal['target'] as int;
    final monthly = goal['monthly'] as int;
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();
    final remaining = target - saved;
    final monthsRemaining = monthly > 0 ? (remaining / monthly).ceil() : 0;

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
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Goal header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            goal['icon'] as IconData,
                            size: 32,
                            color: const Color(0xFF34C759),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          goal['name'] as String,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentage% complete',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF34C759),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saved',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$saved',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF34C759),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Target',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$target',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Details grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Monthly',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹$monthly',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Remaining',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹$remaining',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Time estimate
                  if (monthly > 0 && remaining > 0)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '$monthsRemaining months to reach goal',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Add money button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Add Money',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Delete button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        'Delete Goal',
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
          ],
        ),
      ),
    );
  }
}
