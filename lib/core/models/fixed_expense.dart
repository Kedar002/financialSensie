class FixedExpense {
  final int? id;
  final int userId;
  final String name;
  final double amount;
  final String category;
  final bool isEssential;
  final int? dueDay;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  const FixedExpense({
    this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.category,
    this.isEssential = true,
    this.dueDay,
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
      'category': category,
      'is_essential': isEssential ? 1 : 0,
      'due_day': dueDay,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory FixedExpense.fromMap(Map<String, dynamic> map) {
    return FixedExpense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      isEssential: (map['is_essential'] as int) == 1,
      dueDay: map['due_day'] as int?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  FixedExpense copyWith({
    int? id,
    int? userId,
    String? name,
    double? amount,
    String? category,
    bool? isEssential,
    int? dueDay,
    bool? isActive,
    int? createdAt,
    int? updatedAt,
  }) {
    return FixedExpense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isEssential: isEssential ?? this.isEssential,
      dueDay: dueDay ?? this.dueDay,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class FixedExpenseCategory {
  static const String housing = 'housing';
  static const String utilities = 'utilities';
  static const String insurance = 'insurance';
  static const String subscriptions = 'subscriptions';
  static const String loans = 'loans';
  static const String other = 'other';

  static const List<String> all = [
    housing,
    utilities,
    insurance,
    subscriptions,
    loans,
    other,
  ];
}
