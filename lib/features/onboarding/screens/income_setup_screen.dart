import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/database.dart';
import '../../../core/theme/app_theme.dart';
import 'expenses_setup_screen.dart';

/// Income setup - one field, one action.
class IncomeSetupScreen extends StatefulWidget {
  final bool isEditing;

  const IncomeSetupScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<IncomeSetupScreen> createState() => _IncomeSetupScreenState();
}

class _IncomeSetupScreenState extends State<IncomeSetupScreen> {
  final _controller = TextEditingController();
  final _settingsRepo = SettingsRepository();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingValue();
  }

  Future<void> _loadExistingValue() async {
    final income = await _settingsRepo.getMonthlyIncome();
    if (income > 0) {
      _controller.text = AmountConverter.toRupees(income).toInt().toString();
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
              title: const Text('Edit Income'),
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
                        prefixText: '\u20B9 ',
                      ),
                      autofocus: !widget.isEditing,
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _continue,
                      child: Text(widget.isEditing ? 'Save' : 'Continue'),
                    ),
                    const SizedBox(height: AppTheme.spacing48),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _continue() async {
    // Save to database
    final amount = double.tryParse(_controller.text) ?? 0;
    await _settingsRepo.setMonthlyIncome(AmountConverter.toPaise(amount));

    if (!mounted) return;

    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ExpensesSetupScreen(),
        ),
      );
    }
  }
}
