import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/geofence.dart';
import '../core/models/visit.dart';
import '../core/services/visit_firebase_service.dart';
import 'transit_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final VisitFirebaseService _visitService = VisitFirebaseService();
  String? _deviceId;
  StreamSubscription? _zonesSub;
  Map<int, String> _zoneNames = {};

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final Set<DateTime> _daysWithVisits = {};
  List<Visit> _selectedDayVisits = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _zonesSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('tracker_paired_device_id');
    if (_deviceId != null) {
      _zonesSub = _visitService.geofencesStream(_deviceId!).listen(
        (List<Geofence> zones) {
          final map = <int, String>{};
          for (final z in zones) {
            if (z.id != null) map[z.id!] = z.name;
          }
          if (mounted) setState(() => _zoneNames = map);
        },
        onError: (_) {},
      );
      await _loadMonth();
      await _loadDay(_selectedDay);
    }
  }

  Future<void> _loadMonth() async {
    if (_deviceId == null) return;
    // Load a few key days to populate dots (today, yesterday, etc.)
    // Full month loading would require a range query — for now we populate
    // dots as the user taps days.
    if (mounted) setState(() {});
  }

  Future<void> _loadDay(DateTime day) async {
    if (_deviceId == null) return;
    setState(() => _loading = true);
    final visits = await _visitService.getVisitsByDate(_deviceId!, day);
    if (mounted) {
      setState(() {
        _selectedDayVisits = visits;
        _loading = false;
        if (visits.isNotEmpty) {
          _daysWithVisits.add(DateTime(day.year, day.month, day.day));
        }
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
    _loadMonth();
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDay = day);
    _loadDay(day);
  }

  String _formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  String _formatDuration(Visit visit) {
    final dur = visit.duration;
    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes % 60}m';
    }
    return '${dur.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'Calendar',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _previousMonth,
                child: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: const Icon(Icons.chevron_right, size: 24, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Weekday headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        _buildCalendarGrid(),
        const SizedBox(height: 16),

        // Day detail
        Expanded(child: _buildDayTimeline()),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    // Monday = 1, so offset is (weekday - 1)
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();

    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              if (index < startOffset || index >= startOffset + daysInMonth) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final day = index - startOffset + 1;
              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, day);
              final isSelected = date == _selectedDay;
              final isToday = date == today;
              final hasVisits = _daysWithVisits.contains(date);

              return Expanded(
                child: GestureDetector(
                  onTap: () => _selectDay(date),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.black : Colors.transparent,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? Colors.black
                                    : const Color(0xFF333333),
                          ),
                        ),
                        if (hasVisits && !isSelected)
                          Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildDayTimeline() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      );
    }

    if (_selectedDayVisits.isEmpty) {
      return Center(
        child: Text(
          'No visits on ${DateFormat('MMM d').format(_selectedDay)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
          ),
        ),
      );
    }

    // Summary
    final totalMinutes = _selectedDayVisits.fold<int>(
      0,
      (sum, v) => sum + v.duration.inMinutes,
    );
    final summary =
        '${_selectedDayVisits.length} ${_selectedDayVisits.length == 1 ? 'place' : 'places'}';
    final durationLabel = totalMinutes >= 60
        ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m tracked'
        : '${totalMinutes}m tracked';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Summary bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$summary · $durationLabel',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Timeline items with transit gaps
        ...List.generate(
          _selectedDayVisits.length * 2 - 1,
          (i) {
            if (i.isOdd) {
              final prev = _selectedDayVisits[i ~/ 2];
              final next = _selectedDayVisits[i ~/ 2 + 1];
              if (prev.departureTime != null) {
                final gap =
                    next.arrivalTime.difference(prev.departureTime!);
                if (gap.inMinutes > 0) {
                  final prevName = prev.zoneId != null
                          ? _zoneNames[prev.zoneId!]
                          : null;
                  final nextName = next.zoneId != null
                          ? _zoneNames[next.zoneId!]
                          : null;
                  final fromLabel = prevName ??
                      prev.zoneName ??
                      '${prev.latitude.toStringAsFixed(4)}, ${prev.longitude.toStringAsFixed(4)}';
                  final toLabel = nextName ??
                      next.zoneName ??
                      '${next.latitude.toStringAsFixed(4)}, ${next.longitude.toStringAsFixed(4)}';
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TransitDetailScreen(
                          from: prev,
                          to: next,
                          fromLabel: fromLabel,
                          toLabel: toLabel,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 20,
                            color: const Color(0xFFEEEEEE),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'In transit — ${gap.inMinutes}m',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFFCCCCCC),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFFCCCCCC),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            }

            final visit = _selectedDayVisits[i ~/ 2];
            final currentName =
                visit.zoneId != null ? _zoneNames[visit.zoneId!] : null;
            final label = currentName ??
                visit.zoneName ??
                '${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}';
            final arrival = _formatTime(visit.arrivalTime);
            final departure = visit.departureTime != null
                ? _formatTime(visit.departureTime!)
                : 'Now';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: visit.isActive
                          ? const Color(0xFF4CAF50)
                          : Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$arrival → $departure',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF888888),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDuration(visit),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
