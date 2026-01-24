/// Model to track monthly savings totals.
/// Tracks emergency fund, investments, goals, and total savings each month.
class SavingsTracker {
  final int? id;
  final int userId;
  final String month; // Format: YYYY-MM
  final double emergencyFundBalance;
  final double investmentTotal; // SIP and other investments
  final double goalsTotal; // Amount saved in goals
  final double completedGoalsTotal; // Value of completed goals
  final double totalSavings; // Sum of all savings
  final int recordedAt;

  const SavingsTracker({
    this.id,
    required this.userId,
    required this.month,
    required this.emergencyFundBalance,
    required this.investmentTotal,
    required this.goalsTotal,
    required this.completedGoalsTotal,
    required this.totalSavings,
    required this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'month': month,
      'emergency_fund_balance': emergencyFundBalance,
      'investment_total': investmentTotal,
      'goals_total': goalsTotal,
      'completed_goals_total': completedGoalsTotal,
      'total_savings': totalSavings,
      'recorded_at': recordedAt,
    };
  }

  factory SavingsTracker.fromMap(Map<String, dynamic> map) {
    return SavingsTracker(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      month: map['month'] as String,
      emergencyFundBalance: (map['emergency_fund_balance'] as num).toDouble(),
      investmentTotal: (map['investment_total'] as num).toDouble(),
      goalsTotal: (map['goals_total'] as num).toDouble(),
      completedGoalsTotal: (map['completed_goals_total'] as num).toDouble(),
      totalSavings: (map['total_savings'] as num).toDouble(),
      recordedAt: map['recorded_at'] as int,
    );
  }

  SavingsTracker copyWith({
    int? id,
    int? userId,
    String? month,
    double? emergencyFundBalance,
    double? investmentTotal,
    double? goalsTotal,
    double? completedGoalsTotal,
    double? totalSavings,
    int? recordedAt,
  }) {
    return SavingsTracker(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      month: month ?? this.month,
      emergencyFundBalance: emergencyFundBalance ?? this.emergencyFundBalance,
      investmentTotal: investmentTotal ?? this.investmentTotal,
      goalsTotal: goalsTotal ?? this.goalsTotal,
      completedGoalsTotal: completedGoalsTotal ?? this.completedGoalsTotal,
      totalSavings: totalSavings ?? this.totalSavings,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// Get formatted month display (e.g., "January 2025")
  String get monthDisplay {
    try {
      final parts = month.split('-');
      final year = int.parse(parts[0]);
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

  /// Get short month display (e.g., "Jan 2025")
  String get shortMonthDisplay {
    try {
      final parts = month.split('-');
      final year = int.parse(parts[0]);
      final monthNum = int.parse(parts[1]);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[monthNum - 1]} $year';
    } catch (_) {
      return month;
    }
  }
}
