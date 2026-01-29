/// Expense category.
/// Three buckets: Needs, Wants, Savings.
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

/// Expense subcategory - specific type within Needs and Wants.
/// For Savings, we use SavingsDestination instead.
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
  otherVariable;

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
    }
  }

  /// Get all subcategories for a given main category (Needs or Wants only).
  static List<ExpenseSubcategory> forCategory(ExpenseCategory category) {
    if (category == ExpenseCategory.savings) {
      return []; // Savings uses SavingsDestination, not subcategories
    }
    return ExpenseSubcategory.values
        .where((sub) => sub.parentCategory == category)
        .toList();
  }
}

/// Savings destination - where savings money goes.
/// Either Emergency Fund or a specific Goal.
class SavingsDestination {
  final SavingsDestinationType type;
  final String? goalId;    // Only set if type is goal
  final String? goalName;  // Only set if type is goal

  const SavingsDestination._({
    required this.type,
    this.goalId,
    this.goalName,
  });

  /// Emergency Fund destination
  factory SavingsDestination.emergencyFund() {
    return const SavingsDestination._(
      type: SavingsDestinationType.emergencyFund,
    );
  }

  /// Specific goal destination
  factory SavingsDestination.goal({
    required String goalId,
    required String goalName,
  }) {
    return SavingsDestination._(
      type: SavingsDestinationType.goal,
      goalId: goalId,
      goalName: goalName,
    );
  }

  String get label {
    switch (type) {
      case SavingsDestinationType.emergencyFund:
        return 'Emergency Fund';
      case SavingsDestinationType.goal:
        return goalName ?? 'Goal';
    }
  }

  bool get isEmergencyFund => type == SavingsDestinationType.emergencyFund;
  bool get isGoal => type == SavingsDestinationType.goal;
}

enum SavingsDestinationType {
  emergencyFund,
  goal,
}

/// Expense model.
/// For Needs/Wants: uses subcategory.
/// For Savings: uses savingsDestination (Emergency Fund or specific Goal).
class Expense {
  final String id;
  final double amount;
  final ExpenseCategory category;
  final ExpenseSubcategory? subcategory;        // For Needs/Wants
  final SavingsDestination? savingsDestination; // For Savings
  final String? note;
  final DateTime date;
  final DateTime createdAt;

  const Expense({
    required this.id,
    required this.amount,
    required this.category,
    this.subcategory,
    this.savingsDestination,
    this.note,
    required this.date,
    required this.createdAt,
  });

  /// Create expense for Needs or Wants category.
  factory Expense.create({
    required double amount,
    required ExpenseCategory category,
    required ExpenseSubcategory subcategory,
    String? note,
    DateTime? date,
  }) {
    assert(category != ExpenseCategory.savings,
           'Use Expense.createSavings for savings category');
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

  /// Create expense for Savings category (goes to Emergency Fund or a Goal).
  factory Expense.createSavings({
    required double amount,
    required SavingsDestination destination,
    String? note,
    DateTime? date,
  }) {
    final now = DateTime.now();
    return Expense(
      id: now.millisecondsSinceEpoch.toString(),
      amount: amount,
      category: ExpenseCategory.savings,
      savingsDestination: destination,
      note: note,
      date: date ?? now,
      createdAt: now,
    );
  }

  /// Get display label for the subcategory or savings destination.
  String get destinationLabel {
    if (category == ExpenseCategory.savings) {
      return savingsDestination?.label ?? 'Savings';
    }
    return subcategory?.label ?? category.label;
  }
}
