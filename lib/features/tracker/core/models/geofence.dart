import 'package:latlong2/latlong.dart';

class Geofence {
  final int? id;
  final String name;
  final LatLng center;
  final double radiusMeters;
  final bool notifyOnEnter;
  final bool notifyOnExit;
  final DateTime? createdAt;

  const Geofence({
    this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
    this.notifyOnEnter = true,
    this.notifyOnExit = true,
    this.createdAt,
  });

  Geofence copyWith({
    int? id,
    String? name,
    LatLng? center,
    double? radiusMeters,
    bool? notifyOnEnter,
    bool? notifyOnExit,
    DateTime? createdAt,
  }) {
    return Geofence(
      id: id ?? this.id,
      name: name ?? this.name,
      center: center ?? this.center,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      notifyOnEnter: notifyOnEnter ?? this.notifyOnEnter,
      notifyOnExit: notifyOnExit ?? this.notifyOnExit,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radius_meters': radiusMeters,
      'notify_on_enter': notifyOnEnter ? 1 : 0,
      'notify_on_exit': notifyOnExit ? 1 : 0,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    return Geofence(
      id: map['id'] as int?,
      name: map['name'] as String,
      center: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      radiusMeters: (map['radius_meters'] as num).toDouble(),
      notifyOnEnter: map['notify_on_enter'] == 1,
      notifyOnExit: map['notify_on_exit'] == 1,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'latitude': center.latitude,
      'longitude': center.longitude,
      'radiusMeters': radiusMeters,
      'notifyOnEnter': notifyOnEnter,
      'notifyOnExit': notifyOnExit,
    };
  }

  factory Geofence.fromFirestore(Map<String, dynamic> map, {int? localId}) {
    return Geofence(
      id: localId,
      name: map['name'] as String? ?? '',
      center: LatLng(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100.0,
      notifyOnEnter: map['notifyOnEnter'] as bool? ?? true,
      notifyOnExit: map['notifyOnExit'] as bool? ?? true,
    );
  }
}
