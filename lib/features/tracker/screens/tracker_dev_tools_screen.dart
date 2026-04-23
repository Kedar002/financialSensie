import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_service.dart';
import '../core/models/geofence.dart';
import '../core/models/visit.dart';
import '../core/repositories/geofence_repository.dart';
import '../core/repositories/visit_repository.dart';
import 'package:latlong2/latlong.dart';

/// Developer-only harness for verifying tracker bug fixes without needing to
/// physically walk around. Only visible in debug builds.
///
/// What each button verifies:
///   1. "Simulate unknown-location visit" → inserts a Visit with
///      zone_name='Unknown' so the history row shows immediately.
///      This verifies the Bug 1 fix (unknown zone placeholder on arrival).
///
///   2. "Queue 5 offline locations" → seeds offline_location_queue so the
///      drain loop can be observed. Toggle airplane mode while watching the
///      queue count drop. Verifies Bug 2 (periodic sync + connectivity drain).
///
///   3. "Show zone diagnostics" → lists every local zone with its id so the
///      user can spot duplicates or missing ones at a glance. Verifies Bug 3
///      after a round of create / edit / delete.
class TrackerDevToolsScreen extends StatefulWidget {
  const TrackerDevToolsScreen({super.key});

  @override
  State<TrackerDevToolsScreen> createState() => _TrackerDevToolsScreenState();
}

class _TrackerDevToolsScreenState extends State<TrackerDevToolsScreen> {
  final _visitRepo = VisitRepository();
  final _geoRepo = GeofenceRepository();
  final _dbService = DatabaseService();

  int _queueCount = 0;
  int _visitCount = 0;
  int _zoneCount = 0;
  List<Geofence> _zones = [];
  List<Visit> _recentVisits = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final db = await _dbService.database;
    final queue = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM offline_location_queue')) ??
        0;
    final visits = await _visitRepo.getRecent(limit: 10);
    final zones = await _geoRepo.getAll();
    if (!mounted) return;
    setState(() {
      _queueCount = queue;
      _visitCount = visits.length;
      _recentVisits = visits;
      _zones = zones;
      _zoneCount = zones.length;
    });
  }

  Future<void> _simulateUnknownVisit() async {
    // Insert a completed visit at a jittered lat/lng so it's clearly a
    // different spot each time. arrival 10 min ago, 7-min duration.
    final now = DateTime.now();
    final arrival = now.subtract(const Duration(minutes: 10));
    final departure = now.subtract(const Duration(minutes: 3));
    final jitterLat = 18.5 + (now.millisecond / 10000);
    final jitterLng = 73.8 + (now.millisecond / 10000);
    await _visitRepo.insert(Visit(
      latitude: jitterLat,
      longitude: jitterLng,
      arrivalTime: arrival,
      departureTime: departure,
      durationMinutes: 7,
      zoneName: 'Unknown',
      batteryOnArrival: 80,
      batteryOnDeparture: 79,
    ));
    await _refresh();
    _toast('Inserted unknown-location visit — check History');
  }

  Future<void> _queueOfflineLocations() async {
    final db = await _dbService.database;
    final now = DateTime.now();
    for (int i = 0; i < 5; i++) {
      await db.insert('offline_location_queue', {
        'latitude': 18.5 + i * 0.0001,
        'longitude': 73.8 + i * 0.0001,
        'accuracy': 10.0,
        'speed': 0.5,
        'heading': 0.0,
        'battery_level': 80,
        'is_charging': 0,
        'timestamp':
            now.subtract(Duration(seconds: 30 * (5 - i))).toIso8601String(),
        'created_at': now.toIso8601String(),
      });
    }
    await _refresh();
    _toast(
        'Queued 5 offline points. Wait up to 60s (online) for drain.');
  }

  Future<void> _clearQueue() async {
    final db = await _dbService.database;
    await db.delete('offline_location_queue');
    await _refresh();
    _toast('Offline queue cleared');
  }

  Future<void> _dumpZones() async {
    await _refresh();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Zone diagnostics',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: _zones.isEmpty
              ? const Text('No zones.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _zones.length,
                  itemBuilder: (_, i) {
                    final z = _zones[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'id=${z.id}  ${z.name}\n'
                        '  ${z.center.latitude.toStringAsFixed(4)}, '
                        '${z.center.longitude.toStringAsFixed(4)}  '
                        '${z.radiusMeters.toStringAsFixed(0)}m',
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _seedTestZone() async {
    final now = DateTime.now();
    await _geoRepo.insert(Geofence(
      name: 'Test ${now.second}',
      center: LatLng(18.5 + now.millisecond / 100000,
          73.8 + now.millisecond / 100000),
      radiusMeters: 100,
    ));
    await _refresh();
    _toast('Seeded one test zone');
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text('Dev tools are debug-only.')),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Dev Tools',
            style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _StatRow(label: 'Offline queue', value: '$_queueCount'),
          _StatRow(label: 'Recent visits', value: '$_visitCount'),
          _StatRow(label: 'Zones', value: '$_zoneCount'),
          const SizedBox(height: 24),
          const _Heading('Bug 1 · Unknown zone visit'),
          _ActionButton(
              label: 'Simulate unknown-location visit',
              onTap: _simulateUnknownVisit),
          const SizedBox(height: 24),
          const _Heading('Bug 2 · Offline sync'),
          _ActionButton(
              label: 'Queue 5 offline points', onTap: _queueOfflineLocations),
          const SizedBox(height: 8),
          _ActionButton(label: 'Clear queue', onTap: _clearQueue, outlined: true),
          const SizedBox(height: 8),
          const Text(
            'Turn airplane mode ON before queuing to test the drain when '
            'network comes back. Otherwise the drain loop will sync within '
            '60 seconds.',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 24),
          const _Heading('Bug 3 · Zone duplicates'),
          _ActionButton(label: 'Seed one test zone', onTap: _seedTestZone),
          const SizedBox(height: 8),
          _ActionButton(
              label: 'Show zone diagnostics',
              onTap: _dumpZones,
              outlined: true),
          const SizedBox(height: 8),
          const Text(
            'Create, edit, then delete a zone from the Zones tab. Open the '
            'diagnostics above to confirm no duplicates and ids stay stable.',
            style: TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
                fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 24),
          _ActionButton(label: 'Refresh stats', onTap: _refresh, outlined: true),
          if (_recentVisits.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _Heading('Recent visits'),
            ..._recentVisits.map((v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${v.zoneName ?? "(null)"}  ·  '
                    '${v.arrivalTime.hour.toString().padLeft(2, '0')}:'
                    '${v.arrivalTime.minute.toString().padLeft(2, '0')}  ·  '
                    '${v.durationMinutes ?? "active"}m',
                    style: const TextStyle(
                        fontSize: 12, fontFamily: 'monospace'),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF888888),
                letterSpacing: 0.5)),
      );
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF888888),
                        fontWeight: FontWeight.w400))),
            Text(value,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black)),
          ],
        ),
      );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _ActionButton(
      {required this.label, required this.onTap, this.outlined = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.white : Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: outlined ? Colors.black : Colors.white)),
        ),
      );
}
