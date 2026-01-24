import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Minimal progress bar.
/// No gradients, no shadows. Just a simple fill.
class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 100.0) / 100;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.gray200,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clampedProgress,
        child: Container(
          decoration: BoxDecoration(
            color: foregroundColor ?? AppTheme.black,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}
