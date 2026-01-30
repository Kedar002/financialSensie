import 'package:flutter/material.dart';
import '../../../core/database/database.dart';
import '../../../core/models/cycle_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../onboarding/screens/income_setup_screen.dart';
import '../../onboarding/screens/expenses_setup_screen.dart';
import '../../onboarding/screens/variable_budget_setup_screen.dart';
import '../../onboarding/screens/savings_setup_screen.dart';
import '../../plan/screens/financial_plan_screen.dart';
import '../../learn/screens/learn_screen.dart';
import 'cycle_settings_screen.dart';
import 'knowledge_screen.dart';

/// Profile screen - Your financial setup.
/// Five settings. One link. Nothing more.
/// Steve Jobs would approve.
class ProfileScreen extends StatefulWidget {
  final VoidCallback? onDataReset;

  const ProfileScreen({super.key, this.onDataReset});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SettingsRepository _settingsRepo = SettingsRepository();

  // Loaded from database
  int _income = 0;
  int _fixedExpenses = 0;
  int _variableBudget = 0;
  int _savings = 0;
  CycleSettings _cycleSettings = CycleSettings.defaultSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final income = await _settingsRepo.getMonthlyIncome();
    final fixedExpenses = await _settingsRepo.getTotalFixedExpenses();
    final wantsPercent = await _settingsRepo.getWantsPercent();
    final savingsPercent = await _settingsRepo.getSavingsPercent();
    final cycleType = await _settingsRepo.getCycleType();
    final cycleStartDay = await _settingsRepo.getCycleStartDay();

    // Calculate budgets from percentages
    final afterFixed = income - fixedExpenses;
    final variableBudget = (afterFixed * wantsPercent / 100).round();
    final savings = (afterFixed * savingsPercent / 100).round();

    if (mounted) {
      setState(() {
        _income = income;
        _fixedExpenses = fixedExpenses;
        _variableBudget = variableBudget;
        _savings = savings;
        _cycleSettings = cycleType == 'custom'
            ? CycleSettings.customDay(cycleStartDay)
            : CycleSettings.calendarMonth();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'You',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacing24),
            _buildFinancialPlanCard(context),
            const SizedBox(height: AppTheme.spacing32),
            _isLoading ? _buildLoadingSection() : _buildSetupSection(context),
            const SizedBox(height: AppTheme.spacing48),
            _buildLearnSection(context),
            const SizedBox(height: AppTheme.spacing48),
            _buildDangerZone(context),
            const SizedBox(height: AppTheme.spacing64),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing24),
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.black,
        ),
      ),
    );
  }

  Widget _buildFinancialPlanCard(BuildContext context) {
    return AppCard(
      onTap: () => _openFinancialPlan(context),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.black,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.trending_up,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Plan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  '10 steps to financial freedom',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.gray500,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppTheme.gray400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingRow(
          context,
          label: 'Income',
          value: Formatters.currency(AmountConverter.toRupees(_income)),
          onTap: () => _editIncome(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Fixed Expenses',
          value: Formatters.currency(AmountConverter.toRupees(_fixedExpenses)),
          onTap: () => _editExpenses(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Variable Budget',
          value: Formatters.currency(AmountConverter.toRupees(_variableBudget)),
          onTap: () => _editVariableBudget(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Savings',
          value: Formatters.currency(AmountConverter.toRupees(_savings)),
          onTap: () => _editSavings(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Budget Cycle',
          value: _cycleSettings.displayLabel,
          onTap: () => _editCycle(context),
        ),
      ],
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Row(
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.gray600,
                      ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.gray400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      color: AppTheme.gray200,
    );
  }

  Widget _buildLearnSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Learn',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing8),
        GestureDetector(
          onTap: () => _openLearn(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Literacy',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '10 lessons to master personal finance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray500,
                          ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        _buildDivider(),
        GestureDetector(
          onTap: () => _openKnowledge(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'Learn the logic behind the numbers',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray500,
                          ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.gray400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danger Zone',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        GestureDetector(
          onTap: () => _confirmResetData(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray300),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: AppTheme.gray600,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reset All Data',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: AppTheme.spacing4),
                      Text(
                        'Delete all expenses, goals, and settings',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.gray500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmResetData(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMedium * 2),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reset All Data?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing12),
            Text(
              'This will permanently delete all your expenses, goals, emergency fund, debts, and reset all settings to default. This action cannot be undone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.gray600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacing24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.black,
                    ),
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _resetAllData();
    }
  }

  Future<void> _resetAllData() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.white,
        ),
      ),
    );

    try {
      // Delete and recreate database
      await DatabaseService().deleteDatabase();
      await DatabaseService().database;

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Notify parent to reset state
        widget.onDataReset?.call();

        // Reload settings
        await _loadSettings();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data has been reset'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset data: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openLearn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LearnScreen(),
      ),
    );
  }

  Future<void> _editIncome(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const IncomeSetupScreen(isEditing: true),
      ),
    );
    _loadSettings(); // Reload after edit
  }

  Future<void> _editExpenses(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExpensesSetupScreen(isEditing: true),
      ),
    );
    _loadSettings();
  }

  Future<void> _editVariableBudget(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VariableBudgetSetupScreen(isEditing: true),
      ),
    );
    _loadSettings();
  }

  Future<void> _editSavings(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SavingsSetupScreen(isEditing: true),
      ),
    );
    _loadSettings();
  }

  Future<void> _editCycle(BuildContext context) async {
    final newSettings = await Navigator.of(context).push<CycleSettings>(
      MaterialPageRoute(
        builder: (_) => CycleSettingsScreen(currentSettings: _cycleSettings),
      ),
    );

    if (newSettings != null) {
      // Save to database
      await _settingsRepo.setCycleType(
        newSettings.type == CycleType.calendarMonth ? 'calendar' : 'custom',
      );
      await _settingsRepo.setCycleStartDay(newSettings.customStartDay);

      setState(() {
        _cycleSettings = newSettings;
      });
    }
  }

  void _openKnowledge(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const KnowledgeScreen(),
      ),
    );
  }

  void _openFinancialPlan(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FinancialPlanScreen(),
      ),
    );
  }
}
