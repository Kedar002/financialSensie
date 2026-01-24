import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/database/database_service.dart';
import 'core/repositories/user_repository.dart';
import 'features/onboarding/screens/welcome_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize database
  await DatabaseService().database;

  runApp(const FinanceSenseiApp());
}

class FinanceSenseiApp extends StatelessWidget {
  const FinanceSenseiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinanceSensei',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppEntry(),
    );
  }
}

/// Entry point that checks if user exists.
/// Shows onboarding for new users, home for returning users.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  final _userRepo = UserRepository();
  bool _isLoading = true;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final hasUser = await _userRepo.hasUser();
    setState(() {
      _hasUser = hasUser;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.black),
        ),
      );
    }

    if (_hasUser) {
      return const HomeScreen();
    }

    return const WelcomeScreen();
  }
}
