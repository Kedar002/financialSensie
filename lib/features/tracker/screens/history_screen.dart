import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/geofence.dart';
import '../core/models/visit.dart';
import '../core/services/visit_firebase_service.dart';
import 'transit_detail_screen.dart';
import 'visit_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final VisitFirebaseService _visitService = VisitFirebaseService();
  String? _deviceId;
  StreamSubscription? _visitsSub;
  StreamSubscription? _activeSub;
  StreamSubscription? _zonesSub;
  List<Visit> _completedVisits = [];
  Visit? _activeVisit;
  Map<int, String> _zoneNames = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('tracker_paired_device_id');
    if (_deviceId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Listen for completed visits
    _visitsSub = _visitService.visitsStream(_deviceId!, limit: 100).listen(
      (visits) {
        if (mounted) setState(() {
          _completedVisits = visits;
          _loading = false;
          _error = null;
        });
      },
      onError: (e) {
        if (mounted) setState(() {
          _loading = false;
          _error = 'Could not load visits: $e';
        });
      },
    );

    // Listen for active visit (currently at a location)
    _activeSub = _visitService.activeVisitStream(_deviceId!).listen(
      (visit) {
        if (mounted) setState(() => _activeVisit = visit);
      },
      onError: (_) {},
    );

    // Listen for zone definitions — names here are the source of truth
    // so renames reflect in history without rewriting visit records.
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
  }

  /// Merge active visit (if any) with completed visits.
  List<Visit> get _visits {
    if (_activeVisit == null) return _completedVisits;
    return [_activeVisit!, ..._completedVisits];
  }

  Future<void> _refresh() async {
    _visitsSub?.cancel();
    _activeSub?.cancel();
    _zonesSub?.cancel();
    setState(() {
      _error = null;
    });
    await _init();
  }

  @override
  void dispose() {
    _visitsSub?.cancel();
    _activeSub?.cancel();
    _zonesSub?.cancel();
    super.dispose();
  }

  Widget _scrollableEmpty({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: subtitle != null ? 17 : 14,
                      fontWeight:
                          subtitle != null ? FontWeight.w500 : FontWeight.w400,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d, y').format(time);
  }

  String _formatDuration(Visit visit) {
    final dur = visit.duration;
    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes % 60}m';
    }
    return '${dur.inMinutes}m';
  }

  Map<String, List<Visit>> _groupByDay(List<Visit> visits) {
    final grouped = <String, List<Visit>>{};
    for (final v in visits) {
      final key = _formatDate(v.arrivalTime);
      grouped.putIfAbsent(key, () => []).add(v);
    }
    // Sort each day's visits by arrival time ascending
    for (final list in grouped.values) {
      list.sort((a, b) => a.arrivalTime.compareTo(b.arrivalTime));
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'History',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Places visited and time spent.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: Colors.black,
            backgroundColor: Colors.white,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
      );
    }

    if (_deviceId == null) {
      return _scrollableEmpty(
        icon: Icons.link_off,
        title: 'No device paired',
      );
    }

    if (_error != null) {
      return _scrollableEmpty(
        icon: Icons.error_outline,
        title: _error!,
      );
    }

    if (_visits.isEmpty) {
      return _scrollableEmpty(
        icon: Icons.history,
        title: 'No visits yet',
        subtitle: 'Visits will appear here when the tracker stays\nat a location for 3+ minutes, then leaves.',
      );
    }

    final grouped = _groupByDay(_visits);
    final days = grouped.keys.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: days.length,
      itemBuilder: (context, dayIndex) {
        final dayLabel = days[dayIndex];
        final dayVisits = grouped[dayLabel]!;

        // Day summary
        final totalMinutes = dayVisits.fold<int>(
          0,
          (sum, v) => sum + v.duration.inMinutes,
        );
        final summary =
            '${dayVisits.length} ${dayVisits.length == 1 ? 'place' : 'places'}';
        final durationSummary = totalMinutes >= 60
            ? '${totalMinutes ~/ 60}h ${totalMinutes % 60}m'
            : '${totalMinutes}m';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dayIndex > 0) const SizedBox(height: 24),
            // Day header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dayLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF888888),
                  ),
                ),
                Text(
                  '$summary · $durationSummary',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Visit items with transit gaps
            ...List.generate(dayVisits.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Transit gap
                final prev = dayVisits[i ~/ 2];
                final next = dayVisits[i ~/ 2 + 1];
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

              final visit = dayVisits[i ~/ 2];
              final currentName =
                  visit.zoneId != null ? _zoneNames[visit.zoneId!] : null;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisitDetailScreen(
                      visit: visit,
                      resolvedZoneName: currentName,
                    ),
                  ),
                ),
                child: _VisitItem(
                  visit: visit,
                  resolvedZoneName: currentName,
                  arrivalTime: _formatTime(visit.arrivalTime),
                  departureTime: visit.departureTime != null
                      ? _formatTime(visit.departureTime!)
                      : 'Now',
                  duration: _formatDuration(visit),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _VisitItem extends StatelessWidget {
  final Visit visit;
  final String? resolvedZoneName;
  final String arrivalTime;
  final String departureTime;
  final String duration;

  const _VisitItem({
    required this.visit,
    required this.resolvedZoneName,
    required this.arrivalTime,
    required this.departureTime,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    final label = resolvedZoneName ??
        visit.zoneName ??
        '${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}';

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
              color: visit.isActive ? const Color(0xFF4CAF50) : Colors.black,
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
                  '$arrivalTime → $departureTime',
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
            duration,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
