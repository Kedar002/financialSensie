import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/models/geofence.dart';
import '../core/repositories/geofence_repository.dart';

class AddZoneScreen extends StatefulWidget {
  const AddZoneScreen({super.key});

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _coordsController = TextEditingController();
  final GeofenceRepository _repo = GeofenceRepository();
  LatLng? _center;
  double _radius = 200;
  bool _notifyOnEnter = true;
  bool _notifyOnExit = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _coordsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _applyCoordinates(String text) {
    final parsed = _parseCoords(text);
    if (parsed != null) {
      setState(() => _center = parsed);
      _mapController.move(parsed, 16);
    }
  }

  LatLng? _parseCoords(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;

    // Support formats: "lat,long" or "lat, long" or "lat long"
    final parts = cleaned.split(RegExp(r'[,\s]+'));
    if (parts.length < 2) return null;

    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;

    return LatLng(lat, lng);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _center == null) return;

    setState(() => _saving = true);

    await _repo.insert(Geofence(
      name: name,
      center: _center!,
      radiusMeters: _radius,
      notifyOnEnter: _notifyOnEnter,
      notifyOnExit: _notifyOnExit,
    ));

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Add Zone',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Coordinates input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _coordsController,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Paste coordinates (lat, long)',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFCCCCCC),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onSubmitted: _applyCoordinates,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _applyCoordinates(_coordsController.text),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Map
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(20.5937, 78.9629),
                      initialZoom: 15,
                      onTap: (tapPosition, point) {
                        setState(() => _center = point);
                        _coordsController.text =
                            '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.financesensei',
                      ),
                      if (_center != null)
                        CircleLayer(
                          circles: [
                            CircleMarker(
                              point: _center!,
                              radius: _radius,
                              useRadiusInMeter: true,
                              color: Colors.black.withValues(alpha: 0.08),
                              borderColor: Colors.black.withValues(alpha: 0.3),
                              borderStrokeWidth: 1.5,
                            ),
                          ],
                        ),
                      if (_center != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _center!,
                              width: 14,
                              height: 14,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black,
                                  border: Border.all(
                                      color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (_center == null)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: const Color(0xFFEEEEEE)),
                          ),
                          child: const Text(
                            'Tap map or paste coordinates above',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom controls
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Zone name',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFCCCCCC),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // Radius slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Radius',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF888888),
                        ),
                      ),
                      Text(
                        '${_radius.toStringAsFixed(0)}m',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: const Color(0xFFEEEEEE),
                      thumbColor: Colors.black,
                      overlayColor: Colors.black.withValues(alpha: 0.08),
                      trackHeight: 2,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: _radius,
                      min: 50,
                      max: 1000,
                      onChanged: (v) => setState(() => _radius = v),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Notify toggles
                  Row(
                    children: [
                      _MiniToggle(
                        label: 'Enter',
                        value: _notifyOnEnter,
                        onChanged: (v) =>
                            setState(() => _notifyOnEnter = v),
                      ),
                      const SizedBox(width: 24),
                      _MiniToggle(
                        label: 'Exit',
                        value: _notifyOnExit,
                        onChanged: (v) =>
                            setState(() => _notifyOnExit = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  GestureDetector(
                    onTap: (_center != null &&
                            _nameController.text.trim().isNotEmpty &&
                            !_saving)
                        ? _save
                        : null,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: (_center != null &&
                                _nameController.text.trim().isNotEmpty)
                            ? Colors.black
                            : const Color(0xFFE0E0E0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Zone',
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
          ],
        ),
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 22,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              color: value ? Colors.black : const Color(0xFFE0E0E0),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
