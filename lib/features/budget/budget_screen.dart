import 'package:flutter/material.dart';
import 'tabs/expenses_tab.dart';
import 'tabs/needs_tab.dart';
import 'tabs/wants_tab.dart';
import 'tabs/savings_tab.dart';
import 'tabs/statistics_tab.dart';

class BudgetScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const BudgetScreen({super.key, required this.onMenuTap});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _currentIndex = 0;
  // Keys to force rebuild when switching tabs (refreshes data)
  final List<UniqueKey> _tabKeys = List.generate(5, (_) => UniqueKey());

  void _onTabTap(int index) {
    // Generate new key for the tab to force refresh
    _tabKeys[index] = UniqueKey();
    setState(() => _currentIndex = index);
  }

  Widget _buildTab(int index) {
    switch (index) {
      case 0:
        return ExpensesTab(key: _tabKeys[0], onMenuTap: widget.onMenuTap);
      case 1:
        return NeedsTab(key: _tabKeys[1], onMenuTap: widget.onMenuTap);
      case 2:
        return WantsTab(key: _tabKeys[2], onMenuTap: widget.onMenuTap);
      case 3:
        return SavingsTab(key: _tabKeys[3], onMenuTap: widget.onMenuTap);
      case 4:
        return StatisticsTab(key: _tabKeys[4], onMenuTap: widget.onMenuTap);
      default:
        return ExpensesTab(key: _tabKeys[0], onMenuTap: widget.onMenuTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTab(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFC7C7CC),
        selectedFontSize: 10,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home, size: 22),
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.receipt_long_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.receipt_long, size: 22),
            ),
            label: 'Needs',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.favorite_outline, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.favorite, size: 22),
            ),
            label: 'Wants',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.savings_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.savings, size: 22),
            ),
            label: 'Savings',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.bar_chart_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.bar_chart, size: 22),
            ),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}
