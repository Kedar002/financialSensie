class Visit {
  final int? id;
  final double latitude;
  final double longitude;
  final DateTime arrivalTime;
  final DateTime? departureTime;
  final int? durationMinutes;
  final String? zoneName;
  final int? zoneId;
  final int batteryOnArrival;
  final int? batteryOnDeparture;

  const Visit({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.arrivalTime,
    this.departureTime,
    this.durationMinutes,
    this.zoneName,
    this.zoneId,
    this.batteryOnArrival = -1,
    this.batteryOnDeparture,
  });

  bool get isActive => departureTime == null;

  Duration get duration {
    if (departureTime != null) {
      return departureTime!.difference(arrivalTime);
    }
    return DateTime.now().difference(arrivalTime);
  }

  Visit copyWith({
    int? id,
    double? latitude,
    double? longitude,
    DateTime? arrivalTime,
    DateTime? departureTime,
    int? durationMinutes,
    String? zoneName,
    int? zoneId,
    int? batteryOnArrival,
    int? batteryOnDeparture,
  }) {
    return Visit(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      departureTime: departureTime ?? this.departureTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      zoneName: zoneName ?? this.zoneName,
      zoneId: zoneId ?? this.zoneId,
      batteryOnArrival: batteryOnArrival ?? this.batteryOnArrival,
      batteryOnDeparture: batteryOnDeparture ?? this.batteryOnDeparture,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'arrival_time': arrivalTime.toIso8601String(),
      'departure_time': departureTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'zone_name': zoneName,
      'zone_id': zoneId,
      'battery_on_arrival': batteryOnArrival,
      'battery_on_departure': batteryOnDeparture,
    };
  }

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'] as int?,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      arrivalTime: DateTime.parse(map['arrival_time'] as String),
      departureTime: map['departure_time'] != null
          ? DateTime.parse(map['departure_time'] as String)
          : null,
      durationMinutes: map['duration_minutes'] as int?,
      zoneName: map['zone_name'] as String?,
      zoneId: map['zone_id'] as int?,
      batteryOnArrival: map['battery_on_arrival'] as int? ?? -1,
      batteryOnDeparture: map['battery_on_departure'] as int?,
    );
  }

  /// Convert to Firebase document data.
  Map<String, dynamic> toFirestore() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'arrivalTime': arrivalTime.toIso8601String(),
      'departureTime': departureTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'zoneName': zoneName,
      'zoneId': zoneId,
      'batteryOnArrival': batteryOnArrival,
      'batteryOnDeparture': batteryOnDeparture,
    };
  }

  factory Visit.fromFirestore(Map<String, dynamic> map) {
    return Visit(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      arrivalTime: DateTime.parse(map['arrivalTime'] as String),
      departureTime: map['departureTime'] != null
          ? DateTime.parse(map['departureTime'] as String)
          : null,
      durationMinutes: map['durationMinutes'] as int?,
      zoneName: map['zoneName'] as String?,
      zoneId: map['zoneId'] as int?,
      batteryOnArrival: map['batteryOnArrival'] as int? ?? -1,
      batteryOnDeparture: map['batteryOnDeparture'] as int?,
    );
  }
}
