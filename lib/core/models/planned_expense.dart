class PlannedExpense {
  final int? id;
  final int userId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final int targetDate;
  final double monthlyRequired;
  final int priority;
  final String status;
  final int createdAt;
  final int updatedAt;

  const PlannedExpense({
    this.id,
    required this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.targetDate,
    required this.monthlyRequired,
    this.priority = 1,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate,
      'monthly_required': monthlyRequired,
      'priority': priority,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory PlannedExpense.fromMap(Map<String, dynamic> map) {
    return PlannedExpense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetDate: map['target_date'] as int,
      monthlyRequired: (map['monthly_required'] as num).toDouble(),
      priority: map['priority'] as int,
      status: map['status'] as String,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  PlannedExpense copyWith({
    int? id,
    int? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    int? targetDate,
    double? monthlyRequired,
    int? priority,
    String? status,
    int? createdAt,
    int? updatedAt,
  }) {
    return PlannedExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      monthlyRequired: monthlyRequired ?? this.monthlyRequired,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  int get daysRemaining {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final remaining = targetDate - now;
    return (remaining / 86400).ceil();
  }

  int get monthsRemaining {
    return (daysRemaining / 30).ceil();
  }

  bool get isComplete => currentAmount >= targetAmount;

  bool get isOverdue => daysRemaining < 0 && !isComplete;

  static double calculateMonthlyRequired(
    double targetAmount,
    double currentAmount,
    int targetDateTimestamp,
  ) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final daysRemaining = ((targetDateTimestamp - now) / 86400).ceil();
    final monthsRemaining = (daysRemaining / 30).ceil();

    if (monthsRemaining <= 0) return targetAmount - currentAmount;

    return (targetAmount - currentAmount) / monthsRemaining;
  }
}

class PlannedExpenseStatus {
  static const String active = 'active';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class PlannedExpensePriority {
  static const int high = 1;
  static const int medium = 2;
  static const int low = 3;
}
