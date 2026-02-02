import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/budget/budget_screen.dart';
import 'features/calculator/calculator_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/notes/screens/notes_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const FinanceSenseiApp());
}

class FinanceSenseiApp extends StatelessWidget {
  const FinanceSenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceSensei',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentModule = 'budget';

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildCurrentModule() {
    switch (_currentModule) {
      case 'budget':
        return BudgetScreen(onMenuTap: _openDrawer);
      case 'notes':
        return NotesScreen(onMenuTap: _openDrawer);
      case 'knowledge':
        return LearnScreen(onMenuTap: _openDrawer);
      case 'calculator':
        return CalculatorScreen(onMenuTap: _openDrawer);
      default:
        return BudgetScreen(onMenuTap: _openDrawer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        currentModule: _currentModule,
        onModuleSelected: (module) {
          setState(() => _currentModule = module);
          Navigator.pop(context);
        },
      ),
      body: _buildCurrentModule(),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String currentModule;
  final ValueChanged<String> onModuleSelected;

  const AppDrawer({
    super.key,
    required this.currentModule,
    required this.onModuleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'FinanceSensei',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: 48),

            _DrawerItem(
              title: 'Budget',
              isSelected: currentModule == 'budget',
              onTap: () => onModuleSelected('budget'),
            ),

            _DrawerItem(
              title: 'Notes',
              isSelected: currentModule == 'notes',
              onTap: () => onModuleSelected('notes'),
            ),

            _DrawerItem(
              title: 'Learn',
              isSelected: currentModule == 'knowledge',
              onTap: () => onModuleSelected('knowledge'),
            ),

            _DrawerItem(
              title: 'Calculator',
              isSelected: currentModule == 'calculator',
              onTap: () => onModuleSelected('calculator'),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected ? const Color(0xFFF9F9F9) : Colors.transparent,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
