import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Simple label-value row for displaying metrics.
class MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const MetricRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.bodyMedium,
          ),
          Text(
            value,
            style: bold
                ? textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
                : textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
