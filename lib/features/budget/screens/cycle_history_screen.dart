import 'package:flutter/material.dart';
import '../../../core/models/cycle_history.dart';
import '../../../core/repositories/cycle_repository.dart';
import 'cycle_detail_screen.dart';

class CycleHistoryScreen extends StatefulWidget {
  const CycleHistoryScreen({super.key});

  @override
  State<CycleHistoryScreen> createState() => _CycleHistoryScreenState();
}

class _CycleHistoryScreenState extends State<CycleHistoryScreen> {
  final CycleRepository _repository = CycleRepository();
  List<CycleHistory> _cycles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCycles();
  }

  Future<void> _loadCycles() async {
    final cycles = await _repository.getRecent(limit: 120);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Text(
                'Past Cycles',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _cycles.isEmpty
                      ? _buildEmptyState()
                      : _buildCycleList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 36,
                color: Color(0xFFC7C7CC),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Past Cycles',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your first budget cycle\nto see it here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8E8E93),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleList() {
    // Group cycles by year
    final groupedCycles = <int, List<CycleHistory>>{};
    for (final cycle in _cycles) {
      final year = cycle.cycleEnd.year;
      groupedCycles.putIfAbsent(year, () => []);
      groupedCycles[year]!.add(cycle);
    }

    final years = groupedCycles.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final cycles = groupedCycles[year]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Year header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
              child: Text(
                year.toString(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),

            // Cycles for this year
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: cycles.asMap().entries.map((entry) {
                  final i = entry.key;
                  final cycle = entry.value;
                  final isLast = i == cycles.length - 1;

                  return _CycleCard(
                    cycle: cycle,
                    isLast: isLast,
                    onTap: () => _openCycleDetail(cycle),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openCycleDetail(CycleHistory cycle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleDetailScreen(cycle: cycle),
      ),
    );
  }
}

class _CycleCard extends StatelessWidget {
  final CycleHistory cycle;
  final bool isLast;
  final VoidCallback onTap;

  const _CycleCard({
    required this.cycle,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = cycle.remaining >= 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF2F2F7),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isPositive
                    ? const Color(0xFF34C759).withAlpha(20)
                    : const Color(0xFFFF3B30).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 22,
                color: isPositive
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
            ),

            const SizedBox(width: 14),

            // Cycle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cycle.cycleName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDateRange(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isPositive ? '+' : ''}₹${_formatAmount(cycle.remaining)}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isPositive
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isPositive ? 'saved' : 'overspent',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
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

  String _formatDateRange() {
    return '${_formatDate(cycle.cycleStart)} – ${_formatDate(cycle.cycleEnd)}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  String _formatAmount(int amountInPaise) {
    final value = (amountInPaise.abs() / 100).round();
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
