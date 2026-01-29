import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/expense.dart';

/// Add expense screen.
/// One purpose: Log what you spent.
/// Clean. Fast. Done.
class AddExpenseScreen extends StatefulWidget {
  final DateTime date;

  const AddExpenseScreen({
    super.key,
    required this.date,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  bool get _canSave {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return amount > 0;
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
              _buildHeader(),
              const SizedBox(height: AppTheme.spacing48),
              _buildAmountInput(),
              const SizedBox(height: AppTheme.spacing24),
              _buildNoteInput(),
              const Spacer(),
              _buildSaveButton(),
              const SizedBox(height: AppTheme.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          _getDateLabel(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
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
                focusNode: _amountFocusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
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

  Widget _buildNoteInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Note',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _noteController,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'What was this for?',
            hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _canSave ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: _canSave ? _save : null,
        child: const Text('Done'),
      ),
    );
  }

  String _getDateLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(
      widget.date.year,
      widget.date.month,
      widget.date.day,
    );

    if (selectedDay == today) {
      return 'Today';
    }

    final yesterday = today.subtract(const Duration(days: 1));
    if (selectedDay == yesterday) {
      return 'Yesterday';
    }

    return '${widget.date.day}/${widget.date.month}';
  }

  void _save() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final expense = Expense.create(
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      date: widget.date,
    );

    Navigator.pop(context, expense);
  }
}
