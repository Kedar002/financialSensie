import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/needs_category.dart';
import '../../../core/models/wants_category.dart';
import '../../../core/models/savings_goal.dart';
import '../../../core/repositories/needs_repository.dart';
import '../../../core/repositories/wants_repository.dart';
import '../../../core/repositories/savings_repository.dart';
import '../../../core/repositories/expense_repository.dart';

class AddExpenseSheet extends StatefulWidget {
  final String? preselectedType;
  final Expense? expense; // For editing
  final VoidCallback? onSaved;

  const AddExpenseSheet({
    super.key,
    this.preselectedType,
    this.expense,
    this.onSaved,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amount = '';
  String _selectedType = 'needs';
  Map<String, dynamic>? _selectedCategory;
  final _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final NeedsRepository _needsRepository = NeedsRepository();
  final WantsRepository _wantsRepository = WantsRepository();
  final SavingsRepository _savingsRepository = SavingsRepository();

  List<NeedsCategory> _needsCategories = [];
  List<WantsCategory> _wantsCategories = [];
  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = true;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
    if (widget.expense != null) {
      // Convert from cents to display format
      final displayAmount = widget.expense!.amount / 100;
      if (displayAmount == displayAmount.truncate()) {
        _amount = displayAmount.truncate().toString();
      } else {
        _amount = displayAmount.toStringAsFixed(2);
      }
      _selectedType = widget.expense!.type;
      _noteController.text = widget.expense!.note ?? '';
      _selectedDate = widget.expense!.date;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final needs = await _needsRepository.getAll();
    final wants = await _wantsRepository.getAll();
    final savings = await _savingsRepository.getAll();

    setState(() {
      _needsCategories = needs;
      _wantsCategories = wants;
      _savingsGoals = savings;
      _isLoading = false;

      // If editing, find the matching category
      if (widget.expense != null) {
        _findSelectedCategory();
      }
    });
  }

  void _findSelectedCategory() {
    final expense = widget.expense!;
    if (expense.type == 'needs') {
      final cat = _needsCategories.where((c) => c.id == expense.categoryId).firstOrNull;
      if (cat != null) {
        _selectedCategory = {'id': cat.id, 'name': cat.name};
      }
    } else if (expense.type == 'wants') {
      final cat = _wantsCategories.where((c) => c.id == expense.categoryId).firstOrNull;
      if (cat != null) {
        _selectedCategory = {'id': cat.id, 'name': cat.name};
      }
    } else if (expense.type == 'savings') {
      final goal = _savingsGoals.where((g) => g.id == expense.categoryId).firstOrNull;
      if (goal != null) {
        _selectedCategory = {'id': goal.id, 'name': goal.name, 'saved': goal.saved};
      }
    }
  }

  List<Map<String, dynamic>> get _currentCategories {
    switch (_selectedType) {
      case 'needs':
        return _needsCategories.map((c) => {'id': c.id, 'name': c.name}).toList();
      case 'wants':
        return _wantsCategories.map((c) => {'id': c.id, 'name': c.name}).toList();
      case 'savings':
        // Include saved amount for validation
        return _savingsGoals.map((g) => {
          'id': g.id,
          'name': g.name,
          'saved': g.saved,
        }).toList();
      default:
        return [];
    }
  }

  // Get the available saved amount for selected savings goal
  int? get _selectedSavingsAvailable {
    if (_selectedType != 'savings' || _selectedCategory == null) return null;
    return _selectedCategory!['saved'] as int?;
  }

  // Validate if the amount exceeds available savings
  // Note: savings goals store amounts in rupees, expenses store in paise
  String? get _savingsValidationError {
    if (_selectedType != 'savings') return null;
    if (_selectedCategory == null) return null;
    if (_amount.isEmpty) return null;

    final amountInRupees = double.tryParse(_amount) ?? 0;
    final availableSavedRupees = _selectedCategory!['saved'] as int? ?? 0;

    if (amountInRupees > availableSavedRupees) {
      return 'Only ₹${_formatAmount(availableSavedRupees)} available in this goal';
    }
    return null;
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    HapticFeedback.lightImpact();
    setState(() {
      if (key == '⌫') {
        if (_amount.isNotEmpty) {
          _amount = _amount.substring(0, _amount.length - 1);
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount = _amount.isEmpty ? '0.' : '$_amount.';
        }
      } else {
        if (_amount.contains('.')) {
          final parts = _amount.split('.');
          if (parts[1].length < 2) {
            _amount += key;
          }
        } else if (_amount.length < 7) {
          _amount += key;
        }
      }
    });
  }

  String get _displayAmount {
    if (_amount.isEmpty) return '0';
    return _amount;
  }

  Future<void> _save() async {
    if (_amount.isEmpty) return;

    // Validate savings spending
    if (_savingsValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_savingsValidationError!),
          backgroundColor: const Color(0xFFFF3B30),
        ),
      );
      return;
    }

    final amount = (double.tryParse(_amount) ?? 0) * 100;
    final amountInt = amount.round();

    final expense = Expense(
      id: widget.expense?.id,
      amount: amountInt,
      type: _selectedType,
      categoryId: _selectedCategory?['id'] as int?,
      categoryName: _selectedCategory?['name'] as String? ?? 'Uncategorized',
      note: _noteController.text.isEmpty ? null : _noteController.text,
      date: _selectedDate,
    );

