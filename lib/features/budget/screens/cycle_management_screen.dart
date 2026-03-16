import 'package:flutter/material.dart';
import '../../../core/repositories/cycle_repository.dart';
import '../../../core/repositories/cycle_settings_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import 'cycle_complete_screen.dart';

class CycleManagementScreen extends StatefulWidget {
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final int totalBalance;
  final int totalSpent;
  final int payCycleDay;
  final VoidCallback onCycleChanged;

  const CycleManagementScreen({
    super.key,
    required this.cycleStart,
    required this.cycleEnd,
    required this.totalBalance,
    required this.totalSpent,
    required this.payCycleDay,
    required this.onCycleChanged,
  });

  @override
  State<CycleManagementScreen> createState() => _CycleManagementScreenState();
}

class _CycleManagementScreenState extends State<CycleManagementScreen> {
  final CycleRepository _cycleRepository = CycleRepository();
  final CycleSettingsRepository _cycleSettingsRepository = CycleSettingsRepository();
  final ExpenseRepository _repository = ExpenseRepository();

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}';
  }

  int get _daysRemaining {
    final now = DateTime.now();
    final difference = widget.cycleEnd.difference(now).inDays;
    return difference < 0 ? 0 : difference;
  }

  String _formatDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  String _getCycleName() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];
    return months[widget.cycleStart.month - 1];
  }

  void _showEndCycle() async {
    final spentByType = await _repository.getSpentByType(
      start: widget.cycleStart,
      end: widget.cycleEnd,
    );

    if (!mounted) return;

    final cycleName = _getCycleName();
    final needsSpent = spentByType['needs'] ?? 0;
    final wantsSpent = spentByType['wants'] ?? 0;
    final savingsAdded = spentByType['savings'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CycleCompleteScreen(
          cycleName: cycleName,
          cycleStart: widget.cycleStart,
          cycleEnd: widget.cycleEnd,
          totalIncome: widget.totalBalance,
          totalSpent: widget.totalSpent,
          needsSpent: needsSpent,
          wantsSpent: wantsSpent,
          savingsAdded: savingsAdded,
          onStartNewCycle: () => _startNewCycle(
            cycleName: cycleName,
            needsSpent: needsSpent,
            wantsSpent: wantsSpent,
            savingsAdded: savingsAdded,
          ),
        ),
      ),
    );
  }

  Future<void> _startNewCycle({
    required String cycleName,
    required int needsSpent,
    required int wantsSpent,
    required int savingsAdded,
  }) async {
    await _cycleRepository.completeCycle(
      cycleName: cycleName,
      cycleStart: widget.cycleStart,
      cycleEnd: widget.cycleEnd,
      totalIncome: widget.totalBalance,
      totalSpent: widget.totalSpent,
      needsSpent: needsSpent,
      wantsSpent: wantsSpent,
      savingsAdded: savingsAdded,
    );

    await _cycleSettingsRepository.startNextCycle();

    if (!mounted) return;

    // Pop cycle complete screen
    Navigator.pop(context);
    // Pop cycle management screen
    Navigator.pop(context);

    widget.onCycleChanged();
  }

  void _showCycleSettings() {
    int selectedDay = widget.payCycleDay;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
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
                  const Text(
                    'Pay Cycle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When do you receive your paycheck?',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Every month on the',
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showDayPicker(context, selectedDay, (day) {
                          setModalState(() => selectedDay = day);
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _formatDayWithSuffix(selectedDay),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 20,
                                color: Color(0xFF8E8E93),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Saving will reset cycle dates to include today',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      await _cycleSettingsRepository.updatePayCycleDay(selectedDay);
                      widget.onCycleChanged();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save & Reset Cycle',
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
        ),
      ),
    );
  }

  void _showDayPicker(BuildContext context, int currentDay, Function(int) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                  const Text(
                    'Select Day',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(initialItem: currentDay - 1),
                onSelectedItemChanged: (index) => onSelect(index + 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 28,
                  builder: (context, index) {
                    final day = index + 1;
                    return Center(
                      child: Text(
                        _formatDayWithSuffix(day),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Cycle',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(widget.cycleStart)} – ${_formatDate(widget.cycleEnd)}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$_daysRemaining days remaining',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _showEndCycle,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'End Current Cycle',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showCycleSettings,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pay Cycle Settings',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Day ${widget.payCycleDay}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF8E8E93),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
