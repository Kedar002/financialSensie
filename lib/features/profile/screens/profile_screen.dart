import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/income_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/services/financial_calculation_service.dart';
import '../../../core/models/income_source.dart';
import '../../../core/models/fixed_expense.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../onboarding/screens/income_setup_screen.dart';
import '../../onboarding/screens/expenses_setup_screen.dart';
import '../../onboarding/screens/savings_setup_screen.dart';
import '../../onboarding/screens/welcome_screen.dart';

/// Profile screen - view and edit financial setup.
/// Shows income, expenses, and summary.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepo = UserRepository();
  final _incomeRepo = IncomeRepository();
  final _fixedExpenseRepo = FixedExpenseRepository();
  final _calcService = FinancialCalculationService();
  final _dbService = DatabaseService();

  int? _userId;
  List<IncomeSource> _incomes = [];
  List<FixedExpense> _expenses = [];
  FinancialSummary? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        _userId = user.id;
        _incomes = await _incomeRepo.getByUserId(user.id!);
        _expenses = await _fixedExpenseRepo.getByUserId(user.id!);
        _summary = await _calcService.getSummary(user.id!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.black),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.black,
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
              _buildSummaryCard(),
              const SizedBox(height: AppTheme.spacing32),
              _buildSectionWithEdit(
                title: 'Income',
                onEdit: _editIncome,
              ),
              ..._incomes.map(_buildIncomeItem),
              if (_incomes.isEmpty) _buildEmptyItem('No income added'),
              const SizedBox(height: AppTheme.spacing24),
              _buildSectionWithEdit(
                title: 'Fixed Expenses',
                onEdit: _editExpenses,
              ),
              ..._expenses.map(_buildExpenseItem),
              if (_expenses.isEmpty) _buildEmptyItem('No expenses added'),
              const SizedBox(height: AppTheme.spacing24),
              _buildSectionWithEdit(
                title: 'Savings Setup',
                onEdit: _editSavings,
              ),
              _buildSavingsInfo(),
              const SizedBox(height: AppTheme.spacing48),
              _buildDangerZone(),
              const SizedBox(height: AppTheme.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        children: [
          _buildSummaryRow(
            'Monthly Income',
            Formatters.currency(_summary?.monthlyIncome ?? 0),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(
            'Fixed Expenses',
            '- ${Formatters.currency(_summary?.fixedExpenses ?? 0)}',
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(
            'Allocations',
            '- ${Formatters.currency(_summary?.allocations ?? 0)}',
          ),
          const Divider(height: AppTheme.spacing32),
          _buildSummaryRow(
            'Safe to Spend',
            Formatters.currency(_summary?.safeToSpendBudget ?? 0),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithEdit({
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

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
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

  Widget _buildIncomeItem(IncomeSource income) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  income.frequency,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Text(
              Formatters.currency(income.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(FixedExpense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  expense.category,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Text(
              Formatters.currency(expense.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsInfo() {
    final allocations = _summary?.allocations ?? 0;
    final savingsRate = _summary?.savingsRate ?? 0;

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
                Formatters.currency(allocations),
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
                '${savingsRate.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItem(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDangerZone() {
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
          onPressed: _confirmDeleteAllData,
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

  void _editIncome() async {
    if (_userId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IncomeSetupScreen(
          userId: _userId!,
          isEditing: true,
        ),
      ),
    );
    _loadData();
  }

  void _editExpenses() async {
    if (_userId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpensesSetupScreen(
          userId: _userId!,
          isEditing: true,
        ),
      ),
    );
    _loadData();
  }

  void _editSavings() async {
    if (_userId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SavingsSetupScreen(
          userId: _userId!,
          isEditing: true,
        ),
      ),
    );
    _loadData();
  }

  void _confirmDeleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently erase all your financial data including:\n\n'
          '• Income sources\n'
          '• Expenses\n'
          '• Goals\n'
          '• Emergency fund\n'
          '• Transaction history\n\n'
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

    if (confirm == true) {
      await _deleteAllData();
    }
  }

  Future<void> _deleteAllData() async {
    setState(() => _isLoading = true);

    try {
      await _dbService.deleteAllData();

      if (mounted) {
        // Navigate to welcome screen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting data: $e')),
        );
      }
    }
  }
}
