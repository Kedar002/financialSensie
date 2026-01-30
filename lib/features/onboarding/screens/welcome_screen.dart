import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'income_setup_screen.dart';

/// Welcome screen - minimal, focused, branded.
/// One clear action: Get Started.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // Logo - centered, prominent
              Image.asset(
                'assets/icon/app_icon.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: AppTheme.spacing32),
              Text(
                'FinanceSensei',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Know exactly how much you can spend today, without thinking.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.gray600,
                    ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 4),
              ElevatedButton(
                onPressed: () => _navigateToSetup(context),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: AppTheme.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToSetup(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const IncomeSetupScreen()),
    );
  }
}
