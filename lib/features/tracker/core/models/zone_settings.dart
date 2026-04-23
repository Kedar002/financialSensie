/// Per-zone settings controlled by the Viewer.
/// Synced via Firebase so the tracker can respect them.
class ZoneSettings {
  final int? id;
  final int geofenceId;
  final String zoneName;
  final bool alertOnEnter;
  final bool alertOnExit;
  final int minimumStayMinutes;
  final bool suppressWhileInside;
  final bool alertOnlyOnExit;

  /// Custom GPS update interval for this zone, in minutes.
  /// 0 = use default (smart algorithm decides).
  final int updateIntervalMinutes;

  const ZoneSettings({
    this.id,
    required this.geofenceId,
    required this.zoneName,
    this.alertOnEnter = true,
    this.alertOnExit = true,
    this.minimumStayMinutes = 0,
    this.suppressWhileInside = false,
    this.alertOnlyOnExit = false,
    this.updateIntervalMinutes = 0,
  });

  ZoneSettings copyWith({
    int? id,
    int? geofenceId,
    String? zoneName,
    bool? alertOnEnter,
    bool? alertOnExit,
    int? minimumStayMinutes,
    bool? suppressWhileInside,
    bool? alertOnlyOnExit,
    int? updateIntervalMinutes,
  }) {
    return ZoneSettings(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      zoneName: zoneName ?? this.zoneName,
      alertOnEnter: alertOnEnter ?? this.alertOnEnter,
      alertOnExit: alertOnExit ?? this.alertOnExit,
      minimumStayMinutes: minimumStayMinutes ?? this.minimumStayMinutes,
      suppressWhileInside: suppressWhileInside ?? this.suppressWhileInside,
      alertOnlyOnExit: alertOnlyOnExit ?? this.alertOnlyOnExit,
      updateIntervalMinutes:
          updateIntervalMinutes ?? this.updateIntervalMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'geofence_id': geofenceId,
      'zone_name': zoneName,
      'alert_on_enter': alertOnEnter ? 1 : 0,
      'alert_on_exit': alertOnExit ? 1 : 0,
      'minimum_stay_minutes': minimumStayMinutes,
      'suppress_while_inside': suppressWhileInside ? 1 : 0,
      'alert_only_on_exit': alertOnlyOnExit ? 1 : 0,
      'update_interval_minutes': updateIntervalMinutes,
    };
  }

  factory ZoneSettings.fromMap(Map<String, dynamic> map) {
    return ZoneSettings(
      id: map['id'] as int?,
      geofenceId: map['geofence_id'] as int,
      zoneName: map['zone_name'] as String,
      alertOnEnter: map['alert_on_enter'] == 1,
      alertOnExit: map['alert_on_exit'] == 1,
      minimumStayMinutes: map['minimum_stay_minutes'] as int? ?? 0,
      suppressWhileInside: map['suppress_while_inside'] == 1,
      alertOnlyOnExit: map['alert_only_on_exit'] == 1,
      updateIntervalMinutes: map['update_interval_minutes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'geofenceId': geofenceId,
      'zoneName': zoneName,
      'alertOnEnter': alertOnEnter,
      'alertOnExit': alertOnExit,
      'minimumStayMinutes': minimumStayMinutes,
      'suppressWhileInside': suppressWhileInside,
      'alertOnlyOnExit': alertOnlyOnExit,
      'updateIntervalMinutes': updateIntervalMinutes,
    };
  }

  factory ZoneSettings.fromFirestore(Map<String, dynamic> map) {
    return ZoneSettings(
      geofenceId: map['geofenceId'] as int? ?? 0,
      zoneName: map['zoneName'] as String? ?? '',
      alertOnEnter: map['alertOnEnter'] as bool? ?? true,
      alertOnExit: map['alertOnExit'] as bool? ?? true,
      minimumStayMinutes: map['minimumStayMinutes'] as int? ?? 0,
      suppressWhileInside: map['suppressWhileInside'] as bool? ?? false,
      alertOnlyOnExit: map['alertOnlyOnExit'] as bool? ?? false,
      updateIntervalMinutes: map['updateIntervalMinutes'] as int? ?? 0,
    );
  }
}
