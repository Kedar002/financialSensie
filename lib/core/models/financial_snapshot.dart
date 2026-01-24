class FinancialSnapshot {
  final int? id;
  final int userId;
  final String month;
  final double totalIncome;
  final double totalFixedExpenses;
  final double totalVariableExpenses;
  final double totalSavings;
  final double safeToSpendBudget;
  final double actualSpent;
  final double emergencyFundBalance;
  final int createdAt;

  const FinancialSnapshot({
    this.id,
    required this.userId,
    required this.month,
    required this.totalIncome,
    required this.totalFixedExpenses,
    required this.totalVariableExpenses,
    required this.totalSavings,
    required this.safeToSpendBudget,
    this.actualSpent = 0,
    required this.emergencyFundBalance,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'total_income': totalIncome,
      'total_fixed_expenses': totalFixedExpenses,
      'total_variable_expenses': totalVariableExpenses,
      'total_savings': totalSavings,
      'safe_to_spend_budget': safeToSpendBudget,
      'actual_spent': actualSpent,
      'emergency_fund_balance': emergencyFundBalance,
      'created_at': createdAt,
    };
  }

  factory FinancialSnapshot.fromMap(Map<String, dynamic> map) {
    return FinancialSnapshot(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      month: map['month'] as String,
      totalIncome: (map['total_income'] as num).toDouble(),
      totalFixedExpenses: (map['total_fixed_expenses'] as num).toDouble(),
      totalVariableExpenses: (map['total_variable_expenses'] as num).toDouble(),
      totalSavings: (map['total_savings'] as num).toDouble(),
      safeToSpendBudget: (map['safe_to_spend_budget'] as num).toDouble(),
      actualSpent: (map['actual_spent'] as num).toDouble(),
      emergencyFundBalance: (map['emergency_fund_balance'] as num).toDouble(),
      createdAt: map['created_at'] as int,
    );
  }

  FinancialSnapshot copyWith({
    int? id,
    int? userId,
    String? month,
    double? totalIncome,
    double? totalFixedExpenses,
    double? totalVariableExpenses,
    double? totalSavings,
    double? safeToSpendBudget,
    double? actualSpent,
    double? emergencyFundBalance,
    int? createdAt,
  }) {
    return FinancialSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      totalIncome: totalIncome ?? this.totalIncome,
      totalFixedExpenses: totalFixedExpenses ?? this.totalFixedExpenses,
      totalVariableExpenses:
          totalVariableExpenses ?? this.totalVariableExpenses,
      totalSavings: totalSavings ?? this.totalSavings,
      safeToSpendBudget: safeToSpendBudget ?? this.safeToSpendBudget,
      actualSpent: actualSpent ?? this.actualSpent,
      emergencyFundBalance: emergencyFundBalance ?? this.emergencyFundBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get totalExpenses => totalFixedExpenses + totalVariableExpenses;

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (totalSavings / totalIncome * 100);
  }

  double get budgetVariance => safeToSpendBudget - actualSpent;

  bool get underBudget => actualSpent <= safeToSpendBudget;
}
