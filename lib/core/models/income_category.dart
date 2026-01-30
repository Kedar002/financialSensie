class IncomeCategory {
  final int? id;
  final String name;
  final int amount;
  final String frequency;
  final DateTime createdAt;

  IncomeCategory({
    this.id,
    required this.name,
    this.amount = 0,
    this.frequency = 'monthly',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory IncomeCategory.fromMap(Map<String, dynamic> map) {
    return IncomeCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: map['amount'] as int? ?? 0,
      frequency: map['frequency'] as String? ?? 'monthly',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  IncomeCategory copyWith({
    int? id,
    String? name,
    int? amount,
    String? frequency,
    DateTime? createdAt,
  }) {
    return IncomeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
