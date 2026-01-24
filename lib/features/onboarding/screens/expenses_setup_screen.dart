import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/models/fixed_expense.dart';
import 'variable_budget_setup_screen.dart';

/// Fixed expenses setup - essential items only.
class ExpensesSetupScreen extends StatefulWidget {
  final int userId;
  final bool isEditing;

  const ExpensesSetupScreen({
    super.key,
    required this.userId,
    this.isEditing = false,
  });

  @override
  State<ExpensesSetupScreen> createState() => _ExpensesSetupScreenState();
}

class _ExpensesSetupScreenState extends State<ExpensesSetupScreen> {
  final _rentController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _otherController = TextEditingController();
  final _expenseRepo = FixedExpenseRepository();
  bool _isLoading = false;
  List<FixedExpense> _existingExpenses = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final expenses = await _expenseRepo.getByUserId(widget.userId);
    _existingExpenses = expenses;

    for (final expense in expenses) {
      if (expense.category == FixedExpenseCategory.housing) {
        _rentController.text = expense.amount.toStringAsFixed(0);
      } else if (expense.category == FixedExpenseCategory.utilities) {
        _utilitiesController.text = expense.amount.toStringAsFixed(0);
      } else if (expense.category == FixedExpenseCategory.other) {
        _otherController.text = expense.amount.toStringAsFixed(0);
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _rentController.dispose();
    _utilitiesController.dispose();
    _otherController.dispose();
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
              title: const Text('Edit Expenses'),
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
                    ? 'Update your expenses'
                    : 'Monthly expenses',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Your regular fixed costs.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing32),
              Expanded(
                child: ListView(
                  children: [
                    _ExpenseField(
                      label: 'Rent / EMI',
                      controller: _rentController,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _ExpenseField(
                      label: 'Utilities & Bills',
                      controller: _utilitiesController,
                    ),
                    const SizedBox(height: AppTheme.spacing16),
                    _ExpenseField(
                      label: 'Other fixed expenses',
                      controller: _otherController,
                    ),
                  ],
                ),
              ),
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

  Future<void> _continue() async {
    setState(() => _isLoading = true);

    try {
      // Delete existing expenses if editing
      if (widget.isEditing) {
        for (final expense in _existingExpenses) {
          if (expense.id != null) {
            await _expenseRepo.delete(expense.id!);
          }
        }
      }

      final rent = double.tryParse(_rentController.text) ?? 0;
      final utilities = double.tryParse(_utilitiesController.text) ?? 0;
      final other = double.tryParse(_otherController.text) ?? 0;

      if (rent > 0) {
        await _expenseRepo.addExpense(
          userId: widget.userId,
          name: 'Rent / EMI',
          amount: rent,
          category: FixedExpenseCategory.housing,
        );
      }

      if (utilities > 0) {
        await _expenseRepo.addExpense(
          userId: widget.userId,
          name: 'Utilities & Bills',
          amount: utilities,
          category: FixedExpenseCategory.utilities,
        );
      }

      if (other > 0) {
        await _expenseRepo.addExpense(
          userId: widget.userId,
          name: 'Other',
          amount: other,
          category: FixedExpenseCategory.other,
        );
      }

      if (mounted) {
        if (widget.isEditing) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => VariableBudgetSetupScreen(userId: widget.userId),
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
        builder: (_) => VariableBudgetSetupScreen(userId: widget.userId),
      ),
    );
  }
}

class _ExpenseField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _ExpenseField({
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '0',
            prefixText: '₹ ',
          ),
        ),
      ],
    );
  }
}
