import 'package:flutter/material.dart';

// Color constants for the dark theme
const _white60 = Color(0x99FFFFFF);
const _white50 = Color(0x80FFFFFF);
const _white40 = Color(0x66FFFFFF);
const _white80 = Color(0xCCFFFFFF);

class CycleCompleteScreen extends StatelessWidget {
  final String cycleName;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final int totalIncome;
  final int totalSpent;
  final int needsSpent;
  final int wantsSpent;
  final int savingsAdded;
  final VoidCallback onStartNewCycle;

  const CycleCompleteScreen({
    super.key,
    this.cycleName = 'January',
    required this.cycleStart,
    required this.cycleEnd,
    this.totalIncome = 50000,
    this.totalSpent = 35000,
    this.needsSpent = 20000,
    this.wantsSpent = 10000,
    this.savingsAdded = 5000,
    required this.onStartNewCycle,
  });

  int get _remaining => totalIncome - totalSpent - savingsAdded;
  double get _needsPercent => totalSpent > 0 ? needsSpent / totalSpent : 0;
  double get _wantsPercent => totalSpent > 0 ? wantsSpent / totalSpent : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      // Completion badge
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Cycle name
                      Text(
                        cycleName,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'Cycle Complete',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: _white60,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${_formatDate(cycleStart)} – ${_formatDate(cycleEnd)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _white40,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Remaining highlight
                            Text(
                              '₹${_formatAmount(_remaining)}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _remaining >= 0 ? 'unspent' : 'overspent',
                              style: TextStyle(
                                fontSize: 15,
                                color: _white50,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Spending bar
                            _buildSpendingBar(),

                            const SizedBox(height: 24),

                            // Legend
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildLegendItem('Needs', Colors.white),
                                const SizedBox(width: 24),
                                _buildLegendItem('Wants', _white50),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Income',
                              '₹${_formatAmount(totalIncome)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Spent',
                              '₹${_formatAmount(totalSpent)}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Saved',
                              '₹${_formatAmount(savingsAdded)}',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Breakdown
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            _buildBreakdownRow('Needs', needsSpent, _getPercentOfIncome(needsSpent)),
                            const SizedBox(height: 16),
                            _buildBreakdownRow('Wants', wantsSpent, _getPercentOfIncome(wantsSpent)),
                            const SizedBox(height: 16),
                            _buildBreakdownRow('Savings', savingsAdded, _getPercentOfIncome(savingsAdded)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom action
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: onStartNewCycle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Start New Cycle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingBar() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Flexible(
            flex: (_needsPercent * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Flexible(
            flex: (_wantsPercent * 100).round(),
            child: Container(
              decoration: BoxDecoration(
                color: _white50,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (_needsPercent + _wantsPercent < 1)
            Flexible(
              flex: ((1 - _needsPercent - _wantsPercent) * 100).round(),
              child: const SizedBox(),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _white50,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, int amount, int percent) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: _white80,
            ),
          ),
        ),
        Text(
          '₹${_formatAmount(amount)}',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 48,
          alignment: Alignment.centerRight,
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 14,
              color: _white40,
            ),
          ),
        ),
      ],
    );
  }

  int _getPercentOfIncome(int amount) {
    if (totalIncome == 0) return 0;
    return ((amount / totalIncome) * 100).round();
  }

  String _formatAmount(int amount) {
    final absAmount = amount.abs();
    final formatted = absAmount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return amount < 0 ? '-$formatted' : formatted;
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }
}
