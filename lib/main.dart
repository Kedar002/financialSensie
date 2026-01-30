import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/database/database.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/screens/welcome_screen.dart';

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
      home: const WelcomeScreen(),
    );
  }
}
