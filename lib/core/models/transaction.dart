class Transaction {
  final int? id;
  final int userId;
  final double amount;
  final String category;
  final String? description;
  final int date;
  final bool isPlanned;
  final int? plannedExpenseId;
  final int createdAt;

  const Transaction({
    this.id,
    required this.userId,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    this.isPlanned = false,
    this.plannedExpenseId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'is_planned': isPlanned ? 1 : 0,
      'planned_expense_id': plannedExpenseId,
      'created_at': createdAt,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      description: map['description'] as String?,
      date: map['date'] as int,
      isPlanned: (map['is_planned'] as int) == 1,
      plannedExpenseId: map['planned_expense_id'] as int?,
      createdAt: map['created_at'] as int,
    );
  }

  Transaction copyWith({
    int? id,
    int? userId,
    double? amount,
    String? category,
    String? description,
    int? date,
    bool? isPlanned,
    int? plannedExpenseId,
    int? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      isPlanned: isPlanned ?? this.isPlanned,
      plannedExpenseId: plannedExpenseId ?? this.plannedExpenseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date * 1000);
}
