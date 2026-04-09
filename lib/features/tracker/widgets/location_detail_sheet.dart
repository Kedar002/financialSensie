import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/models/location_data.dart';

class LocationDetailSheet extends StatelessWidget {
  final LocationData location;
  final bool useKm;

  const LocationDetailSheet({
    super.key,
    required this.location,
    this.useKm = true,
  });

  String _timeAgo() {
    final diff = DateTime.now().difference(location.timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final speed = useKm ? location.speedKmh : location.speedMph;
    final speedUnit = useKm ? 'km/h' : 'mph';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Location Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _DetailRow('Latitude', location.latitude.toStringAsFixed(6)),
          _DetailRow('Longitude', location.longitude.toStringAsFixed(6)),
          _DetailRow('Accuracy', '±${location.accuracy.toStringAsFixed(0)}m'),
          _DetailRow('Speed', '${speed.toStringAsFixed(1)} $speedUnit'),
          _DetailRow('Last Updated', _timeAgo()),
          _DetailRow(
            'Battery',
            '${location.batteryLevel}%${location.isCharging ? ' (Charging)' : ''}',
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              final coords =
                  '${location.latitude},${location.longitude}';
              Clipboard.setData(ClipboardData(text: coords));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: $coords'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Copy Coordinates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF888888),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
