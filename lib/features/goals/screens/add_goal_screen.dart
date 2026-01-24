import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/goal_service.dart';
import '../../../core/models/planned_expense.dart';
import '../../../shared/utils/formatters.dart';

/// Add goal screen - name, amount, target date.
/// Shows feasibility feedback.
class AddGoalScreen extends StatefulWidget {
  final int userId;

  const AddGoalScreen({super.key, required this.userId});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _goalService = GoalService();

  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  GoalFeasibility? _feasibility;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _checkFeasibility() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _feasibility = null);
      return;
    }

    final feasibility = await _goalService.checkFeasibility(
      widget.userId,
      amount,
      _targetDate,
    );
    setState(() => _feasibility = feasibility);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Goal'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you saving for?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Vacation, New laptop',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'How much do you need?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                ),
                onChanged: (_) => _checkFeasibility(),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'When do you need it?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    Formatters.date(_targetDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
              if (_feasibility != null) ...[
                const SizedBox(height: AppTheme.spacing24),
                _buildFeasibilityCard(),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.white,
                        ),
                      )
                    : const Text('Create Goal'),
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeasibilityCard() {
    final f = _feasibility!;
    final monthlyRequired = PlannedExpense.calculateMonthlyRequired(
      double.tryParse(_amountController.text) ?? 0,
      0,
      _targetDate.millisecondsSinceEpoch ~/ 1000,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: f.isRealistic ? AppTheme.gray100 : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: f.isRealistic
            ? null
            : Border.all(color: AppTheme.black, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                f.isRealistic ? Icons.check_circle_outline : Icons.info_outline,
                size: 20,
                color: AppTheme.black,
              ),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                f.isRealistic ? 'Looks achievable' : 'Might be tight',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            'You\'ll need to save ${Formatters.currency(monthlyRequired)} per month.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (!f.isRealistic && f.suggestedDate != null) ...[
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Consider ${Formatters.date(f.suggestedDate!)} instead.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.black,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _targetDate = date);
      _checkFeasibility();
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (name.isEmpty || amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await _goalService.createGoal(
        userId: widget.userId,
        name: name,
        targetAmount: amount,
        targetDate: _targetDate,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
