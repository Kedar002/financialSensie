import 'package:flutter/material.dart';
import 'emi_calculator_screen.dart';
import 'budget_calculator_screen.dart';

class CalculatorScreen extends StatelessWidget {
  final VoidCallback onMenuTap;

  const CalculatorScreen({super.key, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, size: 24),
                    onPressed: onMenuTap,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Calculators',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Calculator list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _CalculatorTile(
                    title: 'EMI Calculator',
                    subtitle: 'Plan your loan repayments',
                    onTap: () => _navigateTo(context, const _EmiCalculatorWrapper()),
                  ),
                  const SizedBox(height: 16),
                  _CalculatorTile(
                    title: 'Budget Planner',
                    subtitle: '50-30-20 rule',
                    onTap: () => _navigateTo(context, const _BudgetCalculatorWrapper()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }
}

class _CalculatorTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CalculatorTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFFCCCCCC),
            ),
          ],
        ),
      ),
    );
  }
}

// Wrapper to add back navigation to EMI Calculator
class _EmiCalculatorWrapper extends StatelessWidget {
  const _EmiCalculatorWrapper();

  @override
  Widget build(BuildContext context) {
    return EmiCalculatorScreen(
      onMenuTap: () => Navigator.of(context).pop(),
      showBackButton: true,
    );
  }
}

// Wrapper to add back navigation to Budget Calculator
class _BudgetCalculatorWrapper extends StatelessWidget {
  const _BudgetCalculatorWrapper();

  @override
  Widget build(BuildContext context) {
    return BudgetCalculatorScreen(
      onBack: () => Navigator.of(context).pop(),
    );
  }
}