    if (_isEditing) {
      // For editing savings expenses, we need to handle the difference
      // Note: expense amounts are in paise, savings goals are in rupees
      if (_selectedType == 'savings' && widget.expense?.type == 'savings') {
        final oldAmountRupees = (widget.expense!.amount / 100).round();
        final newAmountRupees = (amountInt / 100).round();
        final differenceRupees = newAmountRupees - oldAmountRupees;
        if (differenceRupees != 0 && _selectedCategory?['id'] != null) {
          final goalId = _selectedCategory!['id'] as int;
          final goal = await _savingsRepository.getById(goalId);
          if (goal != null) {
            // Deduct the difference (positive = more spent, negative = refund)
            final newSaved = goal.saved - differenceRupees;
            if (newSaved < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Not enough saved amount for this change'),
                  backgroundColor: Color(0xFFFF3B30),
                ),
              );
              return;
            }
            await _savingsRepository.update(goal.copyWith(saved: newSaved));
          }
        }
      }

      await _expenseRepository.update(expense);
    } else {
      await _expenseRepository.insert(expense);

      // Deduct from savings goal if spending from savings
      // Note: expense amounts are in paise, savings goals are in rupees
      if (_selectedType == 'savings' && _selectedCategory?['id'] != null) {
        final goalId = _selectedCategory!['id'] as int;
        final goal = await _savingsRepository.getById(goalId);
        if (goal != null) {
          final deductRupees = (amountInt / 100).round();
          final newSaved = goal.saved - deductRupees;
          await _savingsRepository.update(goal.copyWith(saved: newSaved));
        }
      }

    }

    widget.onSaved?.call();
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String get _formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';

    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_selectedDate.day} ${months[_selectedDate.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 17,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ),
                Text(
                  _isEditing ? 'Edit Expense' : 'Add Expense',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _amount.isNotEmpty && _savingsValidationError == null ? _save : null,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _amount.isNotEmpty && _savingsValidationError == null
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFD1D1D6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFAEAEB2),
                  ),
                ),
              ),
              Text(
                _displayAmount,
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: _savingsValidationError != null
                      ? const Color(0xFFFF3B30)
                      : Colors.black,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),

          // Savings validation error
          if (_savingsValidationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _savingsValidationError!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),

          // Available balance hint for savings
          if (_selectedType == 'savings' && _selectedCategory != null && _savingsValidationError == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '₹${_formatAmount(_selectedSavingsAvailable ?? 0)} available',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF34C759),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Type selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Row(
              children: [
                _buildTypeButton('Needs', 'needs'),
                const SizedBox(width: 8),
                _buildTypeButton('Wants', 'wants'),
                const SizedBox(width: 8),
                _buildTypeButton('Savings', 'savings'),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Date selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formattedDate,
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: Color(0xFFD1D1D6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _isLoading ? null : _showCategoryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isLoading
                          ? 'Loading...'
                          : (_selectedCategory?['name'] as String?) ?? 'Category',
                      style: TextStyle(
                        fontSize: 17,
                        color: _selectedCategory != null
                            ? Colors.black
                            : const Color(0xFFAEAEB2),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFFD1D1D6),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Note
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Note',
                hintStyle: const TextStyle(
                  color: Color(0xFFAEAEB2),
                  fontSize: 17,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF007AFF)),
                ),
              ),
            ),
          ),

          const Spacer(),

          // Keypad
          Container(
            color: const Color(0xFFF7F7F7),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  _buildKeypadRow(['4', '5', '6']),
                  _buildKeypadRow(['7', '8', '9']),
                  _buildKeypadRow(['.', '0', '⌫']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(String label, String value) {
    final isSelected = _selectedType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedType = value;
            _selectedCategory = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.black : const Color(0xFFE5E5E5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = _currentCategories;

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No ${_selectedType} categories yet. Add some first.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                _selectedType == 'savings' ? 'Withdraw From' : 'Category',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              ...categories.map((cat) {
                final savedAmount = cat['saved'] as int?;
                final hasNoFunds = _selectedType == 'savings' && (savedAmount == null || savedAmount == 0);

                return Column(
                    children: [
                      GestureDetector(
                        onTap: hasNoFunds ? null : () {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                          child: Column(
                            children: [
                              Text(
                                cat['name'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: hasNoFunds
                                      ? const Color(0xFFC7C7CC)
                                      : _selectedCategory?['name'] == cat['name']
                                          ? const Color(0xFF007AFF)
                                          : Colors.black,
                                ),
                              ),
                              if (_selectedType == 'savings' && savedAmount != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    hasNoFunds
                                        ? 'No funds available'
                                        : '₹${_formatAmount(savedAmount)} available',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: hasNoFunds
                                          ? const Color(0xFFC7C7CC)
                                          : const Color(0xFF34C759),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (cat != categories.last)
                        const Divider(height: 1, color: Color(0xFFF2F2F2)),
                    ],
                  );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _onKeyPress(key),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              child: key == '⌫'
                  ? const Icon(
                      Icons.backspace_outlined,
                      size: 22,
                      color: Colors.black,
                    )
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
