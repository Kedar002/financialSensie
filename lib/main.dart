import 'package:flutter/material.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('FinanceSensei'),
        ),
      ),
    );
  }
}
