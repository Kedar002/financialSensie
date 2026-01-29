import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../onboarding/screens/income_setup_screen.dart';
import '../../onboarding/screens/expenses_setup_screen.dart';
import '../../onboarding/screens/variable_budget_setup_screen.dart';
import '../../onboarding/screens/savings_setup_screen.dart';
import '../../onboarding/screens/welcome_screen.dart';

/// Profile screen - view and edit financial setup.
/// Shows income, expenses, and summary.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppTheme.spacing32),
            _buildSummaryCard(context),
            const SizedBox(height: AppTheme.spacing32),
            _buildSectionWithEdit(
              context,
              title: 'Income',
              onEdit: () => _editIncome(context),
            ),
            _buildPlaceholderItem(context, 'Salary', '\u20B950,000'),
            const SizedBox(height: AppTheme.spacing24),
            _buildSectionWithEdit(
              context,
              title: 'Fixed Expenses',
              onEdit: () => _editExpenses(context),
            ),
            _buildPlaceholderItem(context, 'Rent / EMI', '\u20B915,000'),
            _buildPlaceholderItem(context, 'Utilities', '\u20B93,000'),
            const SizedBox(height: AppTheme.spacing24),
            _buildSectionWithEdit(
              context,
              title: 'Variable Budget',
              onEdit: () => _editVariableBudget(context),
            ),
            _buildVariableBudgetInfo(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildSectionWithEdit(
              context,
              title: 'Savings Setup',
              onEdit: () => _editSavings(context),
            ),
            _buildSavingsInfo(context),
            const SizedBox(height: AppTheme.spacing48),
            _buildDangerZone(context),
            const SizedBox(height: AppTheme.spacing48),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    // Placeholder values
    const monthlyIncome = 50000.0;
    const fixedExpenses = 18000.0;
    const allocations = 7000.0;
    const safeToSpend = monthlyIncome - fixedExpenses - allocations;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        children: [
          _buildSummaryRow(context, 'Monthly Income', Formatters.currency(monthlyIncome)),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(context, 'Fixed Expenses', '- ${Formatters.currency(fixedExpenses)}'),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(context, 'Allocations', '- ${Formatters.currency(allocations)}'),
          const Divider(height: AppTheme.spacing32),
          _buildSummaryRow(context, 'Safe to Spend', Formatters.currency(safeToSpend), bold: true),
        ],
      ),
    );
  }

  Widget _buildSectionWithEdit(
    BuildContext context, {
    required String title,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          GestureDetector(
            onTap: onEdit,
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: bold
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildPlaceholderItem(BuildContext context, String name, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableBudgetInfo(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Variable Budget',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\u20B912,000',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '4',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsInfo(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Savings',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '\u20B97,000',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Savings Rate',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                '14%',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DANGER ZONE',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.gray500,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        OutlinedButton(
          onPressed: () => _confirmDeleteAllData(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB00020),
            side: const BorderSide(color: Color(0xFFB00020)),
          ),
          child: const Text('Delete All Data'),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'This will erase all your data and cannot be undone.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
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

  void _confirmDeleteAllData(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently erase all your financial data.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB00020),
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}
