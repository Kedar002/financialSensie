import 'package:flutter/material.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'all';
  DateTime _selectedMonth = DateTime.now();
  DateTime? _selectedDate;
  bool _showCalendar = false;

  final List<Map<String, dynamic>> _transactions = [
    {'title': 'Groceries', 'type': 'needs', 'amount': -245, 'date': DateTime(2025, 1, 30)},
    {'title': 'Coffee', 'type': 'wants', 'amount': -4.50, 'date': DateTime(2025, 1, 30)},
    {'title': 'Salary', 'type': 'income', 'amount': 5000, 'date': DateTime(2025, 1, 29)},
    {'title': 'Rent', 'type': 'needs', 'amount': -800, 'date': DateTime(2025, 1, 28)},
    {'title': 'Emergency Fund', 'type': 'savings', 'amount': -400, 'date': DateTime(2025, 1, 28)},
    {'title': 'Dining Out', 'type': 'wants', 'amount': -85, 'date': DateTime(2025, 1, 27)},
    {'title': 'Utilities', 'type': 'needs', 'amount': -155, 'date': DateTime(2025, 1, 25)},
    {'title': 'Entertainment', 'type': 'wants', 'amount': -45, 'date': DateTime(2025, 1, 24)},
    {'title': 'Vacation Fund', 'type': 'savings', 'amount': -150, 'date': DateTime(2025, 1, 20)},
    {'title': 'Freelance', 'type': 'income', 'amount': 1200, 'date': DateTime(2025, 1, 15)},
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((t) {
      final matchesFilter = _selectedFilter == 'all' || t['type'] == _selectedFilter;
      final matchesMonth = t['date'].month == _selectedMonth.month &&
                           t['date'].year == _selectedMonth.year;
      final matchesDate = _selectedDate == null ||
                          (t['date'].day == _selectedDate!.day &&
                           t['date'].month == _selectedDate!.month &&
                           t['date'].year == _selectedDate!.year);
      return matchesFilter && matchesMonth && matchesDate;
    }).toList();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      _selectedDate = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      _selectedDate = null;
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
            _buildHeader(),

            // Month Navigator
            _buildMonthNavigator(),

            // Calendar Grid (collapsible)
            if (_showCalendar) _buildCalendarGrid(),

            // Filter Chips
            _buildFilterChips(),

            const SizedBox(height: 8),

            // Selected date indicator
            if (_selectedDate != null) _buildSelectedDateChip(),

            // Transactions List
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
              'Transactions',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMonthNavigator() {
    final months = ['January', 'February', 'March', 'April', 'May', 'June',
                    'July', 'August', 'September', 'October', 'November', 'December'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _previousMonth,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.chevron_left,
                size: 24,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showCalendar = !_showCalendar),
            child: Row(
              children: [
                Text(
                  '${months[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCalendar ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: const Color(0xFF8E8E93),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _nextMonth,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.chevron_right,
                size: 24,
                color: Color(0xFF007AFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;
    final today = DateTime.now();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => SizedBox(
              width: 36,
              child: Text(
                d,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar days
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex + 1 - (startingWeekday - 1);

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 36, height: 36);
                  }

                  final date = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
                  final isSelected = _selectedDate?.day == dayNumber &&
                                    _selectedDate?.month == _selectedMonth.month &&
                                    _selectedDate?.year == _selectedMonth.year;
                  final isToday = today.day == dayNumber &&
                                 today.month == _selectedMonth.month &&
                                 today.year == _selectedMonth.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDate = null;
                        } else {
                          _selectedDate = date;
                        }
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : null,
                        shape: BoxShape.circle,
                        border: isToday && !isSelected
                            ? Border.all(color: const Color(0xFF007AFF), width: 1.5)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'needs', 'label': 'Needs'},
      {'key': 'wants', 'label': 'Wants'},
      {'key': 'savings', 'label': 'Savings'},
      {'key': 'income', 'label': 'Income'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter['key']!),
              child: Container(
                margin: EdgeInsets.only(right: filter['key'] != 'income' ? 6 : 0),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  filter['label']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedDateChip() {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_selectedDate!.day} ${months[_selectedDate!.month - 1]}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = null),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList() {
    // Group transactions by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final t in _filteredTransactions) {
      final date = t['date'] as DateTime;
      final key = '${date.year}-${date.month}-${date.day}';
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final transactions = grouped[dateKey]!;
        final date = transactions.first['date'] as DateTime;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 12, bottom: 8),
              child: Text(
                _formatDate(date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: transactions.asMap().entries.map((entry) {
                  final t = entry.value;
                  final isLast = entry.key == transactions.length - 1;
                  return _TransactionTile(
                    title: t['title'],
                    type: t['type'],
                    amount: t['amount'],
                    isLast: isLast,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (dateOnly == todayOnly) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }
}

class _TransactionTile extends StatelessWidget {
  final String title;
  final String type;
  final double amount;
  final bool isLast;

  const _TransactionTile({
    required this.title,
    required this.type,
    required this.amount,
    this.isLast = false,
  });

  String get _typeLabel {
    switch (type) {
      case 'needs': return 'Needs';
      case 'wants': return 'Wants';
      case 'savings': return 'Savings';
      case 'income': return 'Income';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = amount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF2F2F7), width: 1),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _typeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}₹${amount.abs().toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isPositive ? const Color(0xFF34C759) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
