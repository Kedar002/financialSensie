import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../goals/models/goal.dart';
import '../models/expense.dart';

/// Add/Edit expense screen.
/// Select category, then:
/// - Needs/Wants: Select subcategory from Profile settings
/// - Savings: Select destination (Emergency Fund or a Goal)
class AddExpenseScreen extends StatefulWidget {
  final DateTime date;
  final List<Goal> goals; // User's savings goals
  final Expense? existingExpense; // For edit mode

  const AddExpenseScreen({
    super.key,
    required this.date,
    required this.goals,
    this.existingExpense,
  });

  bool get isEditMode => existingExpense != null;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocusNode = FocusNode();

  ExpenseCategory _selectedCategory = ExpenseCategory.needs;
  ExpenseSubcategory? _selectedSubcategory;
  SavingsDestination? _selectedSavingsDestination;

  @override
  void initState() {
    super.initState();

    if (widget.existingExpense != null) {
      // Edit mode: pre-fill with existing expense data
      final expense = widget.existingExpense!;
      _amountController.text = expense.amount.toStringAsFixed(
        expense.amount.truncateToDouble() == expense.amount ? 0 : 2,
      );
      _noteController.text = expense.note ?? '';
      _selectedCategory = expense.category;
      _selectedSubcategory = expense.subcategory;
      _selectedSavingsDestination = expense.savingsDestination;
    } else {
      // Add mode: set default subcategory for Needs (fixed expenses)
      _selectedSubcategory = ExpenseSubcategory.rentEmi;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
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
    if (amount <= 0) return false;

    if (_selectedCategory == ExpenseCategory.savings) {
      return _selectedSavingsDestination != null;
    }
    return _selectedSubcategory != null;
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
              const SizedBox(height: AppTheme.spacing32),
              _buildCategorySelector(),
              const SizedBox(height: AppTheme.spacing24),
              if (_selectedCategory == ExpenseCategory.savings)
                _buildSavingsDestinationSelector()
              else
                _buildSubcategorySelector(),
              const SizedBox(height: AppTheme.spacing32),
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
          widget.isEditMode ? 'Edit Expense' : _getDateLabel(),
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

  Widget _buildCategorySelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: ExpenseCategory.values.map((category) {
          final isSelected = _selectedCategory == category;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                  if (category == ExpenseCategory.savings) {
                    // Default to Emergency Fund for savings
                    _selectedSubcategory = null;
                    _selectedSavingsDestination = SavingsDestination.emergencyFund();
                  } else if (category == ExpenseCategory.needs) {
                    // Default to first fixed expense (Rent/EMI)
                    _selectedSubcategory = ExpenseSubcategory.rentEmi;
                    _selectedSavingsDestination = null;
                  } else {
                    // Wants: Default to first variable budget item (Food & Dining)
                    _selectedSubcategory = ExpenseSubcategory.foodDining;
                    _selectedSavingsDestination = null;
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppTheme.white : AppTheme.gray600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubcategorySelector() {
    final subcategories = ExpenseSubcategory.forCategory(_selectedCategory);

    // Needs: Use chips (only 3 options)
    // Wants: Use dropdown (6 options)
    if (_selectedCategory == ExpenseCategory.needs) {
      return _buildSubcategoryChips(subcategories);
    } else {
      return _buildSubcategoryDropdown(subcategories);
    }
  }

  Widget _buildSubcategoryChips(List<ExpenseSubcategory> subcategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Wrap(
          spacing: AppTheme.spacing8,
          runSpacing: AppTheme.spacing8,
          children: subcategories.map((sub) {
            final isSelected = _selectedSubcategory == sub;
            return GestureDetector(
              onTap: () => setState(() => _selectedSubcategory = sub),
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
                  sub.label,
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

  Widget _buildSubcategoryDropdown(List<ExpenseSubcategory> subcategories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            border: Border.all(color: AppTheme.gray200),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ExpenseSubcategory>(
              value: _selectedSubcategory,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.gray600),
              style: Theme.of(context).textTheme.bodyLarge,
              dropdownColor: AppTheme.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              items: subcategories.map((sub) {
                return DropdownMenuItem<ExpenseSubcategory>(
                  value: sub,
                  child: Text(sub.label),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSubcategory = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsDestinationSelector() {
    // Build list of savings destinations: Emergency Fund + all goals
    final destinations = <_SavingsOption>[
      _SavingsOption(
        destination: SavingsDestination.emergencyFund(),
        label: 'Emergency Fund',
        subtitle: 'Safety net',
      ),
      ...widget.goals.map((goal) => _SavingsOption(
            destination: SavingsDestination.goal(
              goalId: goal.id,
              goalName: goal.name,
            ),
            label: goal.name,
            subtitle: goal.timeline.label,
          )),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add to',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: AppTheme.spacing12),
        if (destinations.length == 1)
          // Only Emergency Fund, no goals
          Column(
            children: [
              _buildSavingsDestinationChip(destinations.first),
              const SizedBox(height: AppTheme.spacing16),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacing12),
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.gray500),
                    const SizedBox(width: AppTheme.spacing8),
                    Expanded(
                      child: Text(
                        'Create goals in the Goals tab to save for specific things',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.gray500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: AppTheme.spacing8,
            runSpacing: AppTheme.spacing8,
            children: destinations.map((option) => _buildSavingsDestinationChip(option)).toList(),
          ),
      ],
    );
  }

  Widget _buildSavingsDestinationChip(_SavingsOption option) {
    final isSelected = _selectedSavingsDestination != null &&
        ((_selectedSavingsDestination!.isEmergencyFund && option.destination.isEmergencyFund) ||
            (_selectedSavingsDestination!.isGoal &&
                option.destination.isGoal &&
                _selectedSavingsDestination!.goalId == option.destination.goalId));

    return GestureDetector(
      onTap: () => setState(() => _selectedSavingsDestination = option.destination),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.white : AppTheme.black,
              ),
            ),
            if (option.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                option.subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? AppTheme.gray200 : AppTheme.gray500,
                ),
              ),
            ],
          ],
        ),
      ),
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
        child: Text(widget.isEditMode ? 'Save Changes' : 'Done'),
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

    final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

    Expense expense;

    if (widget.isEditMode) {
      // Edit mode: update existing expense
      final existing = widget.existingExpense!;
      if (_selectedCategory == ExpenseCategory.savings) {
        if (_selectedSavingsDestination == null) return;
        expense = Expense(
          id: existing.id,
          amount: amount,
          category: ExpenseCategory.savings,
          savingsDestination: _selectedSavingsDestination,
          note: note,
          date: existing.date,
          createdAt: existing.createdAt,
        );
      } else {
        if (_selectedSubcategory == null) return;
        expense = Expense(
          id: existing.id,
          amount: amount,
          category: _selectedCategory,
          subcategory: _selectedSubcategory,
          note: note,
          date: existing.date,
          createdAt: existing.createdAt,
        );
      }
    } else {
      // Add mode: create new expense
      if (_selectedCategory == ExpenseCategory.savings) {
        if (_selectedSavingsDestination == null) return;
        expense = Expense.createSavings(
          amount: amount,
          destination: _selectedSavingsDestination!,
          note: note,
          date: widget.date,
        );
      } else {
        if (_selectedSubcategory == null) return;
        expense = Expense.create(
          amount: amount,
          category: _selectedCategory,
          subcategory: _selectedSubcategory!,
          note: note,
          date: widget.date,
        );
      }
    }

    Navigator.pop(context, expense);
  }
}

/// Helper class for savings destination options.
class _SavingsOption {
  final SavingsDestination destination;
  final String label;
  final String? subtitle;

  const _SavingsOption({
    required this.destination,
    required this.label,
    this.subtitle,
  });
}
