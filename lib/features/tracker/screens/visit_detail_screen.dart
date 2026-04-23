import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../core/models/visit.dart';

class VisitDetailScreen extends StatelessWidget {
  final Visit visit;
  final String? resolvedZoneName;

  const VisitDetailScreen({
    super.key,
    required this.visit,
    this.resolvedZoneName,
  });

  String _formatTime(DateTime time) => DateFormat('h:mm a').format(time);

  String _formatDate(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    if (date == today) return 'Today';
    if (date == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(time);
  }

  String _formatDuration(Duration dur) {
    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes % 60}m';
    }
    return '${dur.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final label = resolvedZoneName ??
        visit.zoneName ??
        '${visit.latitude.toStringAsFixed(4)}, ${visit.longitude.toStringAsFixed(4)}';
    final center = LatLng(visit.latitude, visit.longitude);
    final duration = visit.duration;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Map — top half
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 16,
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
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: center,
                          radius: 60,
                          color: Colors.black.withValues(alpha: 0.06),
                          borderColor: Colors.black.withValues(alpha: 0.15),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: visit.isActive
                                  ? const Color(0xFF4CAF50)
                                  : Colors.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Back button
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
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details — bottom
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location name
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(visit.arrivalTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                  if (visit.isActive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Currently here',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Duration
                  _DetailRow(
                    label: 'Duration',
                    value: _formatDuration(duration),
                  ),
                  const SizedBox(height: 16),

                  // Arrival
                  _DetailRow(
                    label: 'Arrived',
                    value: _formatTime(visit.arrivalTime),
                  ),
                  const SizedBox(height: 16),

                  // Departure
                  _DetailRow(
                    label: 'Left',
                    value: visit.departureTime != null
                        ? _formatTime(visit.departureTime!)
                        : 'Still here',
                  ),

                  // Battery info (only if available)
                  if (visit.batteryOnArrival >= 0) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Battery on arrival',
                      value: '${visit.batteryOnArrival}%',
                    ),
                  ],
                  if (visit.batteryOnDeparture != null) ...[
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Battery on departure',
                      value: '${visit.batteryOnDeparture}%',
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Coordinates (tappable to copy)
                  _CopyableDetailRow(
                    label: 'Coordinates',
                    value:
                        '${visit.latitude.toStringAsFixed(5)}, ${visit.longitude.toStringAsFixed(5)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

class _CopyableDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coordinates copied'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Row(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.copy,
                size: 14,
                color: Color(0xFFAAAAAA),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
