import 'package:flutter/material.dart';
import '../../../core/models/cycle_settings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../onboarding/screens/income_setup_screen.dart';
import '../../onboarding/screens/expenses_setup_screen.dart';
import '../../onboarding/screens/variable_budget_setup_screen.dart';
import '../../onboarding/screens/savings_setup_screen.dart';
import 'cycle_settings_screen.dart';
import 'knowledge_screen.dart';

/// Profile screen - Your financial setup.
/// Five settings. One link. Nothing more.
/// Steve Jobs would approve.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // In-memory settings (will connect to database later)
  CycleSettings _cycleSettings = CycleSettings.defaultSettings;

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
            const SizedBox(height: AppTheme.spacing32),
            _buildSetupSection(context),
            const SizedBox(height: AppTheme.spacing48),
            _buildLearnSection(context),
            const SizedBox(height: AppTheme.spacing64),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupSection(BuildContext context) {
    // Placeholder values - will connect to database
    const income = 50000.0;
    const fixedExpenses = 18000.0;
    const variableBudget = 25000.0;
    const savings = 7000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSettingRow(
          context,
          label: 'Income',
          value: Formatters.currency(income),
          onTap: () => _editIncome(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Fixed Expenses',
          value: Formatters.currency(fixedExpenses),
          onTap: () => _editExpenses(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Variable Budget',
          value: Formatters.currency(variableBudget),
          onTap: () => _editVariableBudget(context),
        ),
        _buildDivider(),
        _buildSettingRow(
          context,
          label: 'Savings',
          value: Formatters.currency(savings),
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

  void _editIncome(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const IncomeSetupScreen(isEditing: true),
      ),
    );
  }

  void _editExpenses(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExpensesSetupScreen(isEditing: true),
      ),
    );
  }

  void _editVariableBudget(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VariableBudgetSetupScreen(isEditing: true),
      ),
    );
  }

  void _editSavings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SavingsSetupScreen(isEditing: true),
      ),
    );
  }

  Future<void> _editCycle(BuildContext context) async {
    final newSettings = await Navigator.of(context).push<CycleSettings>(
      MaterialPageRoute(
        builder: (_) => CycleSettingsScreen(currentSettings: _cycleSettings),
      ),
    );

    if (newSettings != null) {
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
}
