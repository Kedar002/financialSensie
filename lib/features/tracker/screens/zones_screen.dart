import 'package:flutter/material.dart';
import '../core/models/geofence.dart';
import '../core/repositories/geofence_repository.dart';
import '../widgets/glass_card.dart';
import 'add_zone_screen.dart';

class ZonesScreen extends StatefulWidget {
  const ZonesScreen({super.key});

  @override
  State<ZonesScreen> createState() => _ZonesScreenState();
}

class _ZonesScreenState extends State<ZonesScreen> {
  final GeofenceRepository _repo = GeofenceRepository();
  List<Geofence> _zones = [];

  @override
  void initState() {
    super.initState();
    _loadZones();
  }

  Future<void> _loadZones() async {
    final zones = await _repo.getAll();
    if (mounted) setState(() => _zones = zones);
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

  Future<void> _deleteZone(int id) async {
    await _repo.delete(id);
    await _loadZones();
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
              if (_zones.length < 3)
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
            'Get notified when the device enters or exits an area.',
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
                          'Tap Add to create a geofence zone.',
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
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    '${zone.radiusMeters.toStringAsFixed(0)}m radius',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (zone.id != null) _deleteZone(zone.id!);
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFFCCCCCC),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Text(
            '${_zones.length}/3 zones used',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
        ),
      ],
    );
  }
}
