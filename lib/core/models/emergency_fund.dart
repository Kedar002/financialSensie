class EmergencyFund {
  final int? id;
  final int userId;
  final double targetAmount;
  final double currentAmount;
  final int targetMonths;
  final double monthlyEssential;
  final int updatedAt;

  const EmergencyFund({
    this.id,
    required this.userId,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetMonths = 6,
    required this.monthlyEssential,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_months': targetMonths,
      'monthly_essential': monthlyEssential,
      'updated_at': updatedAt,
    };
  }

  factory EmergencyFund.fromMap(Map<String, dynamic> map) {
    return EmergencyFund(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      targetAmount: (map['target_amount'] as num).toDouble(),
      currentAmount: (map['current_amount'] as num).toDouble(),
      targetMonths: map['target_months'] as int,
      monthlyEssential: (map['monthly_essential'] as num).toDouble(),
      updatedAt: map['updated_at'] as int,
    );
  }

  EmergencyFund copyWith({
    int? id,
    int? userId,
    double? targetAmount,
    double? currentAmount,
    int? targetMonths,
    double? monthlyEssential,
    int? updatedAt,
  }) {
    return EmergencyFund(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetMonths: targetMonths ?? this.targetMonths,
      monthlyEssential: monthlyEssential ?? this.monthlyEssential,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get runwayMonths {
    if (monthlyEssential == 0) return 0;
    return currentAmount / monthlyEssential;
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  bool get isComplete => currentAmount >= targetAmount;

  bool get isLow => runwayMonths < 3;
}
