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

  List<Widget> get _tabs => [
    ExpensesTab(onMenuTap: widget.onMenuTap),
    NeedsTab(onMenuTap: widget.onMenuTap),
    WantsTab(onMenuTap: widget.onMenuTap),
    SavingsTab(onMenuTap: widget.onMenuTap),
    StatisticsTab(onMenuTap: widget.onMenuTap),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
              child: Icon(Icons.account_balance_wallet_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.account_balance_wallet, size: 22),
            ),
            label: 'Expenses',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined, size: 22),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home, size: 22),
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
