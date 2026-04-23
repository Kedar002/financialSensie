import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/geofence.dart';
import '../core/models/zone_settings.dart';
import '../core/repositories/geofence_repository.dart';
import '../core/repositories/visit_repository.dart';
import '../core/repositories/zone_settings_repository.dart';
import '../core/services/visit_firebase_service.dart';

class AddZoneScreen extends StatefulWidget {
  final Geofence? existing;
  final ZoneSettings? existingSettings;

  const AddZoneScreen({super.key, this.existing, this.existingSettings});

  @override
  State<AddZoneScreen> createState() => _AddZoneScreenState();
}

class _AddZoneScreenState extends State<AddZoneScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _coordsController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _minStayController = TextEditingController();
  final GeofenceRepository _geoRepo = GeofenceRepository();
  final ZoneSettingsRepository _settingsRepo = ZoneSettingsRepository();
  final VisitRepository _visitRepo = VisitRepository();
  final VisitFirebaseService _visitFirebase = VisitFirebaseService();

  LatLng? _center;
  double _radius = 200;
  bool _alertOnEnter = true;
  bool _alertOnExit = true;
  bool _suppressWhileInside = false;
  bool _alertOnlyOnExit = false;
  String _intervalUnit = 'min';
  String _minStayUnit = 'min';
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final g = widget.existing!;
      _nameController.text = g.name;
      _center = g.center;
      _radius = g.radiusMeters;
      _alertOnEnter = g.notifyOnEnter;
      _alertOnExit = g.notifyOnExit;
      _coordsController.text =
          '${g.center.latitude.toStringAsFixed(6)}, ${g.center.longitude.toStringAsFixed(6)}';
    }
    if (widget.existingSettings != null) {
      final s = widget.existingSettings!;
      _alertOnEnter = s.alertOnEnter;
      _alertOnExit = s.alertOnExit;
      _suppressWhileInside = s.suppressWhileInside;
      _alertOnlyOnExit = s.alertOnlyOnExit;
      if (s.updateIntervalMinutes > 0) {
        if (s.updateIntervalMinutes >= 60 &&
            s.updateIntervalMinutes % 60 == 0) {
          _intervalController.text =
              (s.updateIntervalMinutes ~/ 60).toString();
          _intervalUnit = 'hr';
        } else {
          _intervalController.text = s.updateIntervalMinutes.toString();
          _intervalUnit = 'min';
        }
      }
      if (s.minimumStayMinutes > 0) {
        if (s.minimumStayMinutes >= 60 && s.minimumStayMinutes % 60 == 0) {
          _minStayController.text =
              (s.minimumStayMinutes ~/ 60).toString();
          _minStayUnit = 'hr';
        } else {
          _minStayController.text = s.minimumStayMinutes.toString();
          _minStayUnit = 'min';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _coordsController.dispose();
    _intervalController.dispose();
    _minStayController.dispose();
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
    final parts = cleaned.split(RegExp(r'[,\s]+'));
    if (parts.length < 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }

  int _parseInterval() {
    final value = int.tryParse(_intervalController.text.trim()) ?? 0;
    if (value <= 0) return 0;
    return _intervalUnit == 'hr' ? value * 60 : value;
  }

  int _parseMinStay() {
    final value = int.tryParse(_minStayController.text.trim()) ?? 0;
    if (value <= 0) return 0;
    return _minStayUnit == 'hr' ? value * 60 : value;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _center == null) return;

    setState(() => _saving = true);

    try {
      final geofence = Geofence(
        id: widget.existing?.id,
        name: name,
        center: _center!,
        radiusMeters: _radius,
        notifyOnEnter: _alertOnEnter,
        notifyOnExit: _alertOnExit,
      );

      int geofenceId;
      if (_isEditing && widget.existing?.id != null) {
        // Update in place — keep the same row id so Firebase doc id stays stable
        // and no brief window exists where the zone is missing.
        await _geoRepo.update(geofence);
        geofenceId = widget.existing!.id!;
      } else {
        geofenceId = await _geoRepo.insert(geofence);
      }

      final settings = ZoneSettings(
        geofenceId: geofenceId,
        zoneName: name,
        alertOnEnter: _alertOnEnter,
        alertOnExit: _alertOnExit,
        minimumStayMinutes: _parseMinStay(),
        suppressWhileInside: _suppressWhileInside,
        alertOnlyOnExit: _alertOnlyOnExit,
        updateIntervalMinutes: _parseInterval(),
      );
      await _settingsRepo.upsertByGeofenceId(settings);

      // Retroactively apply the (possibly new) name to past visit rows so
      // history no longer shows "Unknown" or the auto-generated placeholder
      // after the user names a zone. Covers both the rename flow (matching
      // zone_id) and the first-time-name flow (unknown visits inside radius).
      await _visitRepo.renameZone(geofenceId, name);
      await _visitRepo.linkVisitsInRadius(
        geofenceId: geofenceId,
        name: name,
        latitude: _center!.latitude,
        longitude: _center!.longitude,
        radiusMeters: _radius,
      );

      // Sync to Firebase for tracker to pick up
      try {
        final prefs = await SharedPreferences.getInstance();
        final deviceId = prefs.getString('tracker_paired_device_id') ?? '';
        if (deviceId.isNotEmpty) {
          await _visitFirebase.saveGeofence(
              deviceId, geofence.copyWith(id: geofenceId));
          await _visitFirebase.saveZoneSettings(
              deviceId, geofenceId, settings);
          // History reads from Firestore, so the UI update hinges on these.
          await _visitFirebase.renameZoneInVisits(
              deviceId, geofenceId, name);
          await _visitFirebase.linkUnknownVisitsInRadius(
            deviceId: deviceId,
            geofenceId: geofenceId,
            name: name,
            latitude: _center!.latitude,
            longitude: _center!.longitude,
            radiusMeters: _radius,
          );
        }
      } catch (_) {}

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save zone: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                  Text(
                    _isEditing ? 'Edit Zone' : 'Add Zone',
                    style: const TextStyle(
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onSubmitted: _applyCoordinates,
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          _applyCoordinates(_coordsController.text),
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.3,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _center ?? const LatLng(20.5937, 78.9629),
                      initialZoom: _center != null ? 16 : 15,
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
                              borderColor:
                                  Colors.black.withValues(alpha: 0.3),
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

            // Settings
            Expanded(
              child: SingleChildScrollView(
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
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _radius,
                        min: 50,
                        max: 1000,
                        onChanged: (v) => setState(() => _radius = v),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Alert toggles
                    const Text(
                      'Alerts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MiniToggle(
                      label: 'Alert on enter',
                      value: _alertOnEnter,
                      onChanged: (v) => setState(() => _alertOnEnter = v),
                    ),
                    const SizedBox(height: 8),
                    _MiniToggle(
                      label: 'Alert on exit',
                      value: _alertOnExit,
                      onChanged: (v) => setState(() => _alertOnExit = v),
                    ),
                    const SizedBox(height: 8),
                    _MiniToggle(
                      label: 'Alert only on exit',
                      value: _alertOnlyOnExit,
                      onChanged: (v) =>
                          setState(() => _alertOnlyOnExit = v),
                    ),
                    const SizedBox(height: 8),
                    _MiniToggle(
                      label: 'Suppress updates inside',
                      value: _suppressWhileInside,
                      onChanged: (v) =>
                          setState(() => _suppressWhileInside = v),
                    ),
                    const SizedBox(height: 20),

                    // Minimum stay
                    const Text(
                      'Minimum Stay Alert',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _NumberWithUnit(
                      controller: _minStayController,
                      unit: _minStayUnit,
                      hint: 'Off',
                      onUnitChanged: (u) =>
                          setState(() => _minStayUnit = u),
                    ),
                    const SizedBox(height: 20),

                    // Update interval
                    const Text(
                      'Update Interval',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF888888),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'How often to check GPS while in this zone. Leave empty for smart default.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFAAAAAA),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _NumberWithUnit(
                      controller: _intervalController,
                      unit: _intervalUnit,
                      hint: 'Default',
                      onUnitChanged: (u) =>
                          setState(() => _intervalUnit = u),
                    ),
                    const SizedBox(height: 24),

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
                            : Text(
                                _isEditing ? 'Save Changes' : 'Save Zone',
                                style: const TextStyle(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.black87,
            ),
          ),
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

class _NumberWithUnit extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final String hint;
  final ValueChanged<String> onUnitChanged;

  const _NumberWithUnit({
    required this.controller,
    required this.unit,
    required this.hint,
    required this.onUnitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFFCCCCCC),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onUnitChanged(unit == 'min' ? 'hr' : 'min'),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEEEEEE)),
            ),
            alignment: Alignment.center,
            child: Text(
              unit == 'min' ? 'min' : 'hr',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
