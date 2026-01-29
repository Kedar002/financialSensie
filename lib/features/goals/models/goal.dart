/// Goal timeline categories based on target date.
enum GoalTimeline {
  shortTerm, // < 1 year
  midTerm, // 1-5 years
  longTerm, // > 5 years
}

/// Savings instruments for different goal timelines.
enum SavingsInstrument {
  // Short-term (< 1 year)
  savingsAccount,
  piggyBank,
  fixedDeposit,

  // Mid-term (1-5 years)
  mutualFunds,
  certificateOfDeposit,
  recurringDeposit,

  // Long-term (> 5 years)
  stocks,
  bonds,
  indexFunds,

  // Custom
  custom,
}

extension GoalTimelineExtension on GoalTimeline {
  String get label {
    switch (this) {
      case GoalTimeline.shortTerm:
        return 'Short-term';
      case GoalTimeline.midTerm:
        return 'Mid-term';
      case GoalTimeline.longTerm:
        return 'Long-term';
    }
  }

  String get description {
    switch (this) {
      case GoalTimeline.shortTerm:
        return 'Less than 1 year';
      case GoalTimeline.midTerm:
        return '1 to 5 years';
      case GoalTimeline.longTerm:
        return 'More than 5 years';
    }
  }

  List<SavingsInstrument> get suggestedInstruments {
    switch (this) {
      case GoalTimeline.shortTerm:
        return [
          SavingsInstrument.savingsAccount,
          SavingsInstrument.piggyBank,
          SavingsInstrument.fixedDeposit,
        ];
      case GoalTimeline.midTerm:
        return [
          SavingsInstrument.mutualFunds,
          SavingsInstrument.certificateOfDeposit,
          SavingsInstrument.recurringDeposit,
        ];
      case GoalTimeline.longTerm:
        return [
          SavingsInstrument.stocks,
          SavingsInstrument.indexFunds,
          SavingsInstrument.bonds,
        ];
    }
  }

  static GoalTimeline fromTargetDate(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final years = difference.inDays / 365;

    if (years < 1) {
      return GoalTimeline.shortTerm;
    } else if (years <= 5) {
      return GoalTimeline.midTerm;
    } else {
      return GoalTimeline.longTerm;
    }
  }
}

extension SavingsInstrumentExtension on SavingsInstrument {
  String get label {
    switch (this) {
      case SavingsInstrument.savingsAccount:
        return 'Savings Account';
      case SavingsInstrument.piggyBank:
        return 'Piggy Bank';
      case SavingsInstrument.fixedDeposit:
        return 'Fixed Deposit';
      case SavingsInstrument.mutualFunds:
        return 'Mutual Funds';
      case SavingsInstrument.certificateOfDeposit:
        return 'Certificate of Deposit';
      case SavingsInstrument.recurringDeposit:
        return 'Recurring Deposit';
      case SavingsInstrument.stocks:
        return 'Stocks';
      case SavingsInstrument.bonds:
        return 'Bonds';
      case SavingsInstrument.indexFunds:
        return 'Index Funds';
      case SavingsInstrument.custom:
        return 'Custom';
    }
  }

  String get shortLabel {
    switch (this) {
      case SavingsInstrument.savingsAccount:
        return 'Bank';
      case SavingsInstrument.piggyBank:
        return 'Piggy Bank';
      case SavingsInstrument.fixedDeposit:
        return 'FD';
      case SavingsInstrument.mutualFunds:
        return 'MF';
      case SavingsInstrument.certificateOfDeposit:
        return 'CD';
      case SavingsInstrument.recurringDeposit:
        return 'RD';
      case SavingsInstrument.stocks:
        return 'Stocks';
      case SavingsInstrument.bonds:
        return 'Bonds';
      case SavingsInstrument.indexFunds:
        return 'Index Funds';
      case SavingsInstrument.custom:
        return 'Custom';
    }
  }
}

/// Goal model with timeline categorization.
class Goal {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final SavingsInstrument instrument;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.targetDate,
    required this.instrument,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  GoalTimeline get timeline => GoalTimelineExtension.fromTargetDate(targetDate);

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;

  double get remaining => (targetAmount - currentAmount).clamp(0, double.infinity);

  bool get isCompleted => currentAmount >= targetAmount;

  /// Calculate monthly savings needed to reach goal.
  double get monthlySavingsNeeded {
    if (isCompleted) return 0;
    final now = DateTime.now();
    final monthsLeft = (targetDate.difference(now).inDays / 30).ceil();
    if (monthsLeft <= 0) return remaining;
    return remaining / monthsLeft;
  }

  Goal copyWith({
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    SavingsInstrument? instrument,
  }) {
    return Goal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      instrument: instrument ?? this.instrument,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate.toIso8601String(),
      'instrument': instrument.index,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: map['targetAmount'] as double,
      currentAmount: (map['currentAmount'] as double?) ?? 0,
      targetDate: DateTime.parse(map['targetDate'] as String),
      instrument: SavingsInstrument.values[map['instrument'] as int],
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  factory Goal.create({
    required String name,
    required double targetAmount,
    required DateTime targetDate,
    required SavingsInstrument instrument,
  }) {
    return Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      targetAmount: targetAmount,
      targetDate: targetDate,
      instrument: instrument,
    );
  }
}
