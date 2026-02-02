import 'package:flutter/material.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/savings_goal.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/repositories/savings_repository.dart';

class GoalDetailsScreen extends StatefulWidget {
  final SavingsGoal goal;

  const GoalDetailsScreen({super.key, required this.goal});

  @override
  State<GoalDetailsScreen> createState() => _GoalDetailsScreenState();
}

class _GoalDetailsScreenState extends State<GoalDetailsScreen> {
  final SavingsRepository _repository = SavingsRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  late SavingsGoal _goal;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  Future<void> _refreshGoal() async {
    final updated = await _repository.getById(_goal.id!);
    if (updated != null) {
      setState(() {
        _goal = updated;
        _hasChanges = true;
      });
    }
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shield_outlined':
        return Icons.shield_outlined;
      case 'flight_outlined':
        return Icons.flight_outlined;
      case 'trending_up_outlined':
        return Icons.trending_up_outlined;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'home_outlined':
        return Icons.home_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'phone_iphone_outlined':
        return Icons.phone_iphone_outlined;
      case 'celebration_outlined':
        return Icons.celebration_outlined;
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActivity = _goal.saved > 0;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, _hasChanges),
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      color: const Color(0xFF007AFF),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _showEditSheet(context),
                      child: const Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Goal header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: hasActivity ? const Color(0xFFE8F5E9) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              _getIconData(_goal.icon),
                              size: 32,
                              color: hasActivity ? const Color(0xFF34C759) : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _goal.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_goal.percentage}% complete',
                            style: TextStyle(
                              fontSize: 15,
                              color: hasActivity ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Progress section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saved',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_formatAmount(_goal.saved)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF34C759),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Target',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${_formatAmount(_goal.target)}',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _goal.progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF34C759),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Details grid
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Monthly',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_formatAmount(_goal.monthly)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Remaining',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₹${_formatAmount(_goal.remaining > 0 ? _goal.remaining : 0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Investment suggestion
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: Color(0xFFFF9500),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _goal.investmentSuggestion,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Time estimate
                    if (_goal.monthly > 0 && _goal.remaining > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.schedule_outlined,
                              size: 20,
                              color: Color(0xFF8E8E93),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_goal.monthsRemaining} months to reach goal',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons row
                    Row(
                      children: [
                        // Add money button
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showAddMoneySheet(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Add Money',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Withdraw button
                        Expanded(
                          child: GestureDetector(
                            onTap: _goal.saved > 0 ? () => _showWithdrawSheet(context) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: _goal.saved > 0 ? Colors.white : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _goal.saved > 0 ? Colors.black : const Color(0xFFE5E5E5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Withdraw',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: _goal.saved > 0 ? Colors.black : const Color(0xFFC7C7CC),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Delete button
                    GestureDetector(
                      onTap: () => _confirmDelete(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Delete Goal',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMoneySheet(BuildContext context) {
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();

    String formatDate(DateTime date) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) return 'Today';
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Add Money',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
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
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final amount = int.tryParse(controller.text) ?? 0;
                      if (amount > 0) {
                        // Create expense record (amount in paise)
                        final expense = Expense(
                          amount: amount * 100,
                          type: 'savings',
                          categoryId: _goal.id,
                          categoryName: _goal.name,
                          note: 'Added to ${_goal.name}',
                          date: selectedDate,
                        );
                        await _expenseRepository.insert(expense);

                        // Update savings goal
                        await _repository.addMoney(_goal.id!, amount);
                        await _refreshGoal();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Add',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final controller = TextEditingController();
    String? errorText;
    DateTime selectedDate = DateTime.now();

    String formatDate(DateTime date) {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly == today) return 'Today';
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Withdraw',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available: ₹${_formatAmount(_goal.saved)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    onChanged: (value) {
                      final amount = int.tryParse(value) ?? 0;
                      setSheetState(() {
                        if (amount > _goal.saved) {
                          errorText = 'Amount exceeds available balance';
                        } else {
                          errorText = null;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: errorText != null
                          ? const Color(0xFFFFE5E5)
                          : const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFFF3B30),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
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
                        setSheetState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formatDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 20,
                            color: Color(0xFF8E8E93),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Info text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF8E8E93),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Withdrawals are recorded but won\'t affect your budget balance',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final amount = int.tryParse(controller.text) ?? 0;
                      if (amount > 0 && amount <= _goal.saved && errorText == null) {
                        // Create withdrawal record (amount in paise)
                        final expense = Expense(
                          amount: amount * 100,
                          type: 'savings_withdrawal',
                          categoryId: _goal.id,
                          categoryName: _goal.name,
                          note: 'Withdrawal from ${_goal.name}',
                          date: selectedDate,
                        );
                        await _expenseRepository.insert(expense);

                        // Decrease savings goal
                        await _repository.withdrawMoney(_goal.id!, amount);

                        await _refreshGoal();
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: errorText != null ? const Color(0xFFC7C7CC) : Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Withdraw',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final nameController = TextEditingController(text: _goal.name);
    final targetController = TextEditingController(text: _goal.target.toString());
    final monthlyController = TextEditingController(text: _goal.monthly > 0 ? _goal.monthly.toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Goal name',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Target amount',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: monthlyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Monthly contribution',
                      prefixText: '₹ ',
                      filled: true,
                      fillColor: const Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) return;

                      final target = int.tryParse(targetController.text) ?? _goal.target;
                      final monthly = int.tryParse(monthlyController.text) ?? 0;

                      final updated = _goal.copyWith(
                        name: name,
                        target: target,
                        monthly: monthly,
                      );

                      await _repository.update(updated);
                      await _refreshGoal();
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Goal?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "${_goal.name}"? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () async {
                    await _repository.delete(_goal.id!);
                    if (context.mounted) {
                      Navigator.pop(context); // Close confirmation
                      Navigator.pop(context, true); // Return to list with refresh flag
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Delete',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Text(
                      'Cancel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
