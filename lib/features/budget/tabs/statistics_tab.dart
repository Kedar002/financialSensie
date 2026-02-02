import 'package:flutter/material.dart';
import '../../../core/models/cycle_history.dart';
import '../../../core/repositories/cycle_repository.dart';
import '../screens/cycle_history_screen.dart';

class StatisticsTab extends StatefulWidget {
  final VoidCallback onMenuTap;

  const StatisticsTab({super.key, required this.onMenuTap});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  final CycleRepository _cycleRepository = CycleRepository();
  List<CycleHistory> _cycles = [];
  int _selectedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    final cycles = await _cycleRepository.getRecent(limit: 120);
    setState(() {
      _cycles = cycles;
      _isLoading = false;
    });
  }

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
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openCycleHistory(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.history, size: 20, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cycles.isEmpty
                      ? _buildEmptyState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No cycle history yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first cycle to see statistics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final displayCycles = _cycles.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Title + Cycle selector
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
            _CycleSelector(
              cycles: _cycles,
              selectedIndex: _selectedIndex,
              onChanged: (index) => setState(() => _selectedIndex = index),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Needs
        _CategoryCard(
          title: 'Needs',
          color: const Color(0xFF007AFF),
          cycles: displayCycles,
          getValue: (c) => c.needsSpent,
          getIncome: (c) => c.totalIncome,
          selectedIndex: _selectedIndex.clamp(0, displayCycles.length - 1),
        ),

        const SizedBox(height: 12),

        // Wants
        _CategoryCard(
          title: 'Wants',
          color: const Color(0xFFFF9500),
          cycles: displayCycles,
          getValue: (c) => c.wantsSpent,
          getIncome: (c) => c.totalIncome,
          selectedIndex: _selectedIndex.clamp(0, displayCycles.length - 1),
        ),

        const SizedBox(height: 12),

        // Savings
        _CategoryCard(
          title: 'Savings',
          color: const Color(0xFF34C759),
          cycles: displayCycles,
          getValue: (c) => c.savingsAdded,
          getIncome: (c) => c.totalIncome,
          selectedIndex: _selectedIndex.clamp(0, displayCycles.length - 1),
        ),
      ],
    );
  }

  void _openCycleHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CycleHistoryScreen()),
    );
  }
}

class _CycleSelector extends StatelessWidget {
  final List<CycleHistory> cycles;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _CycleSelector({
    required this.cycles,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return const SizedBox();

    final current = cycles[selectedIndex];
    final shortName = _getShortName(current);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: selectedIndex < cycles.length - 1
                ? () => onChanged(selectedIndex + 1)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.chevron_left,
                size: 20,
                color: selectedIndex < cycles.length - 1
                    ? Colors.black
                    : const Color(0xFFD1D1D6),
              ),
            ),
          ),
          Text(
            shortName,
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

  String _getShortName(CycleHistory cycle) {
    final month = cycle.cycleName.length >= 3
        ? cycle.cycleName.substring(0, 3)
        : cycle.cycleName;
    final year = cycle.cycleEnd.year.toString().substring(2);
    return "$month '$year";
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<CycleHistory> cycles;
  final int Function(CycleHistory) getValue;
  final int Function(CycleHistory) getIncome;
  final int selectedIndex;

  const _CategoryCard({
    required this.title,
    required this.color,
    required this.cycles,
    required this.getValue,
    required this.getIncome,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (cycles.isEmpty) return const SizedBox();

    // Reverse for chronological display (oldest to newest left to right)
    final displayCycles = cycles.reversed.toList();
    final maxValue = displayCycles.fold<int>(
      1,
      (max, c) => getValue(c) > max ? getValue(c) : max,
    );

    final actualSelectedIndex = displayCycles.length - 1 - selectedIndex;
    final selectedCycle = cycles[selectedIndex];
    final currentValue = getValue(selectedCycle);
    final income = getIncome(selectedCycle);
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
                    '₹${_formatAmount(currentValue)}',
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
            children: displayCycles.asMap().entries.map((entry) {
              final index = entry.key;
              final cycle = entry.value;
              final value = getValue(cycle);
              final isSelected = index == actualSelectedIndex;
              final barHeight = maxValue > 0
                  ? (value / maxValue * 60).clamp(6.0, 60.0)
                  : 6.0;

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
                      cycle.cycleName.length >= 3
                          ? cycle.cycleName.substring(0, 3)
                          : cycle.cycleName,
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

  String _formatAmount(int amountInPaise) {
    final value = (amountInPaise / 100).round();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
