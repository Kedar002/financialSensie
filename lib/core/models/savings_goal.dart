class SavingsGoal {
  final int? id;
  final String name;
  final int target;
  final int saved;
  final int monthly;
  final DateTime targetDate;
  final String icon;
  final DateTime createdAt;

  SavingsGoal({
    this.id,
    required this.name,
    required this.target,
    this.saved = 0,
    this.monthly = 0,
    required this.targetDate,
    required this.icon,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target': target,
      'saved': saved,
      'monthly': monthly,
      'target_date': targetDate.toIso8601String(),
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'] as int?,
      name: map['name'] as String,
      target: map['target'] as int? ?? 0,
      saved: map['saved'] as int? ?? 0,
      monthly: map['monthly'] as int? ?? 0,
      targetDate: DateTime.parse(map['target_date'] as String),
      icon: map['icon'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SavingsGoal copyWith({
    int? id,
    String? name,
    int? target,
    int? saved,
    int? monthly,
    DateTime? targetDate,
    String? icon,
    DateTime? createdAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      saved: saved ?? this.saved,
      monthly: monthly ?? this.monthly,
      targetDate: targetDate ?? this.targetDate,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress => target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
  int get percentage => (progress * 100).round();
  int get remaining => target - saved;
  int get monthsRemaining => monthly > 0 && remaining > 0 ? (remaining / monthly).ceil() : 0;

  String get investmentSuggestion {
    final now = DateTime.now();
    final years = targetDate.difference(now).inDays / 365;

    if (years < 1) {
      return 'Savings Account or Cash';
    } else if (years <= 5) {
      return 'Fixed Deposit or Debt Mutual Funds';
    } else {
      return 'Equity Mutual Funds or Index Funds';
    }
  }
}
