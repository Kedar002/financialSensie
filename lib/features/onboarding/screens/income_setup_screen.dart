import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/income_repository.dart';
import 'expenses_setup_screen.dart';

/// Income setup - one field, one action.
class IncomeSetupScreen extends StatefulWidget {
  const IncomeSetupScreen({super.key});

  @override
  State<IncomeSetupScreen> createState() => _IncomeSetupScreenState();
}

class _IncomeSetupScreenState extends State<IncomeSetupScreen> {
  final _controller = TextEditingController();
  final _userRepo = UserRepository();
  final _incomeRepo = IncomeRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing48),
              Text(
                'What\'s your monthly income?',
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
                autofocus: true,
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
                    : const Text('Continue'),
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
      // Create user if not exists
      final hasUser = await _userRepo.hasUser();
      int userId;

      if (!hasUser) {
        userId = await _userRepo.createUser('User');
      } else {
        final user = await _userRepo.getCurrentUser();
        userId = user!.id!;
      }

      // Add income
      await _incomeRepo.addIncome(
        userId: userId,
        name: 'Salary',
        amount: amount,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ExpensesSetupScreen()),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
