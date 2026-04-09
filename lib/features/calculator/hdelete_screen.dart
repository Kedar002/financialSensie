import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tracker/screens/role_selection_screen.dart';
import '../tracker/screens/tracking_screen.dart';
import '../tracker/screens/viewer_home_screen.dart';

class HdeleteScreen extends StatefulWidget {
  const HdeleteScreen({super.key});

  @override
  State<HdeleteScreen> createState() => _HdeleteScreenState();
}

class _HdeleteScreenState extends State<HdeleteScreen> {
  // Entry point routes to role-specific screen

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('tracker_role');

    if (!mounted) return;

    Widget destination;
    if (role == 'tracker') {
      destination = const TrackingScreen();
    } else if (role == 'viewer') {
      destination = const ViewerHomeScreen();
    } else {
      destination = const RoleSelectionScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.black,
        ),
      ),
    );
  }
}
