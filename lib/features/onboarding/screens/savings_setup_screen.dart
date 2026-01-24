import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/emergency_fund_repository.dart';
import '../../../core/services/emergency_fund_service.dart';
import '../../home/screens/home_screen.dart';

/// Emergency fund setup - current savings.
class SavingsSetupScreen extends StatefulWidget {
  const SavingsSetupScreen({super.key});

  @override
  State<SavingsSetupScreen> createState() => _SavingsSetupScreenState();
}

class _SavingsSetupScreenState extends State<SavingsSetupScreen> {
  final _controller = TextEditingController();
  final _userRepo = UserRepository();
  final _fundRepo = EmergencyFundRepository();
  final _fundService = EmergencyFundService();
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
                'Current savings',
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
                  prefixText: '₹ ',
                ),
                autofocus: true,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _finish,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Finish Setup'),
              ),
              const SizedBox(height: AppTheme.spacing16),
              Center(
                child: TextButton(
                  onPressed: () => _skip(context),
                  child: const Text('I\'ll add this later'),
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userRepo.getCurrentUser();
      if (user == null) return;

      final currentSavings = double.tryParse(_controller.text) ?? 0;
      final target = await _fundService.calculateTarget(user.id!);

      await _fundRepo.createOrUpdate(
        userId: user.id!,
        targetAmount: target,
        currentAmount: currentSavings,
        monthlyEssential: target / 6,
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
