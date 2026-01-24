import 'dart:convert';

class FinancialSnapshot {
  final int? id;
  final int userId;
  final String month; // Format: "YYYY-MM"
  final double totalIncome;
  final double totalFixedExpenses;
  final double totalVariableExpenses;
  final double totalSavings;
  final double safeToSpendBudget;
  final double actualSpent;
  final double emergencyFundBalance;
  final double emergencyFundTarget;
  final double needsPercent;
  final double wantsPercent;
  final double savingsPercent;
  final double safeToSpendPercent;
  final String? incomeBreakdown; // JSON array
  final String? needsBreakdown; // JSON array
  final String? wantsBreakdown; // JSON array
  final String? savingsBreakdown; // JSON array
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
    this.emergencyFundTarget = 0,
    this.needsPercent = 0,
    this.wantsPercent = 0,
    this.savingsPercent = 0,
    this.safeToSpendPercent = 0,
    this.incomeBreakdown,
    this.needsBreakdown,
    this.wantsBreakdown,
    this.savingsBreakdown,
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
      'emergency_fund_target': emergencyFundTarget,
      'needs_percent': needsPercent,
      'wants_percent': wantsPercent,
      'savings_percent': savingsPercent,
      'safe_to_spend_percent': safeToSpendPercent,
      'income_breakdown': incomeBreakdown,
      'needs_breakdown': needsBreakdown,
      'wants_breakdown': wantsBreakdown,
      'savings_breakdown': savingsBreakdown,
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
      actualSpent: (map['actual_spent'] as num?)?.toDouble() ?? 0,
      emergencyFundBalance: (map['emergency_fund_balance'] as num).toDouble(),
      emergencyFundTarget: (map['emergency_fund_target'] as num?)?.toDouble() ?? 0,
      needsPercent: (map['needs_percent'] as num?)?.toDouble() ?? 0,
      wantsPercent: (map['wants_percent'] as num?)?.toDouble() ?? 0,
      savingsPercent: (map['savings_percent'] as num?)?.toDouble() ?? 0,
      safeToSpendPercent: (map['safe_to_spend_percent'] as num?)?.toDouble() ?? 0,
      incomeBreakdown: map['income_breakdown'] as String?,
      needsBreakdown: map['needs_breakdown'] as String?,
      wantsBreakdown: map['wants_breakdown'] as String?,
      savingsBreakdown: map['savings_breakdown'] as String?,
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
    double? emergencyFundTarget,
    double? needsPercent,
    double? wantsPercent,
    double? savingsPercent,
    double? safeToSpendPercent,
    String? incomeBreakdown,
    String? needsBreakdown,
    String? wantsBreakdown,
    String? savingsBreakdown,
    int? createdAt,
  }) {
    return FinancialSnapshot(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      totalIncome: totalIncome ?? this.totalIncome,
      totalFixedExpenses: totalFixedExpenses ?? this.totalFixedExpenses,
      totalVariableExpenses: totalVariableExpenses ?? this.totalVariableExpenses,
      totalSavings: totalSavings ?? this.totalSavings,
      safeToSpendBudget: safeToSpendBudget ?? this.safeToSpendBudget,
      actualSpent: actualSpent ?? this.actualSpent,
      emergencyFundBalance: emergencyFundBalance ?? this.emergencyFundBalance,
      emergencyFundTarget: emergencyFundTarget ?? this.emergencyFundTarget,
      needsPercent: needsPercent ?? this.needsPercent,
      wantsPercent: wantsPercent ?? this.wantsPercent,
      savingsPercent: savingsPercent ?? this.savingsPercent,
      safeToSpendPercent: safeToSpendPercent ?? this.safeToSpendPercent,
      incomeBreakdown: incomeBreakdown ?? this.incomeBreakdown,
      needsBreakdown: needsBreakdown ?? this.needsBreakdown,
      wantsBreakdown: wantsBreakdown ?? this.wantsBreakdown,
      savingsBreakdown: savingsBreakdown ?? this.savingsBreakdown,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Computed properties
  double get totalExpenses => totalFixedExpenses + totalVariableExpenses;
  double get totalNeeds => totalFixedExpenses; // Essential fixed + variable
  double get totalWants => totalVariableExpenses; // Non-essential

  double get savingsRate {
    if (totalIncome == 0) return 0;
    return (totalSavings / totalIncome * 100);
  }

  double get budgetVariance => safeToSpendBudget - actualSpent;
  bool get underBudget => actualSpent <= safeToSpendBudget;

  double get emergencyFundRunway {
    if (totalExpenses == 0) return 0;
    return emergencyFundBalance / (totalExpenses > 0 ? totalExpenses : 1);
  }

  // Parse breakdown JSON
  List<Map<String, dynamic>> get incomeList {
    if (incomeBreakdown == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(incomeBreakdown!));
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get needsList {
    if (needsBreakdown == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(needsBreakdown!));
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get wantsList {
    if (wantsBreakdown == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(wantsBreakdown!));
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> get savingsList {
    if (savingsBreakdown == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(savingsBreakdown!));
    } catch (_) {
      return [];
    }
  }

  // Display helpers
  String get monthDisplay {
    try {
      final parts = month.split('-');
      final year = parts[0];
      final monthNum = int.parse(parts[1]);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[monthNum - 1]} $year';
    } catch (_) {
      return month;
    }
  }

  String get shortMonthDisplay {
    try {
      final parts = month.split('-');
      final year = parts[0].substring(2); // Last 2 digits
      final monthNum = int.parse(parts[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${months[monthNum - 1]} '$year";
    } catch (_) {
      return month;
    }
  }
}
