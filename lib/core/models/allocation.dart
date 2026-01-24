class Allocation {
  final int? id;
  final int userId;
  final String type;
  final String name;
  final double? percentage;
  final double? fixedAmount;
  final int priority;
  final bool isActive;
  final int createdAt;

  const Allocation({
    this.id,
    required this.userId,
    required this.type,
    required this.name,
    this.percentage,
    this.fixedAmount,
    required this.priority,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'name': name,
      'percentage': percentage,
      'fixed_amount': fixedAmount,
      'priority': priority,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory Allocation.fromMap(Map<String, dynamic> map) {
    return Allocation(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: map['type'] as String,
      name: map['name'] as String,
      percentage: map['percentage'] != null
          ? (map['percentage'] as num).toDouble()
          : null,
      fixedAmount: map['fixed_amount'] != null
          ? (map['fixed_amount'] as num).toDouble()
          : null,
      priority: map['priority'] as int,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as int,
    );
  }

  Allocation copyWith({
    int? id,
    int? userId,
    String? type,
    String? name,
    double? percentage,
    double? fixedAmount,
    int? priority,
    bool? isActive,
    int? createdAt,
  }) {
    return Allocation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      fixedAmount: fixedAmount ?? this.fixedAmount,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double calculateAmount(double totalIncome) {
    if (fixedAmount != null) {
      return fixedAmount!;
    }
    if (percentage != null) {
      return totalIncome * percentage! / 100;
    }
    return 0;
  }
}

class AllocationType {
  static const String emergencyFund = 'emergency_fund';
  static const String investment = 'investment';
  static const String goal = 'goal';
  static const String spending = 'spending';

  static const List<String> all = [
    emergencyFund,
    investment,
    goal,
    spending,
  ];
}
