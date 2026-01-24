import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/models/variable_expense.dart';
import 'savings_setup_screen.dart';

/// Variable budget setup - estimate spending for each category.
class VariableBudgetSetupScreen extends StatefulWidget {
  final int userId;
  final bool isEditing;

  const VariableBudgetSetupScreen({
    super.key,
    required this.userId,
    this.isEditing = false,
  });

  @override
  State<VariableBudgetSetupScreen> createState() => _VariableBudgetSetupScreenState();
}

class _VariableBudgetSetupScreenState extends State<VariableBudgetSetupScreen> {
  final _variableExpenseRepo = VariableExpenseRepository();
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = false;
  List<VariableExpense> _existingExpenses = [];

  final List<_CategoryInfo> _categories = [
    _CategoryInfo(
      key: VariableExpenseCategory.food,
      label: 'Food & Dining',
      icon: Icons.restaurant,
      isEssential: true,
    ),
    _CategoryInfo(
      key: VariableExpenseCategory.transport,
      label: 'Transport',
      icon: Icons.directions_car,
      isEssential: true,
    ),
    _CategoryInfo(
      key: VariableExpenseCategory.shopping,
      label: 'Shopping',
      icon: Icons.shopping_bag,
      isEssential: false,
    ),
    _CategoryInfo(
      key: VariableExpenseCategory.entertainment,
      label: 'Entertainment',
      icon: Icons.movie,
      isEssential: false,
    ),
    _CategoryInfo(
      key: VariableExpenseCategory.health,
      label: 'Health & Wellness',
      icon: Icons.medical_services,
      isEssential: true,
    ),
    _CategoryInfo(
      key: VariableExpenseCategory.other,
      label: 'Other',
      icon: Icons.receipt,
      isEssential: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final category in _categories) {
      _controllers[category.key] = TextEditingController();
    }
    if (widget.isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final expenses = await _variableExpenseRepo.getByUserId(widget.userId);
    _existingExpenses = expenses;

    for (final expense in expenses) {
      if (_controllers.containsKey(expense.category)) {
        _controllers[expense.category]!.text = expense.estimatedAmount.toStringAsFixed(0);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEditing
          ? AppBar(
              backgroundColor: AppTheme.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Edit Budget'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEditing) const SizedBox(height: AppTheme.spacing48),
              Text(
                widget.isEditing
                    ? 'Update your budget'
                    : 'Variable spending',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Estimate how much you spend each month.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing16),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _CategoryField(
                      icon: category.icon,
                      label: category.label,
                      controller: _controllers[category.key]!,
                      isEssential: category.isEssential,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildTotal(),
              const SizedBox(height: AppTheme.spacing16),
              ElevatedButton(
                onPressed: _isLoading ? null : _continue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : Text(widget.isEditing ? 'Save' : 'Continue'),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: AppTheme.spacing16),
                Center(
                  child: TextButton(
                    onPressed: () => _skip(context),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotal() {
    double total = 0;
    for (final controller in _controllers.values) {
      total += double.tryParse(controller.text) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total variable budget',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '₹${total.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _isLoading = true);

    try {
      // Delete existing expenses if editing
      if (widget.isEditing) {
        for (final expense in _existingExpenses) {
          if (expense.id != null) {
            await _variableExpenseRepo.delete(expense.id!);
          }
        }
      }

      for (final category in _categories) {
        final amount = double.tryParse(_controllers[category.key]!.text) ?? 0;
        if (amount > 0) {
          await _variableExpenseRepo.addExpense(
            userId: widget.userId,
            category: category.key,
            estimatedAmount: amount,
            isEssential: category.isEssential,
          );
        }
      }

      if (mounted) {
        if (widget.isEditing) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SavingsSetupScreen(userId: widget.userId),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SavingsSetupScreen(userId: widget.userId),
      ),
    );
  }
}

class _CategoryInfo {
  final String key;
  final String label;
  final IconData icon;
  final bool isEssential;

  const _CategoryInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.isEssential,
  });
}

class _CategoryField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isEssential;

  const _CategoryField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.isEssential,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppTheme.black, size: 20),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isEssential)
                Text(
                  'Essential',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: '₹ ',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
