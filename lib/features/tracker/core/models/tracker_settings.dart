import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerSettings {
  final bool pulsingAnimation;
  final bool showAccuracyCircle;
  final int movementAlertMinutes; // 0 = disabled
  final int lowBatteryThreshold; // 0 = disabled
  final int connectionLostMinutes; // 0 = disabled
  final bool useKm;
  final bool use24hr;
  final bool showSpeedOnMap;
  final bool showBatteryOnMap;
  final bool showTrail;
  final String updateFrequency; // 'normal', 'power_saver', 'realtime'
  final bool autoDeleteHistory;

  const TrackerSettings({
    this.pulsingAnimation = true,
    this.showAccuracyCircle = true,
    this.movementAlertMinutes = 0,
    this.lowBatteryThreshold = 0,
    this.connectionLostMinutes = 0,
    this.useKm = true,
    this.use24hr = true,
    this.showSpeedOnMap = true,
    this.showBatteryOnMap = true,
    this.showTrail = true,
    this.updateFrequency = 'normal',
    this.autoDeleteHistory = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'pulsingAnimation': pulsingAnimation,
      'showAccuracyCircle': showAccuracyCircle,
      'movementAlertMinutes': movementAlertMinutes,
      'lowBatteryThreshold': lowBatteryThreshold,
      'connectionLostMinutes': connectionLostMinutes,
      'useKm': useKm,
      'use24hr': use24hr,
      'showSpeedOnMap': showSpeedOnMap,
      'showBatteryOnMap': showBatteryOnMap,
      'showTrail': showTrail,
      'updateFrequency': updateFrequency,
      'autoDeleteHistory': autoDeleteHistory,
    };
  }

  factory TrackerSettings.fromJson(Map<String, dynamic> json) {
    return TrackerSettings(
      pulsingAnimation: json['pulsingAnimation'] as bool? ?? true,
      showAccuracyCircle: json['showAccuracyCircle'] as bool? ?? true,
      movementAlertMinutes: json['movementAlertMinutes'] as int? ?? 0,
      lowBatteryThreshold: json['lowBatteryThreshold'] as int? ?? 0,
      connectionLostMinutes: json['connectionLostMinutes'] as int? ?? 0,
      useKm: json['useKm'] as bool? ?? true,
      use24hr: json['use24hr'] as bool? ?? true,
      showSpeedOnMap: json['showSpeedOnMap'] as bool? ?? true,
      showBatteryOnMap: json['showBatteryOnMap'] as bool? ?? true,
      showTrail: json['showTrail'] as bool? ?? true,
      updateFrequency: json['updateFrequency'] as String? ?? 'normal',
      autoDeleteHistory: json['autoDeleteHistory'] as bool? ?? false,
    );
  }

  static Future<TrackerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('tracker_settings');
    if (jsonStr == null) return const TrackerSettings();
    return TrackerSettings.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_settings', jsonEncode(toJson()));
  }

  TrackerSettings copyWith({
    bool? pulsingAnimation,
    bool? showAccuracyCircle,
    int? movementAlertMinutes,
    int? lowBatteryThreshold,
    int? connectionLostMinutes,
    bool? useKm,
    bool? use24hr,
    bool? showSpeedOnMap,
    bool? showBatteryOnMap,
    bool? showTrail,
    String? updateFrequency,
    bool? autoDeleteHistory,
  }) {
    return TrackerSettings(
      pulsingAnimation: pulsingAnimation ?? this.pulsingAnimation,
      showAccuracyCircle: showAccuracyCircle ?? this.showAccuracyCircle,
      movementAlertMinutes: movementAlertMinutes ?? this.movementAlertMinutes,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      connectionLostMinutes: connectionLostMinutes ?? this.connectionLostMinutes,
      useKm: useKm ?? this.useKm,
      use24hr: use24hr ?? this.use24hr,
      showSpeedOnMap: showSpeedOnMap ?? this.showSpeedOnMap,
      showBatteryOnMap: showBatteryOnMap ?? this.showBatteryOnMap,
      showTrail: showTrail ?? this.showTrail,
      updateFrequency: updateFrequency ?? this.updateFrequency,
      autoDeleteHistory: autoDeleteHistory ?? this.autoDeleteHistory,
    );
  }
}
