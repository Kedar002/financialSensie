/// Expense category.
/// Three buckets. That's all you need.
enum ExpenseCategory {
  needs,
  wants,
  savings;

  String get label {
    switch (this) {
      case ExpenseCategory.needs:
        return 'Needs';
      case ExpenseCategory.wants:
        return 'Wants';
      case ExpenseCategory.savings:
        return 'Savings';
    }
  }
}

/// Simple expense model.
/// Just what's needed. Nothing more.
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
  });

  /// Create a new expense with auto-generated ID.
  factory Expense.create({
    required double amount,
    required ExpenseCategory category,
    String? note,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return Expense(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      note: note,
      date: date ?? now,
      createdAt: now,
    );
  }
}
