class CycleHistory {
  final int? id;
  final String cycleName;
  final DateTime cycleStart;
  final DateTime cycleEnd;
  final int totalIncome;
  final int totalSpent;
  final int needsSpent;
  final int wantsSpent;
  final int savingsAdded;
  final int remaining;
  final DateTime createdAt;

  CycleHistory({
    this.id,
    required this.cycleName,
    required this.cycleStart,
    required this.cycleEnd,
    required this.totalIncome,
    required this.totalSpent,
    required this.needsSpent,
    required this.wantsSpent,
    required this.savingsAdded,
    required this.remaining,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cycle_name': cycleName,
      'cycle_start': cycleStart.toIso8601String(),
      'cycle_end': cycleEnd.toIso8601String(),
      'total_income': totalIncome,
      'total_spent': totalSpent,
      'needs_spent': needsSpent,
      'wants_spent': wantsSpent,
      'savings_added': savingsAdded,
      'remaining': remaining,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CycleHistory.fromMap(Map<String, dynamic> map) {
    return CycleHistory(
      id: map['id'] as int?,
      cycleName: map['cycle_name'] as String,
      cycleStart: DateTime.parse(map['cycle_start'] as String),
      cycleEnd: DateTime.parse(map['cycle_end'] as String),
      totalIncome: map['total_income'] as int,
      totalSpent: map['total_spent'] as int,
      needsSpent: map['needs_spent'] as int,
      wantsSpent: map['wants_spent'] as int,
      savingsAdded: map['savings_added'] as int,
      remaining: map['remaining'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
