class UserProfile {
  final int? id;
  final String name;
  final String currency;
  final String riskLevel;
  final int dependents;
  final int salaryDay; // Day of month when salary arrives (1-28)
  final int createdAt;
  final int updatedAt;

  const UserProfile({
    this.id,
    required this.name,
    this.currency = 'INR',
    this.riskLevel = 'moderate',
    this.dependents = 0,
    this.salaryDay = 1, // Default: 1st of month
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currency': currency,
      'risk_level': riskLevel,
      'dependents': dependents,
      'salary_day': salaryDay,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int?,
      name: map['name'] as String,
      currency: map['currency'] as String,
      riskLevel: map['risk_level'] as String,
      dependents: map['dependents'] as int,
      salaryDay: (map['salary_day'] as int?) ?? 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  UserProfile copyWith({
    int? id,
    String? name,
    String? currency,
    String? riskLevel,
    int? dependents,
    int? salaryDay,
    int? createdAt,
    int? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      riskLevel: riskLevel ?? this.riskLevel,
      dependents: dependents ?? this.dependents,
      salaryDay: salaryDay ?? this.salaryDay,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get emergencyFundMonths {
    switch (riskLevel) {
      case 'low':
        return 8;
      case 'high':
        return 4;
      default:
        return 6;
    }
  }

  /// Get the start date of current payment cycle
  DateTime get currentCycleStart {
    final now = DateTime.now();
    if (now.day >= salaryDay) {
      return DateTime(now.year, now.month, salaryDay);
    } else {
      // We're before salary day, so cycle started last month
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      return DateTime(lastMonth.year, lastMonth.month, salaryDay);
    }
  }

  /// Get the end date of current payment cycle
  DateTime get currentCycleEnd {
    final start = currentCycleStart;
    final nextMonth = DateTime(start.year, start.month + 1, salaryDay);
    return nextMonth.subtract(const Duration(days: 1));
  }

  /// Days remaining in current payment cycle
  int get daysRemainingInCycle {
    final now = DateTime.now();
    final end = currentCycleEnd;
    final diff = end.difference(now).inDays;
    return diff + 1; // Include today
  }
}
