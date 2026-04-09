import 'package:flutter/material.dart';

class BatteryBadge extends StatelessWidget {
  final int level;
  final bool isCharging;

  const BatteryBadge({
    super.key,
    required this.level,
    this.isCharging = false,
  });

  Color get _color {
    if (level <= 15) return const Color(0xFFE53935);
    if (level <= 30) return const Color(0xFFFF9800);
    return const Color(0xFF4CAF50);
  }

  IconData get _icon {
    if (isCharging) return Icons.battery_charging_full;
    if (level <= 15) return Icons.battery_alert;
    if (level <= 50) return Icons.battery_3_bar;
    return Icons.battery_full;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            '$level%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
