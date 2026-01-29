import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/minimal_calendar.dart';
import '../../emergency_fund/screens/emergency_fund_screen.dart';
import '../../goals/screens/goals_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Home screen - THE core screen.
/// One focus: How much can you spend?
/// Steve Jobs would approve.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  DateTime _selectedDate = DateTime.now();

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
              elevation: 0,
              child: const Icon(Icons.add, color: AppTheme.white),
            )
          : null,
    );
  }

  Widget _buildHomeContent() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.spacing24),
            MinimalCalendar(
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
            const SizedBox(height: AppTheme.spacing48),
            _buildHeroSection(),
            const SizedBox(height: AppTheme.spacing48),
            _buildCycleProgress(),
            const SizedBox(height: AppTheme.spacing64),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    // Placeholder values - will be connected to database later
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final daily = isToday ? 847.0 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'You can spend' : _getDateLabel(_selectedDate),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          Formatters.currency(daily),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        if (isToday) ...[
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'today',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }

  Widget _buildCycleProgress() {
    // Placeholder values
    const spent = 8500.0;
    const budget = 25000.0;
    final progress = spent / budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This month',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        _buildProgressBar(progress),
        const SizedBox(height: AppTheme.spacing16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatColumn('Spent', Formatters.currency(spent)),
            _buildStatColumn('Budget', Formatters.currency(budget)),
            _buildStatColumn(
              'Left',
              Formatters.currency(budget - spent),
              highlight: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: AppTheme.gray200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          value,
          style: highlight
              ? Theme.of(context).textTheme.titleLarge
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
            icon: Icon(Icons.circle_outlined),
            activeIcon: Icon(Icons.circle),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_outline),
            activeIcon: Icon(Icons.lock),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.adjust_outlined),
            activeIcon: Icon(Icons.adjust),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'You',
          ),
        ],
      ),
    );
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    }

    if (date.isAfter(now)) {
      return 'Planned for ${date.day}/${date.month}';
    }

    return 'Spent on ${date.day}/${date.month}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _logSpending() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log spending - coming soon')),
    );
  }
}
