import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/services/safe_to_spend_service.dart';
import '../../../core/models/variable_expense.dart';
import '../../../shared/utils/formatters.dart';

/// Quick spending log - minimal friction.
/// Amount, optional category. That's it.
class LogSpendingScreen extends StatefulWidget {
  final int userId;

  const LogSpendingScreen({super.key, required this.userId});

  @override
  State<LogSpendingScreen> createState() => _LogSpendingScreenState();
}

class _LogSpendingScreenState extends State<LogSpendingScreen> {
  final _controller = TextEditingController();
  final _transactionRepo = TransactionRepository();
  final _safeToSpendService = SafeToSpendService();

  String _selectedCategory = VariableExpenseCategory.other;
  SpendImpact? _impact;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountChanged(String value) async {
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      setState(() => _impact = null);
      return;
    }

    final impact = await _safeToSpendService.previewSpendImpact(
      widget.userId,
      amount,
    );
    setState(() => _impact = impact);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Spending'),
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
                'How much?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing8),
              TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.displayMedium,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '₹ ',
                ),
                autofocus: true,
                onChanged: _onAmountChanged,
              ),
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'Category',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacing12),
              Wrap(
                spacing: AppTheme.spacing8,
                runSpacing: AppTheme.spacing8,
                children: VariableExpenseCategory.all.map((category) {
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing16,
                        vertical: AppTheme.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.black : AppTheme.gray100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Text(
                        _formatCategory(category),
                        style: TextStyle(
                          color: isSelected ? AppTheme.white : AppTheme.black,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_impact != null) ...[
                const SizedBox(height: AppTheme.spacing32),
                _buildImpactPreview(),
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
                    : const Text('Save'),
              ),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactPreview() {
    if (_impact == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily budget after',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  Formatters.currency(_impact!.newDaily),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          if (_impact!.isOverBudget)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: AppTheme.black,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                'Over budget',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.white,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await _transactionRepo.addTransaction(
        userId: widget.userId,
        amount: amount,
        category: _selectedCategory,
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
