import 'dart:async';
import 'package:flutter/material.dart';
import 'delete_screen.dart';
import 'hdelete_screen.dart';

class FdCalculatorScreen extends StatefulWidget {
  final VoidCallback onBack;

  const FdCalculatorScreen({super.key, required this.onBack});

  @override
  State<FdCalculatorScreen> createState() => _FdCalculatorScreenState();
}

class _FdCalculatorScreenState extends State<FdCalculatorScreen> {
  Timer? _longPressTimer;

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(seconds: 5), _showConfirmDialog);
  }

  void _onPointerUp(PointerEvent event) {
    _longPressTimer?.cancel();
  }

  void _showConfirmDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool obscureText = true;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Type to confirm you want to open the delete page.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888888),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: obscureText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type here',
                    hintStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFCCCCCC),
                    ),
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFEEEEEE)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    contentPadding: const EdgeInsets.only(bottom: 8),
                    suffixIcon: GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          obscureText = !obscureText;
                        });
                      },
                      child: Icon(
                        obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minHeight: 20,
                      minWidth: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: () {
                      final text = controller.text.trim().toLowerCase();
                      if (text == 'delete') {
                        Navigator.of(dialogContext).pop();
                        _navigateTo(const DeleteScreen());
                      } else if (text == 'hdelete') {
                        Navigator.of(dialogContext).pop();
                        _navigateTo(const HdeleteScreen());
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'FD Calculator',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: Listener(
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerUp,
                behavior: HitTestBehavior.translucent,
                child: Center(
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
