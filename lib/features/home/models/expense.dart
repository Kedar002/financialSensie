/// Simple expense model.
/// Just what's needed. Nothing more.
class Expense {
  final String id;
  final double amount;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    this.note,
    required this.date,
    required this.createdAt,
  });

  /// Create a new expense with auto-generated ID.
  factory Expense.create({
    required double amount,
    String? note,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return Expense(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      note: note,
      date: date ?? now,
      createdAt: now,
    );
  }
}
