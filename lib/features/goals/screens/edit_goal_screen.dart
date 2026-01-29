import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../models/goal.dart';

/// Edit goal screen - modify name, target amount, date, and instrument.
class EditGoalScreen extends StatefulWidget {
  final Goal goal;

  const EditGoalScreen({
    super.key,
    required this.goal,
  });

  @override
  State<EditGoalScreen> createState() => _EditGoalScreenState();
}

class _EditGoalScreenState extends State<EditGoalScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late DateTime _targetDate;
  late SavingsInstrument _selectedInstrument;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.goal.name);
    _amountController = TextEditingController(
      text: widget.goal.targetAmount.toStringAsFixed(0),
    );
    _targetDate = widget.goal.targetDate;
    _selectedInstrument = widget.goal.instrument;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  GoalTimeline get _timeline => GoalTimelineExtension.fromTargetDate(_targetDate);

  bool get _canSave {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    return name.isNotEmpty && amount > 0;
  }

  bool get _hasChanges {
    final newName = _nameController.text.trim();
    final newAmount = double.tryParse(_amountController.text) ?? 0;
    return newName != widget.goal.name ||
        newAmount != widget.goal.targetAmount ||
        _targetDate != widget.goal.targetDate ||
        _selectedInstrument != widget.goal.instrument;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppTheme.spacing32),
              _buildNameInput(),
              const SizedBox(height: AppTheme.spacing32),
              _buildAmountInput(),
              const SizedBox(height: AppTheme.spacing32),
              _buildDatePicker(),
              const SizedBox(height: AppTheme.spacing32),
              _buildTimelineInfo(),
              const SizedBox(height: AppTheme.spacing24),
              _buildInstrumentSelector(),
              const SizedBox(height: AppTheme.spacing48),
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
          'Edit Goal',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 50),
      ],
    );
  }

  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Goal name',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _nameController,
          style: Theme.of(context).textTheme.titleLarge,
          decoration: InputDecoration(
            hintText: 'e.g., Goa Trip, New Laptop',
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

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target amount',
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target date',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing16,
            ),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(_targetDate),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppTheme.gray400,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing12,
              vertical: AppTheme.spacing6,
            ),
            decoration: BoxDecoration(
              color: AppTheme.black,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              _timeline.label,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Text(
              _timeline.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentSelector() {
    final instruments = _timeline.suggestedInstruments;

    // If current instrument is not in suggested list, add it
    final allInstruments = instruments.contains(_selectedInstrument)
        ? instruments
        : [_selectedInstrument, ...instruments];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where will you save?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing4),
        Text(
          'Recommended for ${_timeline.label.toLowerCase()} goals',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
        const SizedBox(height: AppTheme.spacing16),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: allInstruments.map((instrument) {
            final isSelected = _selectedInstrument == instrument;
            return GestureDetector(
              onTap: () => setState(() => _selectedInstrument = instrument),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing16,
                  vertical: AppTheme.spacing12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.black : AppTheme.white,
                  border: Border.all(
                    color: isSelected ? AppTheme.black : AppTheme.gray200,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  instrument.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? AppTheme.white : AppTheme.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final canSave = _canSave && _hasChanges;
    return AnimatedOpacity(
      opacity: canSave ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        onPressed: canSave ? _save : null,
        child: const Text('Save Changes'),
      ),
    );
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 30)),
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

    if (picked != null) {
      setState(() {
        _targetDate = picked;
        // Reset instrument if not in new timeline's suggested list
        final newTimeline = GoalTimelineExtension.fromTargetDate(picked);
        if (!newTimeline.suggestedInstruments.contains(_selectedInstrument)) {
          _selectedInstrument = newTimeline.suggestedInstruments.first;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    final updatedGoal = widget.goal.copyWith(
      name: name,
      targetAmount: amount,
      targetDate: _targetDate,
      instrument: _selectedInstrument,
    );

    Navigator.pop(context, updatedGoal);
  }
}
