import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tracker/screens/role_selection_screen.dart';
import '../tracker/screens/viewer_home_screen.dart';

class HdeleteScreen extends StatefulWidget {
  const HdeleteScreen({super.key});

  @override
  State<HdeleteScreen> createState() => _HdeleteScreenState();
}

class _HdeleteScreenState extends State<HdeleteScreen> {
  @override
  void initState() {
    super.initState();
    _openViewer();
  }

  Future<void> _openViewer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_role', 'viewer');
    await prefs.setString('tracker_paired_device_id', kSharedDeviceId);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ViewerHomeScreen(),
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
