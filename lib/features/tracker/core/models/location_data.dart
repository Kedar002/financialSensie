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
  final bool isNetworkAvailable;
  final bool isLocationServiceEnabled;
  final int pendingQueueCount;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.speed = 0,
    this.heading = 0,
    this.accuracy = 0,
    this.batteryLevel = -1,
    this.isCharging = false,
    this.isNetworkAvailable = true,
    this.isLocationServiceEnabled = true,
    this.pendingQueueCount = 0,
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
      'isNetworkAvailable': isNetworkAvailable,
      'isLocationServiceEnabled': isLocationServiceEnabled,
      'pendingQueueCount': pendingQueueCount,
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
      isNetworkAvailable: (map['isNetworkAvailable'] as bool?) ?? true,
      isLocationServiceEnabled: (map['isLocationServiceEnabled'] as bool?) ?? true,
      pendingQueueCount: (map['pendingQueueCount'] as int?) ?? 0,
    );
  }

  double get speedKmh => speed * 3.6;
  double get speedMph => speed * 2.237;
}
