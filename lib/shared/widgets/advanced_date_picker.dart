import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Selection mode for the date picker.
enum DateSelectionMode {
  single,
  multiple,
  range,
}

/// Advanced date picker with multiple selection modes.
/// Single date, multiple dates, date range, month/year navigation.
/// Clean, minimal. Steve Jobs approved.
class AdvancedDatePicker extends StatefulWidget {
  final DateSelectionMode mode;
  final DateTime? selectedDate;
  final List<DateTime> selectedDates;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final Function(DateTime)? onDateSelected;
  final Function(List<DateTime>)? onMultipleDatesSelected;
  final Function(DateTime?, DateTime?)? onRangeSelected;
  final VoidCallback? onClear;

  const AdvancedDatePicker({
    super.key,
    this.mode = DateSelectionMode.single,
    this.selectedDate,
    this.selectedDates = const [],
    this.rangeStart,
    this.rangeEnd,
    this.onDateSelected,
    this.onMultipleDatesSelected,
    this.onRangeSelected,
    this.onClear,
  });

  @override
  State<AdvancedDatePicker> createState() => _AdvancedDatePickerState();
}

class _AdvancedDatePickerState extends State<AdvancedDatePicker> {
  late DateTime _viewingMonth;
  late DateSelectionMode _mode;
  late List<DateTime> _selectedDates;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    _viewingMonth = widget.selectedDate ?? DateTime.now();
    _selectedDates = List.from(widget.selectedDates);
    _rangeStart = widget.rangeStart;
    _rangeEnd = widget.rangeEnd;

