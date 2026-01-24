import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../utils/formatters.dart';

/// Large amount display for key metrics.
/// Clean, minimal, impactful.
class AmountDisplay extends StatelessWidget {
  final double amount;
  final String? label;
  final bool large;
  final bool compact;

  const AmountDisplay({
    super.key,
    required this.amount,
    this.label,
    this.large = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.labelMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
        ],
        Text(
          compact
              ? Formatters.currencyCompact(amount)
              : Formatters.currency(amount),
          style: large ? textTheme.displayLarge : textTheme.displayMedium,
        ),
      ],
    );
  }
}
