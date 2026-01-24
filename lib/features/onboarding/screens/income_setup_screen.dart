import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/income_repository.dart';
import '../../../core/models/income_source.dart';
import 'expenses_setup_screen.dart';

/// Income setup - one field, one action.
class IncomeSetupScreen extends StatefulWidget {
  final int? userId;
  final bool isEditing;

  const IncomeSetupScreen({
    super.key,
    this.userId,
    this.isEditing = false,
  });

  @override
  State<IncomeSetupScreen> createState() => _IncomeSetupScreenState();
}

class _IncomeSetupScreenState extends State<IncomeSetupScreen> {
  final _controller = TextEditingController();
  final _userRepo = UserRepository();
  final _incomeRepo = IncomeRepository();
  bool _isLoading = false;
  List<IncomeSource> _existingIncomes = [];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.userId != null) {
      _loadExistingData();
    }
  }

  Future<void> _loadExistingData() async {
    final incomes = await _incomeRepo.getByUserId(widget.userId!);
    if (incomes.isNotEmpty) {
      _existingIncomes = incomes;
      // Show the first income amount
      final totalMonthly = incomes.fold<double>(
        0.0,
        (sum, income) => sum + income.monthlyAmount,
      );
      _controller.text = totalMonthly.toStringAsFixed(0);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
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
              title: const Text('Edit Income'),
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
                    ? 'Update your monthly income'
                    : 'What\'s your monthly income?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Your salary or primary income source.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing32),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.displayMedium,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                ),
                autofocus: !widget.isEditing,
              ),
              const Spacer(),
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
              const SizedBox(height: AppTheme.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      int userId;

      if (widget.isEditing && widget.userId != null) {
        userId = widget.userId!;

        // Delete existing incomes and add new one
        for (final income in _existingIncomes) {
          if (income.id != null) {
            await _incomeRepo.delete(income.id!);
          }
        }
      } else {
        // Create user if not exists
        final hasUser = await _userRepo.hasUser();

        if (!hasUser) {
          userId = await _userRepo.createUser('User');
        } else {
          final user = await _userRepo.getCurrentUser();
          userId = user!.id!;
        }
      }

      // Add income
      await _incomeRepo.addIncome(
        userId: userId,
        name: 'Salary',
        amount: amount,
      );

      if (mounted) {
        if (widget.isEditing) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ExpensesSetupScreen(userId: userId),
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
}
