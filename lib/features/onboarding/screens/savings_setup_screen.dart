import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';

/// Emergency fund setup - current savings.
class SavingsSetupScreen extends StatefulWidget {
  final bool isEditing;

  const SavingsSetupScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<SavingsSetupScreen> createState() => _SavingsSetupScreenState();
}

class _SavingsSetupScreenState extends State<SavingsSetupScreen> {
  final _controller = TextEditingController();
  final _settingsRepo = SettingsRepository();
  final _fundRepo = EmergencyFundRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingValue();
  }

  Future<void> _loadExistingValue() async {
    if (widget.isEditing) {
      // When editing, show monthly savings amount (from percentage)
      final income = await _settingsRepo.getMonthlyIncome();
      final fixedExpenses = await _settingsRepo.getTotalFixedExpenses();
      final savingsPercent = await _settingsRepo.getSavingsPercent();

      final afterFixed = income - fixedExpenses;
      if (afterFixed > 0 && savingsPercent > 0) {
        final savings = (afterFixed * savingsPercent / 100).round();
        _controller.text = AmountConverter.toRupees(savings).toInt().toString();
      }
    } else {
      // When onboarding, show current emergency fund amount
      final currentAmount = await _fundRepo.getCurrentAmount();
      if (currentAmount > 0) {
        _controller.text = AmountConverter.toRupees(currentAmount).toInt().toString();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                icon: const Icon(Icons.chevron_left, color: AppTheme.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Edit Savings'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.black))
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEditing) const SizedBox(height: AppTheme.spacing48),
              Text(
                widget.isEditing
                    ? 'Update your savings'
                    : 'Current savings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'How much do you have saved for emergencies?',
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
                  prefixText: '\u20B9 ',
                ),
                autofocus: !widget.isEditing,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _finish,
                child: Text(widget.isEditing ? 'Save' : 'Finish Setup'),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: AppTheme.spacing16),
                Center(
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('I\'ll add this later'),
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

  Future<void> _finish() async {
    final enteredAmount = double.tryParse(_controller.text) ?? 0;

    if (widget.isEditing) {
      // When editing, save as savings percentage
      final income = await _settingsRepo.getMonthlyIncome();
      final fixedExpenses = await _settingsRepo.getTotalFixedExpenses();
      final afterFixed = income - fixedExpenses;
      final enteredAmountPaise = AmountConverter.toPaise(enteredAmount);

      int savingsPercent = 20; // default
      if (afterFixed > 0 && enteredAmountPaise > 0) {
        savingsPercent = (enteredAmountPaise / afterFixed * 100).round().clamp(0, 100);
      }

      await _settingsRepo.setSavingsPercent(savingsPercent);

      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      // When onboarding, save to emergency fund and mark complete
      if (enteredAmount > 0) {
        await _fundRepo.addContribution(
          amount: enteredAmount,
          type: 'initial',
          note: 'Initial savings from onboarding',
        );
      }

      // Mark onboarding as complete
      await _settingsRepo.completeOnboarding();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _skip() async {
    // Mark onboarding as complete even when skipping
    await _settingsRepo.completeOnboarding();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
