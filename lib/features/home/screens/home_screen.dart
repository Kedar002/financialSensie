import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/safe_to_spend_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'log_spending_screen.dart';

/// Home screen - THE core screen.
/// Shows safe-to-spend prominently. Nothing else competes.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userRepo = UserRepository();
  final _safeToSpendService = SafeToSpendService();

  int _currentIndex = 0;
  int? _userId;
  SafeToSpendStatus? _status;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        _userId = user.id;
        _status = await _safeToSpendService.getStatus(user.id!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.black),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing24),
              _buildSafeToSpendCard(),
              const SizedBox(height: AppTheme.spacing32),
              _buildQuickStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafeToSpendCard() {
    final daily = _status?.dailyAmount ?? 0;
    final weekly = _status?.weeklyAmount ?? 0;

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
              Expanded(
                child: _StatItem(
                  label: 'Days left',
                  value: '${_status?.daysRemaining ?? 0}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final spent = _status?.spentThisMonth ?? 0;
    final budget = _status?.monthlyBudget ?? 0;
    final remaining = _status?.remaining ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This month',
          style: Theme.of(context).textTheme.headlineMedium,
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

  void _logSpending() async {
    if (_userId == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LogSpendingScreen(userId: _userId!),
      ),
    );

    if (result == true) {
      _loadData();
    }
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
