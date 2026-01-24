import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/database/database_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/income_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/services/financial_calculation_service.dart';
import '../../../core/models/income_source.dart';
import '../../../core/models/fixed_expense.dart';
import '../../../core/models/variable_expense.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../onboarding/screens/income_setup_screen.dart';
import '../../onboarding/screens/expenses_setup_screen.dart';
import '../../onboarding/screens/variable_budget_setup_screen.dart';
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
  final _variableExpenseRepo = VariableExpenseRepository();
  final _calcService = FinancialCalculationService();
  final _dbService = DatabaseService();

  int? _userId;
  int _salaryDay = 1;
  List<IncomeSource> _incomes = [];
  List<FixedExpense> _expenses = [];
  List<VariableExpense> _variableExpenses = [];
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
        _salaryDay = user.salaryDay;
        _incomes = await _incomeRepo.getByUserId(user.id!);
        _expenses = await _fixedExpenseRepo.getByUserId(user.id!);
        _variableExpenses = await _variableExpenseRepo.getByUserId(user.id!);
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
              _buildPaymentCycleSection(),
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
                title: 'Variable Budget',
                onEdit: _editVariableBudget,
              ),
              _buildVariableBudgetInfo(),
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

  Widget _buildPaymentCycleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Cycle',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            GestureDetector(
              onTap: _editSalaryDay,
              child: Text(
                'Edit',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        AppCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salary Day',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    'Budget resets on this day',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
              Text(
                _getOrdinal(_salaryDay),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getOrdinal(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
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
      child: GestureDetector(
        onTap: () => _showIncomeActions(income),
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
              Row(
                children: [
                  Text(
                    Formatters.currency(income.amount),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  const Icon(Icons.chevron_right, color: AppTheme.gray400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(FixedExpense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: GestureDetector(
        onTap: () => _showExpenseActions(expense),
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
              Row(
                children: [
                  Text(
                    Formatters.currency(expense.amount),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: AppTheme.spacing8),
                  const Icon(Icons.chevron_right, color: AppTheme.gray400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariableBudgetInfo() {
    if (_variableExpenses.isEmpty) {
      return _buildEmptyItem('No variable budget set');
    }

    final total = _variableExpenses.fold<double>(0.0, (sum, e) => sum + e.estimatedAmount);

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
                Formatters.currency(total),
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
                '${_variableExpenses.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ],
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

  void _showIncomeActions(IncomeSource income) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    income.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    Formatters.currency(income.amount),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editIncomeItem(income);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFB00020)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFB00020))),
              onTap: () {
                Navigator.pop(context);
                _deleteIncomeItem(income);
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  void _editIncomeItem(IncomeSource income) async {
    final nameController = TextEditingController(text: income.name);
    final amountController = TextEditingController(text: income.amount.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Income'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && income.id != null) {
      final newName = nameController.text.trim();
      final newAmount = double.tryParse(amountController.text) ?? income.amount;

      if (newName.isNotEmpty) {
        await _incomeRepo.update(income.copyWith(
          name: newName,
          amount: newAmount,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ), income.id!);
        _loadData();
      }
    }
  }

  void _deleteIncomeItem(IncomeSource income) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income?'),
        content: Text('Delete "${income.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB00020)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && income.id != null) {
      await _incomeRepo.delete(income.id!);
      _loadData();
    }
  }

  void _showExpenseActions(FixedExpense expense) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    Formatters.currency(expense.amount),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                _editExpenseItem(expense);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFB00020)),
              title: const Text('Delete', style: TextStyle(color: Color(0xFFB00020))),
              onTap: () {
                Navigator.pop(context);
                _deleteExpenseItem(expense);
              },
            ),
            const SizedBox(height: AppTheme.spacing16),
          ],
        ),
      ),
    );
  }

  void _editExpenseItem(FixedExpense expense) async {
    final nameController = TextEditingController(text: expense.name);
    final amountController = TextEditingController(text: expense.amount.toStringAsFixed(0));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && expense.id != null) {
      final newName = nameController.text.trim();
      final newAmount = double.tryParse(amountController.text) ?? expense.amount;

      if (newName.isNotEmpty) {
        await _fixedExpenseRepo.update(expense.copyWith(
          name: newName,
          amount: newAmount,
          updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ), expense.id!);
        _loadData();
      }
    }
  }

  void _deleteExpenseItem(FixedExpense expense) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Delete "${expense.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB00020)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && expense.id != null) {
      await _fixedExpenseRepo.delete(expense.id!);
      _loadData();
    }
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

  void _editVariableBudget() async {
    if (_userId == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VariableBudgetSetupScreen(
          userId: _userId!,
          isEditing: true,
        ),
      ),
    );
    _loadData();
  }

  void _editSalaryDay() async {
    if (_userId == null) return;

    int selectedDay = _salaryDay;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Salary Day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'When do you receive your salary?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gray300),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedDay,
                    isExpanded: true,
                    items: List.generate(28, (i) => i + 1)
                        .map((day) => DropdownMenuItem(
                              value: day,
                              child: Text(_getOrdinal(day)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedDay = value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacing12),
              Text(
                'Your budget will reset on this day each month.',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selectedDay),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != _salaryDay) {
      await _userRepo.updateSalaryDay(_userId!, result);
      _loadData();
    }
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
