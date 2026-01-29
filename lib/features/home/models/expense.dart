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

/// Expense subcategory - specific type within each main category.
/// Connected to Profile settings.
enum ExpenseSubcategory {
  // Needs - Fixed Expenses (from Profile → Fixed Expenses)
  rentEmi,
  utilitiesBills,
  otherFixed,

  // Needs - Variable Essentials (from Profile → Variable Budget)
  foodDining,
  transport,
  healthWellness,

  // Wants - Variable Lifestyle (from Profile → Variable Budget)
  shopping,
  entertainment,
  otherVariable,

  // Savings - Destinations
  emergencyFund,
  goals;

  String get label {
    switch (this) {
      case ExpenseSubcategory.rentEmi:
        return 'Rent / EMI';
      case ExpenseSubcategory.utilitiesBills:
        return 'Utilities & Bills';
      case ExpenseSubcategory.otherFixed:
        return 'Other Fixed';
      case ExpenseSubcategory.foodDining:
        return 'Food & Dining';
      case ExpenseSubcategory.transport:
        return 'Transport';
      case ExpenseSubcategory.healthWellness:
        return 'Health & Wellness';
      case ExpenseSubcategory.shopping:
        return 'Shopping';
      case ExpenseSubcategory.entertainment:
        return 'Entertainment';
      case ExpenseSubcategory.otherVariable:
        return 'Other';
      case ExpenseSubcategory.emergencyFund:
        return 'Emergency Fund';
      case ExpenseSubcategory.goals:
        return 'Goals';
    }
  }

  /// Which main category this subcategory belongs to.
  ExpenseCategory get parentCategory {
    switch (this) {
      case ExpenseSubcategory.rentEmi:
      case ExpenseSubcategory.utilitiesBills:
      case ExpenseSubcategory.otherFixed:
      case ExpenseSubcategory.foodDining:
      case ExpenseSubcategory.transport:
      case ExpenseSubcategory.healthWellness:
        return ExpenseCategory.needs;
      case ExpenseSubcategory.shopping:
      case ExpenseSubcategory.entertainment:
      case ExpenseSubcategory.otherVariable:
        return ExpenseCategory.wants;
      case ExpenseSubcategory.emergencyFund:
      case ExpenseSubcategory.goals:
        return ExpenseCategory.savings;
    }
  }

  /// Get all subcategories for a given main category.
  static List<ExpenseSubcategory> forCategory(ExpenseCategory category) {
    return ExpenseSubcategory.values
        .where((sub) => sub.parentCategory == category)
        .toList();
  }
}

/// Simple expense model.
/// Just what's needed. Nothing more.
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final ExpenseSubcategory subcategory;
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.subcategory,
    this.note,
    required this.date,
    required this.createdAt,
  });

  /// Create a new expense with auto-generated ID.
  factory Expense.create({
    required double amount,
    required ExpenseCategory category,
    required ExpenseSubcategory subcategory,
    String? note,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return Expense(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      category: category,
      subcategory: subcategory,
      note: note,
      date: date ?? now,
      createdAt: now,
    );
  }
}
