class Expense {
  final int? id;
  final int amount;
  final String type; // 'needs', 'wants', 'savings', 'income'
  final int? categoryId;
  final String categoryName;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.amount,
    required this.type,
    this.categoryId,
    required this.categoryName,
    this.note,
    DateTime? date,
    DateTime? createdAt,
  })  : date = date ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  bool get isIncome => type == 'income';
  bool get isExpense => type != 'income';

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'type': type,
      'category_id': categoryId,
      'category_name': categoryName,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as int,
      type: map['type'] as String,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String,
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Expense copyWith({
    int? id,
    int? amount,
    String? type,
    int? categoryId,
    String? categoryName,
    String? note,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      note: note ?? this.note,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
