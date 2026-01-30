import 'package:flutter/material.dart';

class StatisticsTab extends StatefulWidget {
  final VoidCallback onMenuTap;

  const StatisticsTab({super.key, required this.onMenuTap});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  int _selectedMonthIndex = 0;

  final List<Map<String, dynamic>> _months = const [
    {'month': 'Jan', 'year': 2025, 'income': 5850, 'needs': 1200, 'wants': 350, 'savings': 650},
    {'month': 'Dec', 'year': 2024, 'income': 5850, 'needs': 1450, 'wants': 520, 'savings': 400},
    {'month': 'Nov', 'year': 2024, 'income': 5500, 'needs': 1300, 'wants': 480, 'savings': 350},
    {'month': 'Oct', 'year': 2024, 'income': 5500, 'needs': 1100, 'wants': 390, 'savings': 500},
    {'month': 'Sep', 'year': 2024, 'income': 5200, 'needs': 1250, 'wants': 420, 'savings': 300},
    {'month': 'Aug', 'year': 2024, 'income': 5200, 'needs': 1180, 'wants': 380, 'savings': 450},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  // Title + Month selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _MonthSelector(
                        months: _months,
                        selectedIndex: _selectedMonthIndex,
                        onChanged: (index) => setState(() => _selectedMonthIndex = index),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Needs
                  _CategoryCard(
                    title: 'Needs',
                    color: const Color(0xFF007AFF),
                    months: _months,
                    valueKey: 'needs',
                    selectedIndex: _selectedMonthIndex,
                  ),

                  const SizedBox(height: 12),

                  // Wants
                  _CategoryCard(
                    title: 'Wants',
                    color: const Color(0xFFFF9500),
                    months: _months,
                    valueKey: 'wants',
                    selectedIndex: _selectedMonthIndex,
                  ),

                  const SizedBox(height: 12),

                  // Savings
                  _CategoryCard(
                    title: 'Savings',
                    color: const Color(0xFF34C759),
                    months: _months,
                    valueKey: 'savings',
                    selectedIndex: _selectedMonthIndex,
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

class _MonthSelector extends StatelessWidget {
  final List<Map<String, dynamic>> months;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _MonthSelector({
    required this.months,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = months[selectedIndex];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: selectedIndex < months.length - 1
                ? () => onChanged(selectedIndex + 1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: selectedIndex < months.length - 1
                    ? Colors.black
                    : const Color(0xFFD1D1D6),
              ),
            ),
          ),
          Text(
            "${current['month']} '${current['year'].toString().substring(2)}",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          GestureDetector(
            onTap: selectedIndex > 0
                ? () => onChanged(selectedIndex - 1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: selectedIndex > 0
                    ? Colors.black
                    : const Color(0xFFD1D1D6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<Map<String, dynamic>> months;
  final String valueKey;
  final int selectedIndex;

  const _CategoryCard({
    required this.title,
    required this.color,
    required this.months,
    required this.valueKey,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final displayMonths = months.take(6).toList().reversed.toList();
    final maxValue = displayMonths.fold<int>(
      1,
      (max, m) => (m[valueKey] as int) > max ? (m[valueKey] as int) : max,
    );

    final currentValue = months[selectedIndex][valueKey] as int;
    final income = months[selectedIndex]['income'] as int;
    final percentage = income > 0 ? ((currentValue / income) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(title),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹$currentValue',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$percentage% of income',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bar chart
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayMonths.asMap().entries.map((entry) {
              final index = entry.key;
              final month = entry.value;
              final value = month[valueKey] as int;
              final isSelected = index == displayMonths.length - 1 - selectedIndex;
              final barHeight = (value / maxValue * 60).clamp(6.0, 60.0);

              return Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: barHeight,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      month['month'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(String title) {
    switch (title) {
      case 'Needs':
        return Icons.home_outlined;
      case 'Wants':
        return Icons.favorite_outline;
      case 'Savings':
        return Icons.savings_outlined;
      default:
        return Icons.attach_money;
    }
  }
}
