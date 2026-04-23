import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackerSettings {
  final String updateFrequency; // 'smart', 'realtime', 'normal', 'power_saver', 'custom'
  final int customFrequencySeconds; // used when updateFrequency == 'custom'
  final bool isPaused; // when true, all tracking is suspended

  const TrackerSettings({
    this.updateFrequency = 'smart',
    this.customFrequencySeconds = 60,
    this.isPaused = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'updateFrequency': updateFrequency,
      'customFrequencySeconds': customFrequencySeconds,
      'isPaused': isPaused,
    };
  }

  factory TrackerSettings.fromJson(Map<String, dynamic> json) {
    return TrackerSettings(
      updateFrequency: json['updateFrequency'] as String? ?? 'smart',
      customFrequencySeconds: json['customFrequencySeconds'] as int? ?? 60,
      isPaused: json['isPaused'] as bool? ?? false,
    );
  }

  static Future<TrackerSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('tracker_settings');
    debugPrint('[Settings] load: raw=$jsonStr');
    if (jsonStr == null) return const TrackerSettings();
    return TrackerSettings.fromJson(
      jsonDecode(jsonStr) as Map<String, dynamic>,
    );
  }

  Future<void> save() async {
    final json = jsonEncode(toJson());
    debugPrint('[Settings] save: $json');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_settings', json);
    // Verify it was written
    final verify = prefs.getString('tracker_settings');
    debugPrint('[Settings] verify after save: $verify');
  }

  TrackerSettings copyWith({
    String? updateFrequency,
    int? customFrequencySeconds,
    bool? isPaused,
  }) {
    return TrackerSettings(
      updateFrequency: updateFrequency ?? this.updateFrequency,
      customFrequencySeconds: customFrequencySeconds ?? this.customFrequencySeconds,
      isPaused: isPaused ?? this.isPaused,
    );
  }
}
