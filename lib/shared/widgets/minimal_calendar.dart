import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Steve Jobs approved calendar.
/// Clean. Minimal. Functional.
/// Shows week strip by default, expands to full month on tap.
class MinimalCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const MinimalCalendar({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<MinimalCalendar> createState() => _MinimalCalendarState();
}

class _MinimalCalendarState extends State<MinimalCalendar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppTheme.spacing16),
            _isExpanded ? _buildMonthView() : _buildWeekStrip(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final monthYear = _getMonthYear(widget.selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthYear,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        AnimatedRotation(
          turns: _isExpanded ? 0.5 : 0,
          duration: const Duration(milliseconds: 250),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: AppTheme.gray400,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    final today = DateTime.now();
    final weekDays = _getWeekDays(widget.selectedDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((date) {
        final isSelected = _isSameDay(date, widget.selectedDate);
        final isToday = _isSameDay(date, today);

        return _DayCell(
          date: date,
          isSelected: isSelected,
          isToday: isToday,
          onTap: () => widget.onDateSelected(date),
        );
      }).toList(),
    );
  }

  Widget _buildMonthView() {
    final today = DateTime.now();
    final firstDayOfMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month + 1,
      0,
    );

    final startWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: dayLabels.map((label) {
            return SizedBox(
              width: 40,
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...List.generate(
          ((daysInMonth + startWeekday - 1) / 7).ceil(),
          (weekIndex) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (dayIndex) {
                  final dayNumber =
                      weekIndex * 7 + dayIndex - startWeekday + 2;

                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox(width: 40, height: 40);
                  }

                  final date = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    dayNumber,
                  );
                  final isSelected = _isSameDay(date, widget.selectedDate);
                  final isToday = _isSameDay(date, today);

                  return _DayCell(
                    date: date,
                    isSelected: isSelected,
                    isToday: isToday,
                    onTap: () => widget.onDateSelected(date),
                  );
                }),
              ),
            );
          },
        ),
        const SizedBox(height: AppTheme.spacing8),
        _buildMonthNavigation(),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.gray400,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing32),
        GestureDetector(
          onTap: _goToToday,
          child: Text(
            'Today',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.black,
                ),
          ),
        ),
        const SizedBox(width: AppTheme.spacing32),
        GestureDetector(
          onTap: _nextMonth,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            child: const Icon(
              Icons.chevron_right,
              color: AppTheme.gray400,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  void _previousMonth() {
    final newDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month - 1,
      1,
    );
    widget.onDateSelected(newDate);
  }

  void _nextMonth() {
    final newDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month + 1,
      1,
    );
    widget.onDateSelected(newDate);
  }

  void _goToToday() {
    widget.onDateSelected(DateTime.now());
  }

  List<DateTime> _getWeekDays(DateTime date) {
    final weekday = date.weekday;
    final monday = date.subtract(Duration(days: weekday - 1));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getMonthYear(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected ? AppTheme.white : AppTheme.black,
                  ),
                ),
              ),
            ),
            if (isToday && !isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.black,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