    if (widget.selectedDate != null && _mode == DateSelectionMode.single) {
      _selectedDates = [widget.selectedDate!];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildModeSelector(),
        const SizedBox(height: AppTheme.spacing16),
        _buildMonthYearSelector(),
        const SizedBox(height: AppTheme.spacing16),
        _buildWeekdayHeaders(),
        const SizedBox(height: AppTheme.spacing8),
        _buildCalendarGrid(),
        const SizedBox(height: AppTheme.spacing16),
        _buildSelectionSummary(),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _buildModeChip('Single', DateSelectionMode.single),
        const SizedBox(width: AppTheme.spacing8),
        _buildModeChip('Multiple', DateSelectionMode.multiple),
        const SizedBox(width: AppTheme.spacing8),
        _buildModeChip('Range', DateSelectionMode.range),
        const Spacer(),
        if (_selectedDates.isNotEmpty || _rangeStart != null)
          GestureDetector(
            onTap: _clearSelection,
            child: Text(
              'Clear',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildModeChip(String label, DateSelectionMode mode) {
    final isSelected = _mode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mode = mode;
          _clearSelection();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.black : AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppTheme.white : AppTheme.gray600,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _previousMonth,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.gray600,
              size: 24,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showMonthYearPicker,
          child: Row(
            children: [
              Text(
                _formatMonth(_viewingMonth),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: AppTheme.spacing4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppTheme.gray600,
                size: 20,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _canGoNext ? _nextMonth : null,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            child: Icon(
              Icons.chevron_right,
              color: _canGoNext ? AppTheme.gray600 : AppTheme.gray300,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: weekdays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_viewingMonth.year, _viewingMonth.month, 1);
    final lastDayOfMonth = DateTime(_viewingMonth.year, _viewingMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final cells = <Widget>[];

    // Empty cells for days before the first of the month
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_viewingMonth.year, _viewingMonth.month, day);
      cells.add(_buildDayCell(date));
    }

    // Build rows of 7
    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      final rowCells = cells.sublist(i, (i + 7).clamp(0, cells.length));
      while (rowCells.length < 7) {
        rowCells.add(const SizedBox());
      }
      rows.add(
        Row(
          children: rowCells.map((cell) => Expanded(child: cell)).toList(),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildDayCell(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final isToday = dateOnly == today;
    final isFuture = dateOnly.isAfter(today);
    final isSelected = _isDateSelected(date);
    final isInRange = _isDateInRange(date);
    final isRangeStart = _rangeStart != null && _isSameDay(_rangeStart!, date);
    final isRangeEnd = _rangeEnd != null && _isSameDay(_rangeEnd!, date);

    return GestureDetector(
      onTap: isFuture ? null : () => _onDayTapped(date),
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.black
              : isInRange
                  ? AppTheme.gray200
                  : null,
          borderRadius: _mode == DateSelectionMode.range
              ? BorderRadius.horizontal(
                  left: isRangeStart || !isInRange
                      ? const Radius.circular(20)
                      : Radius.zero,
                  right: isRangeEnd || !isInRange
                      ? const Radius.circular(20)
                      : Radius.zero,
                )
              : BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isFuture
                      ? AppTheme.gray300
                      : isSelected
                          ? AppTheme.white
                          : AppTheme.black,
                ),
              ),
              if (isToday && !isSelected)
                Container(
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
      ),
    );
  }

  Widget _buildSelectionSummary() {
    String summary;

    if (_mode == DateSelectionMode.single && _selectedDates.isNotEmpty) {
      summary = _formatFullDate(_selectedDates.first);
    } else if (_mode == DateSelectionMode.multiple && _selectedDates.isNotEmpty) {
      summary = '${_selectedDates.length} date${_selectedDates.length > 1 ? 's' : ''} selected';
    } else if (_mode == DateSelectionMode.range) {
      if (_rangeStart != null && _rangeEnd != null) {
        summary = '${_formatShortDate(_rangeStart!)} - ${_formatShortDate(_rangeEnd!)}';
      } else if (_rangeStart != null) {
        summary = 'From ${_formatShortDate(_rangeStart!)}';
      } else {
        summary = 'Select start date';
      }
    } else {
      summary = 'No dates selected';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        summary,
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }

  bool _isDateSelected(DateTime date) {
    if (_mode == DateSelectionMode.range) {
      return (_rangeStart != null && _isSameDay(_rangeStart!, date)) ||
          (_rangeEnd != null && _isSameDay(_rangeEnd!, date));
    }
    return _selectedDates.any((d) => _isSameDay(d, date));
  }

  bool _isDateInRange(DateTime date) {
    if (_mode != DateSelectionMode.range) return false;
    if (_rangeStart == null || _rangeEnd == null) return false;

    final dateOnly = DateTime(date.year, date.month, date.day);
    final start = DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    final end = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);

    return dateOnly.isAfter(start) && dateOnly.isBefore(end);
  }

  void _onDayTapped(DateTime date) {
    setState(() {
      switch (_mode) {
        case DateSelectionMode.single:
          _selectedDates = [date];
          widget.onDateSelected?.call(date);
          break;

        case DateSelectionMode.multiple:
          final existing = _selectedDates.indexWhere((d) => _isSameDay(d, date));
          if (existing >= 0) {
            _selectedDates.removeAt(existing);
          } else {
            _selectedDates.add(date);
          }
          widget.onMultipleDatesSelected?.call(_selectedDates);
          break;

        case DateSelectionMode.range:
          if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
            // Start new range
            _rangeStart = date;
            _rangeEnd = null;
          } else {
            // Complete range
            if (date.isBefore(_rangeStart!)) {
              _rangeEnd = _rangeStart;
              _rangeStart = date;
            } else {
              _rangeEnd = date;
            }
          }
          widget.onRangeSelected?.call(_rangeStart, _rangeEnd);
          break;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedDates.clear();
      _rangeStart = null;
      _rangeEnd = null;
    });
    widget.onClear?.call();
  }

  void _previousMonth() {
    setState(() {
      _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month - 1);
    });
  }

  void _nextMonth() {
    if (_canGoNext) {
      setState(() {
        _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month + 1);
      });
    }
  }

  bool get _canGoNext {
    final now = DateTime.now();
    return _viewingMonth.year < now.year ||
        (_viewingMonth.year == now.year && _viewingMonth.month < now.month);
  }

  void _showMonthYearPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _MonthYearPicker(
        selectedDate: _viewingMonth,
        onSelected: (date) {
          setState(() {
            _viewingMonth = date;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatShortDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Month and year picker sheet.
class _MonthYearPicker extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onSelected;

  const _MonthYearPicker({
    required this.selectedDate,
    required this.onSelected,
  });

  @override
  State<_MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<_MonthYearPicker> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedDate.year;
    _selectedMonth = widget.selectedDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(10, (i) => now.year - i);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Month & Year',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing24),
            // Year selector
            Text(
              'Year',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: years.map((year) {
                final isSelected = year == _selectedYear;
                return GestureDetector(
                  onTap: () => setState(() => _selectedYear = year),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.black : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Text(
                      '$year',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppTheme.white : AppTheme.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacing24),
            // Month selector
            Text(
              'Month',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Wrap(
              spacing: AppTheme.spacing8,
              runSpacing: AppTheme.spacing8,
              children: List.generate(12, (i) {
                final month = i + 1;
                final isSelected = month == _selectedMonth;
                final isFuture = _selectedYear == now.year && month > now.month;

                return GestureDetector(
                  onTap: isFuture ? null : () => setState(() => _selectedMonth = month),
                  child: Container(
                    width: 70,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacing8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.black : AppTheme.gray100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Center(
                      child: Text(
                        _getMonthShort(month),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isFuture
                              ? AppTheme.gray300
                              : isSelected
                                  ? AppTheme.white
                                  : AppTheme.black,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppTheme.spacing24),
            // Done button
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  widget.onSelected(DateTime(_selectedYear, _selectedMonth));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.black,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Center(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.white,
                      ),
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

  String _getMonthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
