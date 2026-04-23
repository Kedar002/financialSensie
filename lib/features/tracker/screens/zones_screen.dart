import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/geofence.dart';
import '../core/models/zone_settings.dart';
import '../core/repositories/geofence_repository.dart';
import '../core/repositories/zone_settings_repository.dart';
import '../core/services/visit_firebase_service.dart';
import 'add_zone_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final GeofenceRepository _geoRepo = GeofenceRepository();
  final ZoneSettingsRepository _settingsRepo = ZoneSettingsRepository();
  final VisitFirebaseService _visitFirebase = VisitFirebaseService();
  List<Geofence> _zones = [];
  Map<int, ZoneSettings> _settingsMap = {};

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final zones = await _geoRepo.getAll();
    final allSettings = await _settingsRepo.getAll();
    final map = <int, ZoneSettings>{};
    for (final s in allSettings) {
      map[s.geofenceId] = s;
    }
    if (mounted) {
      setState(() {
        _zones = zones;
        _settingsMap = map;
      });
    }
  }

  Future<void> _addZone() async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AddZoneScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (result == true) _loadZones();
  }

  Future<void> _editZone(Geofence zone) async {
    final settings = _settingsMap[zone.id];
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddZoneScreen(existing: zone, existingSettings: settings),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
    if (result == true) _loadZones();
  }

  Future<void> _deleteZone(int id) async {
    await _geoRepo.delete(id);
    await _settingsRepo.delete(id);
    // Also remove from Firebase
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = prefs.getString('tracker_paired_device_id') ?? '';
      if (deviceId.isNotEmpty) {
        await _visitFirebase.deleteGeofence(deviceId, id);
        await _visitFirebase.deleteZoneSettings(deviceId, id);
      }
    } catch (_) {}
    await _loadZones();
  }

  String _settingsSummary(ZoneSettings? s) {
    if (s == null) return 'Default settings';
    final parts = <String>[];
    if (s.alertOnlyOnExit) {
      parts.add('Alert on exit only');
    } else {
      if (s.alertOnEnter) parts.add('Enter');
      if (s.alertOnExit) parts.add('Exit');
    }
    if (s.suppressWhileInside) parts.add('Suppressed');
    if (s.updateIntervalMinutes > 0) {
      if (s.updateIntervalMinutes >= 60) {
        parts.add('Every ${s.updateIntervalMinutes ~/ 60}h');
      } else {
        parts.add('Every ${s.updateIntervalMinutes}m');
      }
    }
    if (s.minimumStayMinutes > 0) {
      if (s.minimumStayMinutes >= 60) {
        parts.add('Min ${s.minimumStayMinutes ~/ 60}h stay');
      } else {
        parts.add('Min ${s.minimumStayMinutes}m stay');
      }
    }
    return parts.isEmpty ? 'Default settings' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Zones',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: _addZone,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Manage zones and customize per-zone settings.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _zones.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar_outlined,
                          size: 48,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No zones yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap Add to create a zone.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _zones.length,
                  itemBuilder: (context, index) {
                    final zone = _zones[index];
                    final settings = _settingsMap[zone.id];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _editZone(zone),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAFAFA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.circle_outlined,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      zone.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${zone.radiusMeters.toStringAsFixed(0)}m · ${_settingsSummary(settings)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF888888),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (zone.id != null) _deleteZone(zone.id!);
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Color(0xFFCCCCCC),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
