import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/visit.dart';
import '../core/services/visit_firebase_service.dart';

class TransitDetailScreen extends StatefulWidget {
  final Visit from;
  final Visit to;
  final String fromLabel;
  final String toLabel;

  const TransitDetailScreen({
    super.key,
    required this.from,
    required this.to,
    required this.fromLabel,
    required this.toLabel,
  });

  @override
  State<TransitDetailScreen> createState() => _TransitDetailScreenState();
}

class _TransitDetailScreenState extends State<TransitDetailScreen> {
  final VisitFirebaseService _service = VisitFirebaseService();
  final MapController _mapController = MapController();
  List<LatLng> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('tracker_paired_device_id');
    if (deviceId == null || widget.from.departureTime == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final pts = await _service.locationHistoryBetween(
        deviceId,
        widget.from.departureTime!,
        widget.to.arrivalTime,
      );
      if (!mounted) return;
      setState(() {
        _points = pts;
        _loading = false;
      });
      _fitToPoints();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fitToPoints() {
    if (_points.length < 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: _points,
          padding: const EdgeInsets.all(40),
        ),
      );
    });
  }

  String _formatTime(DateTime t) => DateFormat('h:mm a').format(t);

  String _formatDuration(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final depart = widget.from.departureTime;
    final arrive = widget.to.arrivalTime;
    final duration =
        depart != null ? arrive.difference(depart) : Duration.zero;

    final initialCenter = _points.isNotEmpty
        ? _points.first
        : LatLng(
            (widget.from.latitude + widget.to.latitude) / 2,
            (widget.from.longitude + widget.to.longitude) / 2,
          );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.financesensei',
                    ),
                    if (_points.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _points,
                            color: const Color(0xFF2E7CF6),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                              widget.from.latitude, widget.from.longitude),
                          width: 16,
                          height: 16,
                          child: _endpointDot(Colors.black),
                        ),
                        Marker(
                          point:
                              LatLng(widget.to.latitude, widget.to.longitude),
                          width: 16,
                          height: 16,
                          child: _endpointDot(const Color(0xFF2E7CF6)),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: const Icon(Icons.arrow_back,
                          size: 20, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.fromLabel}  →  ${widget.toLabel}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Row(
                    label: 'Duration',
                    value: _formatDuration(duration),
                  ),
                  const SizedBox(height: 16),
                  _Row(
                    label: 'Left',
                    value: depart != null ? _formatTime(depart) : '—',
                  ),
                  const SizedBox(height: 16),
                  _Row(
                    label: 'Arrived',
                    value: _formatTime(arrive),
                  ),
                  const SizedBox(height: 16),
                  _Row(
                    label: 'Samples',
                    value: _loading
                        ? '…'
                        : (_points.isEmpty ? 'No path recorded' : '${_points.length}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endpointDot(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF888888),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
