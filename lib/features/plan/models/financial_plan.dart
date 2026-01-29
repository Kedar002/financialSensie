/// Debt entry for tracking what you owe.
class Debt {
  final String id;
  final String name;
  final double totalAmount;
  final double remainingAmount;
  final double interestRate;
  final double minimumPayment;
  final DebtPriority priority;
  final DateTime createdAt;

  const Debt({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.minimumPayment,
    required this.priority,
    required this.createdAt,
  });

  factory Debt.create({
    required String name,
    required double totalAmount,
    required double interestRate,
    required double minimumPayment,
  }) {
    final now = DateTime.now();
    return Debt(
      id: now.millisecondsSinceEpoch.toString(),
      name: name,
      totalAmount: totalAmount,
      remainingAmount: totalAmount,
      interestRate: interestRate,
      minimumPayment: minimumPayment,
      priority: DebtPriority.fromInterestRate(interestRate),
      createdAt: now,
    );
  }

  double get paidAmount => totalAmount - remainingAmount;
  double get progress => totalAmount > 0 ? (paidAmount / totalAmount) * 100 : 0;
  bool get isPaidOff => remainingAmount <= 0;

  Debt copyWith({
    String? name,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    double? minimumPayment,
    DebtPriority? priority,
  }) {
    return Debt(
      id: id,
      name: name ?? this.name,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      priority: priority ?? this.priority,
      createdAt: createdAt,
    );
  }
}

/// Debt priority based on interest rate.
enum DebtPriority {
  high,    // > 15% (credit cards, personal loans)
  medium,  // 8-15% (car loans, some personal loans)
  low;     // < 8% (home loans, education loans)

  String get label {
    switch (this) {
      case DebtPriority.high:
        return 'High Priority';
      case DebtPriority.medium:
        return 'Medium Priority';
      case DebtPriority.low:
        return 'Low Priority';
    }
  }

  String get description {
    switch (this) {
      case DebtPriority.high:
        return 'Pay this first (>15% interest)';
      case DebtPriority.medium:
        return 'Pay after high priority (8-15%)';
      case DebtPriority.low:
        return 'Maintain minimum payments (<8%)';
    }
  }

  static DebtPriority fromInterestRate(double rate) {
    if (rate > 15) return DebtPriority.high;
    if (rate >= 8) return DebtPriority.medium;
    return DebtPriority.low;
  }
}

/// The 10 steps of a financial plan.
enum PlanStep {
  income,
  budgetRule,
  needs,
  wants,
  goals,
  emergencyFund,
  debt,
  savings,
  automate,
  review;

  String get title {
    switch (this) {
      case PlanStep.income:
        return 'Know Your Income';
      case PlanStep.budgetRule:
        return 'Budget Rule';
      case PlanStep.needs:
        return 'Fixed Needs';
      case PlanStep.wants:
        return 'Lifestyle Wants';
      case PlanStep.goals:
        return 'Set Goals';
      case PlanStep.emergencyFund:
        return 'Emergency Fund';
      case PlanStep.debt:
        return 'Handle Debt';
      case PlanStep.savings:
        return 'Save & Invest';
      case PlanStep.automate:
        return 'Automate';
      case PlanStep.review:
        return 'Monthly Review';
    }
  }

  String get subtitle {
    switch (this) {
      case PlanStep.income:
        return 'Your monthly take-home';
      case PlanStep.budgetRule:
        return '50-30-20 allocation';
      case PlanStep.needs:
        return 'Non-negotiable expenses';
      case PlanStep.wants:
        return 'Lifestyle spending';
      case PlanStep.goals:
        return 'Short, mid & long-term';
      case PlanStep.emergencyFund:
        return '3-6 months of needs';
      case PlanStep.debt:
        return 'Pay high-interest first';
      case PlanStep.savings:
        return 'Build your future';
      case PlanStep.automate:
        return 'Remove discipline problems';
      case PlanStep.review:
        return 'Track & adjust monthly';
    }
  }

  int get stepNumber => index + 1;
}

/// Budget allocation rule.
enum BudgetRule {
  rule503020;  // The classic 50-30-20

  String get label {
    switch (this) {
      case BudgetRule.rule503020:
        return '50-30-20';
    }
  }

  String get description {
    switch (this) {
      case BudgetRule.rule503020:
        return '50% Needs · 30% Wants · 20% Savings';
    }
  }

  double get needsPercent {
    switch (this) {
      case BudgetRule.rule503020:
        return 0.50;
    }
  }

  double get wantsPercent {
    switch (this) {
      case BudgetRule.rule503020:
        return 0.30;
    }
  }

  double get savingsPercent {
    switch (this) {
      case BudgetRule.rule503020:
        return 0.20;
    }
  }
}
