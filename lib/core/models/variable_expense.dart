class VariableExpense {
  final int? id;
  final int userId;
  final String category;
  final double estimatedAmount;
  final bool isEssential;
  final int createdAt;
  final int updatedAt;

  const VariableExpense({
    this.id,
    required this.userId,
    required this.category,
    required this.estimatedAmount,
    this.isEssential = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category': category,
      'estimated_amount': estimatedAmount,
      'is_essential': isEssential ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory VariableExpense.fromMap(Map<String, dynamic> map) {
    return VariableExpense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      category: map['category'] as String,
      estimatedAmount: (map['estimated_amount'] as num).toDouble(),
      isEssential: (map['is_essential'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  VariableExpense copyWith({
    int? id,
    int? userId,
    String? category,
    double? estimatedAmount,
    bool? isEssential,
    int? createdAt,
    int? updatedAt,
  }) {
    return VariableExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      isEssential: isEssential ?? this.isEssential,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VariableExpenseCategory {
  static const String food = 'food';
  static const String transport = 'transport';
  static const String entertainment = 'entertainment';
  static const String shopping = 'shopping';
  static const String health = 'health';
  static const String other = 'other';

  static const List<String> all = [
    food,
    transport,
    entertainment,
    shopping,
    health,
    other,
  ];

  static const List<String> essential = [food, transport, health];
}
