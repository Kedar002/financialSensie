import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Home screen - THE core screen.
/// Shows safe-to-spend prominently. Nothing else competes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const EmergencyFundScreen(),
          const GoalsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildNavBar(),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: _logSpending,
              backgroundColor: AppTheme.black,
              child: const Icon(Icons.add, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing24),
            _buildCycleInfo(),
            const SizedBox(height: AppTheme.spacing16),
            _buildSafeToSpendCard(),
            const SizedBox(height: AppTheme.spacing32),
            _buildQuickStats(),
            const SizedBox(height: AppTheme.spacing48),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleInfo() {
    final cycleText = DateFormat('MMMM yyyy').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          cycleText,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1,
              ),
        ),
      ],
    );
  }

  Widget _buildSafeToSpendCard() {
    // Placeholder values - will be connected to database later
    const daily = 847.0;
    const weekly = 5929.0;
    const daysRemaining = 12;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today you can spend',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          Formatters.currency(daily),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: AppTheme.spacing24),
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'This week',
                  value: Formatters.currency(weekly),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.gray200,
              ),
              const Expanded(
                child: _StatItem(
                  label: 'Days left',
                  value: '$daysRemaining',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    // Placeholder values
    const spent = 8500.0;
    const budget = 25000.0;
    const remaining = budget - spent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'This cycle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'View budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        AppCard(
          child: Column(
            children: [
              _buildStatRow('Budget', Formatters.currency(budget)),
              const Divider(height: AppTheme.spacing24),
              _buildStatRow('Spent', Formatters.currency(spent)),
              const Divider(height: AppTheme.spacing24),
              _buildStatRow(
                'Remaining',
                Formatters.currency(remaining),
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: bold
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.gray200, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            activeIcon: Icon(Icons.shield),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _logSpending() {
    // TODO: Implement log spending
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log spending - coming soon')),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}
