import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/financial_plan.dart';
import 'debt_screen.dart';

/// Financial Plan - Your 10-step roadmap to financial freedom.
/// One screen. Complete overview. Tap any step to configure.
class FinancialPlanScreen extends StatefulWidget {
  const FinancialPlanScreen({super.key});

  @override
  State<FinancialPlanScreen> createState() => _FinancialPlanScreenState();
}

class _FinancialPlanScreenState extends State<FinancialPlanScreen> {
  // Placeholder values - will come from database
  final double _income = 50000;
  final double _fixedExpenses = 18000;
  final double _variableBudget = 32000;
  final double _emergencyFundCurrent = 75000;
  final double _emergencyFundTarget = 200000;
  final int _goalsCount = 0;
  final List<Debt> _debts = [];

  double get _emergencyFundProgress =>
      _emergencyFundTarget > 0 ? (_emergencyFundCurrent / _emergencyFundTarget) * 100 : 0;

  int get _completedSteps {
    int count = 0;
    if (_income > 0) count++; // Step 1: Income
    count++; // Step 2: Budget rule (always 50-30-20)
    if (_fixedExpenses > 0) count++; // Step 3: Needs
    if (_variableBudget > 0) count++; // Step 4: Wants
    if (_goalsCount > 0) count++; // Step 5: Goals
    if (_emergencyFundProgress >= 100) count++; // Step 6: Emergency fund complete
    if (_debts.isEmpty || _debts.every((d) => d.isPaidOff)) count++; // Step 7: Debt free
    // Steps 8-10 are ongoing, count as complete if basics done
    if (_income > 0 && _emergencyFundProgress > 0) count++; // Step 8: Savings started
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(context),
                    const SizedBox(height: AppTheme.spacing32),
                    _buildStepsList(context),
                    const SizedBox(height: AppTheme.spacing64),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(
            'Financial Plan',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    final progress = (_completedSteps / 10) * 100;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.black,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '$_completedSteps/10',
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildProgressBar(progress),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            _getProgressMessage(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (progress / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  String _getProgressMessage() {
    if (_completedSteps <= 2) return 'Start by setting up your income and budget';
    if (_completedSteps <= 5) return 'Great start! Focus on your emergency fund next';
    if (_completedSteps <= 7) return 'Almost there! Keep building your safety net';
    return 'Excellent! You\'re on track to financial freedom';
  }

  Widget _buildStepsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The 10 Steps',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Follow these in order for best results',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing24),
        ...PlanStep.values.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: _buildStepCard(context, step),
            )),
      ],
    );
  }

  Widget _buildStepCard(BuildContext context, PlanStep step) {
    final status = _getStepStatus(step);
    final statusColor = _getStatusColor(status);

    return AppCard(
      onTap: () => _onStepTap(context, step),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: status == _StepStatus.complete ? AppTheme.black : AppTheme.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: status == _StepStatus.complete
                  ? const Icon(Icons.check, size: 16, color: AppTheme.white)
                  : Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: status == _StepStatus.current
                            ? AppTheme.black
                            : AppTheme.gray400,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  _getStepValue(step) ?? step.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTheme.spacing8),
          Icon(
            Icons.chevron_right,
            size: 20,
            color: AppTheme.gray300,
          ),
        ],
      ),
    );
  }

  _StepStatus _getStepStatus(PlanStep step) {
    switch (step) {
      case PlanStep.income:
        return _income > 0 ? _StepStatus.complete : _StepStatus.current;
      case PlanStep.budgetRule:
        return _StepStatus.complete; // Always using 50-30-20
      case PlanStep.needs:
        return _fixedExpenses > 0 ? _StepStatus.complete : _StepStatus.pending;
      case PlanStep.wants:
        return _variableBudget > 0 ? _StepStatus.complete : _StepStatus.pending;
      case PlanStep.goals:
        return _goalsCount > 0 ? _StepStatus.complete : _StepStatus.pending;
      case PlanStep.emergencyFund:
        if (_emergencyFundProgress >= 100) return _StepStatus.complete;
        if (_emergencyFundProgress > 0) return _StepStatus.current;
        return _StepStatus.pending;
      case PlanStep.debt:
        if (_debts.isEmpty) return _StepStatus.complete;
        if (_debts.every((d) => d.isPaidOff)) return _StepStatus.complete;
        return _StepStatus.current;
      case PlanStep.savings:
        return _emergencyFundProgress > 0 ? _StepStatus.current : _StepStatus.pending;
      case PlanStep.automate:
        return _StepStatus.pending; // User decides
      case PlanStep.review:
        return _StepStatus.pending; // Ongoing
    }
  }

  Color _getStatusColor(_StepStatus status) {
    switch (status) {
      case _StepStatus.complete:
        return AppTheme.black;
      case _StepStatus.current:
        return AppTheme.gray600;
      case _StepStatus.pending:
        return AppTheme.gray400;
    }
  }

  String? _getStepValue(PlanStep step) {
    switch (step) {
      case PlanStep.income:
        return _income > 0 ? '₹${_income.toStringAsFixed(0)}/month' : null;
      case PlanStep.budgetRule:
        return '50% Needs · 30% Wants · 20% Savings';
      case PlanStep.needs:
        return _fixedExpenses > 0 ? '₹${_fixedExpenses.toStringAsFixed(0)}/month' : null;
      case PlanStep.wants:
        return _variableBudget > 0 ? '₹${(_variableBudget * 0.3 / 0.5).toStringAsFixed(0)}/month' : null;
      case PlanStep.goals:
        return _goalsCount > 0 ? '$_goalsCount goals set' : null;
      case PlanStep.emergencyFund:
        return '${_emergencyFundProgress.toStringAsFixed(0)}% complete';
      case PlanStep.debt:
        if (_debts.isEmpty) return 'No debt - great!';
        return '${_debts.length} ${_debts.length == 1 ? 'debt' : 'debts'} to pay';
      case PlanStep.savings:
        return '20% of income';
      case PlanStep.automate:
        return null;
      case PlanStep.review:
        return null;
    }
  }

  void _onStepTap(BuildContext context, PlanStep step) {
    switch (step) {
      case PlanStep.debt:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DebtScreen(debts: _debts),
          ),
        );
        break;
      default:
        // Show info bottom sheet for steps that link to other screens
        _showStepInfo(context, step);
    }
  }

  void _showStepInfo(BuildContext context, PlanStep step) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    child: Text(
                      step.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                _getStepExplanation(step),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              _buildStepAction(context, step),
            ],
          ),
        ),
      ),
    );
  }

  String _getStepExplanation(PlanStep step) {
    switch (step) {
      case PlanStep.income:
        return 'Your monthly take-home salary is the foundation of your plan. Only count guaranteed income - no bonuses or side income yet.';
      case PlanStep.budgetRule:
        return 'The 50-30-20 rule splits your income into three buckets: 50% for needs (essentials), 30% for wants (lifestyle), and 20% for savings and debt payments.';
      case PlanStep.needs:
        return 'These are non-negotiable expenses that exist even if you lose your job: rent, utilities, groceries, transport, insurance.';
      case PlanStep.wants:
        return 'These make life enjoyable but are adjustable: eating out, shopping, subscriptions, travel, entertainment.';
      case PlanStep.goals:
        return 'Set SMART goals: Specific, Measurable, and Time-bound. Create short-term (0-1 year), medium-term (1-5 years), and long-term (5+ years) goals.';
      case PlanStep.emergencyFund:
        return 'Build 3-6 months of needs in a savings account. This is non-negotiable - no investing before this is done.';
      case PlanStep.debt:
        return 'List all debts with interest rates. Pay high-interest debt first (credit cards), then medium, then low (home loans). Always pay more than minimum.';
      case PlanStep.savings:
        return 'After emergency fund is complete, split savings between skill upgrades, long-term investments, and retirement. Start small - consistency beats amount.';
      case PlanStep.automate:
        return 'Set up auto-debit for savings, auto-pay for bills, and auto-invest for SIPs. Automation removes the need for daily discipline.';
      case PlanStep.review:
        return 'Once a month: review spending, adjust goals, increase savings if income rises, and cut leaks like unused subscriptions.';
    }
  }

  Widget _buildStepAction(BuildContext context, PlanStep step) {
    String actionText;
    String? navigateTo;

    switch (step) {
      case PlanStep.income:
        actionText = 'Edit in Profile';
        navigateTo = 'profile';
        break;
      case PlanStep.budgetRule:
        actionText = 'View Monthly Budget';
        navigateTo = 'budget';
        break;
      case PlanStep.needs:
        actionText = 'Edit Fixed Expenses';
        navigateTo = 'profile';
        break;
      case PlanStep.wants:
        actionText = 'Edit Variable Budget';
        navigateTo = 'profile';
        break;
      case PlanStep.goals:
        actionText = 'Go to Goals';
        navigateTo = 'goals';
        break;
      case PlanStep.emergencyFund:
        actionText = 'Go to Safety';
        navigateTo = 'safety';
        break;
      case PlanStep.debt:
        actionText = 'Manage Debts';
        navigateTo = 'debt';
        break;
      case PlanStep.savings:
        actionText = 'View Allocation';
        navigateTo = 'budget';
        break;
      case PlanStep.automate:
        actionText = 'Got it';
        navigateTo = null;
        break;
      case PlanStep.review:
        actionText = 'Got it';
        navigateTo = null;
        break;
    }

    return ElevatedButton(
      onPressed: () {
        Navigator.pop(context);
        if (navigateTo != null) {
          // Navigate based on step
          // For now, just close the sheet
        }
      },
      child: Text(actionText),
    );
  }
}

enum _StepStatus {
  complete,
  current,
  pending,
}
