import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'variable_budget_setup_screen.dart';

/// Fixed expenses setup - essential items only.
class ExpensesSetupScreen extends StatefulWidget {
  final bool isEditing;

  const ExpensesSetupScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<ExpensesSetupScreen> createState() => _ExpensesSetupScreenState();
}

class _ExpensesSetupScreenState extends State<ExpensesSetupScreen> {
  final _rentController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _otherController = TextEditingController();

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
                onPressed: _continue,
                child: Text(widget.isEditing ? 'Save' : 'Continue'),
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

  void _continue() {
    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const VariableBudgetSetupScreen(),
        ),
      );
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const VariableBudgetSetupScreen(),
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
            prefixText: '\u20B9 ',
          ),
        ),
      ],
    );
  }
}
