class IncomeSource {
  final int? id;
  final int userId;
  final String name;
  final double amount;
  final String frequency;
  final int? payDay;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  const IncomeSource({
    this.id,
    required this.userId,
    required this.name,
    required this.amount,
    this.frequency = 'monthly',
    this.payDay,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'pay_day': payDay,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) {
    return IncomeSource(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      frequency: map['frequency'] as String,
      payDay: map['pay_day'] as int?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  IncomeSource copyWith({
    int? id,
    int? userId,
    String? name,
    double? amount,
    String? frequency,
    int? payDay,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
  }) {
    return IncomeSource(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      payDay: payDay ?? this.payDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get monthlyAmount {
    switch (frequency) {
      case 'weekly':
        return amount * 4;
      case 'biweekly':
        return amount * 2;
      default:
        return amount;
    }
  }
}
