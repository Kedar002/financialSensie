import 'package:cloud_firestore/cloud_firestore.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double speed;
  final double heading;
  final double accuracy;
  final int batteryLevel;
  final bool isCharging;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0,
    this.heading = 0,
    this.accuracy = 0,
    this.batteryLevel = -1,
    this.isCharging = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': FieldValue.serverTimestamp(),
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'batteryLevel': batteryLevel,
      'isCharging': isCharging,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      speed: (map['speed'] as num?)?.toDouble() ?? 0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
      batteryLevel: (map['batteryLevel'] as int?) ?? -1,
      isCharging: (map['isCharging'] as bool?) ?? false,
    );
  }

  double get speedKmh => speed * 3.6;
  double get speedMph => speed * 2.237;
}
