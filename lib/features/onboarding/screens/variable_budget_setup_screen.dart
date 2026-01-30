import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'savings_setup_screen.dart';

/// Variable budget setup - simplified to ONE question.
/// Categories can be added later in the app.
class VariableBudgetSetupScreen extends StatefulWidget {
  final bool isEditing;

  const VariableBudgetSetupScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<VariableBudgetSetupScreen> createState() => _VariableBudgetSetupScreenState();
}

class _VariableBudgetSetupScreenState extends State<VariableBudgetSetupScreen> {
  final _controller = TextEditingController();

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
                    ? 'Update your variable budget'
                    : 'Variable spending',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Food, transport, shopping, and other monthly expenses.',
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
              if (!widget.isEditing) ...[
                const SizedBox(height: AppTheme.spacing16),
                Center(
                  child: TextButton(
                    onPressed: () => _skip(context),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing48),
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
          builder: (_) => const SavingsSetupScreen(),
        ),
      );
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SavingsSetupScreen(),
      ),
    );
  }
}
