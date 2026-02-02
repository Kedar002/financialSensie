class CycleSettings {
  final int id;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final int payCycleDay;

  CycleSettings({
    this.id = 1,
    required this.cycleStart,
    required this.cycleEnd,
    this.payCycleDay = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_start': cycleStart.toIso8601String(),
      'cycle_end': cycleEnd.toIso8601String(),
      'pay_cycle_day': payCycleDay,
    };
  }

  factory CycleSettings.fromMap(Map<String, dynamic> map) {
    return CycleSettings(
      id: map['id'] as int,
      cycleStart: DateTime.parse(map['cycle_start'] as String),
      cycleEnd: DateTime.parse(map['cycle_end'] as String),
      payCycleDay: map['pay_cycle_day'] as int,
    );
  }

  CycleSettings copyWith({
    DateTime? cycleStart,
    DateTime? cycleEnd,
    int? payCycleDay,
  }) {
    return CycleSettings(
      id: id,
      cycleStart: cycleStart ?? this.cycleStart,
      cycleEnd: cycleEnd ?? this.cycleEnd,
      payCycleDay: payCycleDay ?? this.payCycleDay,
    );
  }

  /// Calculate default cycle dates based on pay cycle day
  static CycleSettings createDefault({int payCycleDay = 1}) {
    final now = DateTime.now();
    DateTime cycleStart;
    DateTime cycleEnd;

    if (now.day >= payCycleDay) {
      cycleStart = DateTime(now.year, now.month, payCycleDay);
      cycleEnd = DateTime(now.year, now.month + 1, payCycleDay - 1);
    } else {
      cycleStart = DateTime(now.year, now.month - 1, payCycleDay);
      cycleEnd = DateTime(now.year, now.month, payCycleDay - 1);
    }

    return CycleSettings(
      cycleStart: cycleStart,
      cycleEnd: cycleEnd,
      payCycleDay: payCycleDay,
    );
  }

  /// Calculate next cycle dates based on current cycle end
  CycleSettings nextCycle() {
    // Next cycle starts the day after current cycle ends
    final nextStart = cycleEnd.add(const Duration(days: 1));

    // Calculate next cycle end based on pay cycle day
    DateTime nextEnd;
    if (nextStart.day >= payCycleDay) {
      nextEnd = DateTime(nextStart.year, nextStart.month + 1, payCycleDay - 1);
    } else {
      nextEnd = DateTime(nextStart.year, nextStart.month, payCycleDay - 1);
    }

    return CycleSettings(
      cycleStart: nextStart,
      cycleEnd: nextEnd,
      payCycleDay: payCycleDay,
    );
  }
}
