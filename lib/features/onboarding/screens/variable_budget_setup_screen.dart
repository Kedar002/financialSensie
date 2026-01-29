import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import 'savings_setup_screen.dart';

/// Variable budget setup - estimate spending for each category.
class VariableBudgetSetupScreen extends StatefulWidget {
  final bool isEditing;

  const VariableBudgetSetupScreen({
    super.key,
    this.isEditing = false,
  });

  @override
  State<VariableBudgetSetupScreen> createState() => _VariableBudgetSetupScreenState();
}

class _VariableBudgetSetupScreenState extends State<VariableBudgetSetupScreen> {
  final Map<String, TextEditingController> _controllers = {};

  final List<_CategoryInfo> _categories = [
    _CategoryInfo(
      key: 'food',
      label: 'Food & Dining',
      icon: Icons.restaurant,
      isEssential: true,
    ),
    _CategoryInfo(
      key: 'transport',
      label: 'Transport',
      icon: Icons.directions_car,
      isEssential: true,
    ),
    _CategoryInfo(
      key: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag,
      isEssential: false,
    ),
    _CategoryInfo(
      key: 'entertainment',
      label: 'Entertainment',
      icon: Icons.movie,
      isEssential: false,
    ),
    _CategoryInfo(
      key: 'health',
      label: 'Health & Wellness',
      icon: Icons.medical_services,
      isEssential: true,
    ),
    _CategoryInfo(
      key: 'other',
      label: 'Other',
      icon: Icons.receipt,
      isEssential: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final category in _categories) {
      _controllers[category.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isEditing
          ? AppBar(
              backgroundColor: AppTheme.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.black),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Edit Budget'),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isEditing) const SizedBox(height: AppTheme.spacing48),
              Text(
                widget.isEditing
                    ? 'Update your budget'
                    : 'Variable spending',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'Estimate how much you spend each month.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Expanded(
                child: ListView.separated(
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppTheme.spacing16),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _CategoryField(
                      icon: category.icon,
                      label: category.label,
                      controller: _controllers[category.key]!,
                      isEssential: category.isEssential,
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              _buildTotal(),
              const SizedBox(height: AppTheme.spacing16),
              ElevatedButton(
                onPressed: _continue,
                child: Text(widget.isEditing ? 'Save' : 'Continue'),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: AppTheme.spacing16),
                Center(
                  child: TextButton(
                    onPressed: () => _skip(context),
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotal() {
    double total = 0;
    for (final controller in _controllers.values) {
      total += double.tryParse(controller.text) ?? 0;
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total variable budget',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '\u20B9${total.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  void _continue() {
    if (widget.isEditing) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SavingsSetupScreen(),
        ),
      );
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const SavingsSetupScreen(),
      ),
    );
  }
}

class _CategoryInfo {
  final String key;
  final String label;
  final IconData icon;
  final bool isEssential;

  const _CategoryInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.isEssential,
  });
}

class _CategoryField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool isEssential;

  const _CategoryField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.isEssential,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppTheme.black, size: 20),
        ),
        const SizedBox(width: AppTheme.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (isEssential)
                Text(
                  'Essential',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: '\u20B9 ',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
