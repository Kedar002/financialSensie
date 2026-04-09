class SavedLocation {
  final int? id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;
  final double heading;
  final int batteryLevel;
  final bool isCharging;
  final DateTime timestamp;
  final DateTime savedAt;

  const SavedLocation({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
    required this.heading,
    required this.batteryLevel,
    required this.isCharging,
    required this.timestamp,
    required this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'speed': speed,
      'heading': heading,
      'battery_level': batteryLevel,
      'is_charging': isCharging ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'saved_at': savedAt.toIso8601String(),
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      speed: (map['speed'] as num).toDouble(),
      heading: (map['heading'] as num).toDouble(),
      batteryLevel: map['battery_level'] as int,
      isCharging: map['is_charging'] == 1,
      timestamp: DateTime.parse(map['timestamp'] as String),
      savedAt: DateTime.parse(map['saved_at'] as String),
    );
  }

  double get speedKmh => speed * 3.6;
  double get speedMph => speed * 2.237;
}
