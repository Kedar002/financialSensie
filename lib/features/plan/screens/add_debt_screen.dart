import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/financial_plan.dart';

/// Add Debt Screen - Log a debt to track.
/// Simple: Name, Amount, Interest Rate, Minimum Payment.
class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _minimumController = TextEditingController();
  final _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _interestController.dispose();
    _minimumController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interest = double.tryParse(_interestController.text) ?? 0;
    return name.isNotEmpty && amount > 0 && interest >= 0;
  }

  DebtPriority get _priority {
    final interest = double.tryParse(_interestController.text) ?? 0;
    return DebtPriority.fromInterestRate(interest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppTheme.spacing32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNameInput(context),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildAmountInput(context),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildInterestInput(context),
                      const SizedBox(height: AppTheme.spacing16),
                      _buildPriorityIndicator(context),
                      const SizedBox(height: AppTheme.spacing24),
                      _buildMinimumInput(context),
                      const SizedBox(height: AppTheme.spacing32),
                    ],
                  ),
                ),
              ),
              _buildSaveButton(context),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppTheme.gray600,
            ),
          ),
        ),
        Text(
          'Add Debt',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildNameInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is this debt?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppTheme.spacing16),
        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'e.g., Credit Card, Car Loan',
            hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.gray400,
                ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(height: 1, color: AppTheme.gray200),
      ],
    );
  }

  Widget _buildAmountInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total amount owed',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.gray400,
                  ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.displayLarge,
                decoration: const InputDecoration(
                  hintText: '0',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interest rate (annual %)',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextField(
                controller: _interestController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                style: Theme.of(context).textTheme.titleLarge,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.gray400,
                      ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Text(
              '%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gray400,
                  ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(height: 1, color: AppTheme.gray200),
      ],
    );
  }

  Widget _buildPriorityIndicator(BuildContext context) {
    final interest = double.tryParse(_interestController.text) ?? 0;
    if (interest <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: _priority == DebtPriority.high ? AppTheme.black : AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Icon(
            _priority == DebtPriority.high ? Icons.priority_high : Icons.info_outline,
            size: 16,
            color: _priority == DebtPriority.high ? AppTheme.white : AppTheme.gray600,
          ),
          const SizedBox(width: AppTheme.spacing8),
          Expanded(
            child: Text(
              _priority.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _priority == DebtPriority.high ? AppTheme.white : AppTheme.gray600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimumInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum monthly payment',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Optional - helps track payment requirements',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray400,
              ),
        ),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '₹',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.gray400,
                  ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: TextField(
                controller: _minimumController,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.titleLarge,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.gray400,
                      ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing8),
        Container(height: 1, color: AppTheme.gray200),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return AnimatedOpacity(
      opacity: _canSave ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _canSave ? _save : null,
        child: const Text('Add Debt'),
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final interest = double.tryParse(_interestController.text) ?? 0;
    final minimum = double.tryParse(_minimumController.text) ?? 0;

    if (name.isEmpty || amount <= 0) return;

    final debt = Debt.create(
      name: name,
      totalAmount: amount,
      interestRate: interest,
      minimumPayment: minimum,
    );

    Navigator.pop(context, debt);
  }
}
