import 'package:flutter/material.dart';
import '../../../core/models/savings_goal.dart';
import '../../../core/repositories/savings_repository.dart';
import '../screens/goal_details_screen.dart';

class SavingsTab extends StatefulWidget {
  final VoidCallback onMenuTap;

  const SavingsTab({super.key, required this.onMenuTap});

  @override
  State<SavingsTab> createState() => _SavingsTabState();
}

class _SavingsTabState extends State<SavingsTab> {
  final SavingsRepository _repository = SavingsRepository();
  List<SavingsGoal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _repository.getAll();
    setState(() {
      _goals = goals;
      _isLoading = false;
    });
  }

  int get _totalSaved => _goals.fold(0, (sum, goal) => sum + goal.saved);

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF2F2F7),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onMenuTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.menu, size: 20, color: Colors.black),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showAddGoal(context),
                    child: const Icon(
                      Icons.add,
                      size: 28,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Title Card
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Total Saved',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${_formatAmount(_totalSaved)}',
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF34C759),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Goals',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                    Text(
                                      '${_goals.length}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Goals Grid or Empty State
                        if (_goals.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.savings_outlined,
                                  size: 48,
                                  color: Color(0xFFC7C7CC),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No savings goals yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showAddGoal(context),
                                  child: const Text(
                                    'Create your first goal',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF007AFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: _goals.length,
                            itemBuilder: (context, index) {
                              final goal = _goals[index];
                              return GestureDetector(
                                onTap: () => _showGoalDetails(context, goal),
                                child: _SavingsCard(
                                  name: goal.name,
                                  target: goal.target,
                                  saved: goal.saved,
                                  icon: _getIconData(goal.icon),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddGoalSheet(
        onSave: (goal) async {
          await _repository.insert(goal);
          await _loadGoals();
        },
      ),
    );
  }

  void _showGoalDetails(BuildContext context, SavingsGoal goal) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailsScreen(goal: goal),
      ),
    );
    if (result == true) {
      await _loadGoals();
    }
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
}

class _SavingsCard extends StatelessWidget {
  final String name;
  final int target;
  final int saved;
  final IconData icon;

  const _SavingsCard({
    required this.name,
    required this.target,
    required this.saved,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (saved / target).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();
    final hasActivity = saved > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasActivity ? const Color(0xFFE8F5E9) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: hasActivity ? const Color(0xFF34C759) : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: hasActivity ? const Color(0xFF34C759) : const Color(0xFFC7C7CC),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            hasActivity ? '₹$saved / ₹$target' : 'No savings yet',
            style: TextStyle(
              fontSize: 13,
              color: hasActivity ? Colors.black54 : const Color(0xFFC7C7CC),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF34C759),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(SavingsGoal goal) onSave;

  const _AddGoalSheet({required this.onSave});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _monthlyController = TextEditingController();
  DateTime? _targetDate;
  String _selectedIcon = 'savings_outlined';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'shield_outlined', 'icon': Icons.shield_outlined, 'label': 'Emergency'},
    {'name': 'flight_outlined', 'icon': Icons.flight_outlined, 'label': 'Travel'},
    {'name': 'trending_up_outlined', 'icon': Icons.trending_up_outlined, 'label': 'Invest'},
    {'name': 'directions_car_outlined', 'icon': Icons.directions_car_outlined, 'label': 'Car'},
    {'name': 'home_outlined', 'icon': Icons.home_outlined, 'label': 'Home'},
    {'name': 'school_outlined', 'icon': Icons.school_outlined, 'label': 'Education'},
    {'name': 'phone_iphone_outlined', 'icon': Icons.phone_iphone_outlined, 'label': 'Gadget'},
    {'name': 'celebration_outlined', 'icon': Icons.celebration_outlined, 'label': 'Event'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: DateTime(now.year + 50),
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
      setState(() => _targetDate = picked);
    }
  }

  String get _formattedDate {
    if (_targetDate == null) return 'Select date';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${_targetDate!.day} ${months[_targetDate!.month - 1]} ${_targetDate!.year}';
  }

  Map<String, dynamic>? get _investmentSuggestion {
    if (_targetDate == null) return null;

    final now = DateTime.now();
    final difference = _targetDate!.difference(now);
    final years = difference.inDays / 365;

    if (years < 1) {
      return {
        'title': 'Short-term (< 1 year)',
        'suggestion': 'Savings Account or Cash',
        'description': 'Keep funds liquid and easily accessible. Consider a high-yield savings account.',
        'icon': Icons.savings_outlined,
        'color': const Color(0xFF34C759),
      };
    } else if (years <= 5) {
      return {
        'title': 'Medium-term (1-5 years)',
        'suggestion': 'Fixed Deposit or Debt Mutual Funds',
        'description': 'Balance safety with better returns. FDs offer guaranteed returns.',
        'icon': Icons.account_balance_outlined,
        'color': const Color(0xFF007AFF),
      };
    } else {
      return {
        'title': 'Long-term (> 5 years)',
        'suggestion': 'Equity Mutual Funds or Index Funds',
        'description': 'Time is on your side. Equity investments historically outperform over long periods.',
        'icon': Icons.trending_up_outlined,
        'color': const Color(0xFFFF9500),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = _investmentSuggestion;

    return Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5E5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'New Savings Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Icon selector
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _icons.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final iconData = _icons[index];
                      final isSelected = _selectedIcon == iconData['name'];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = iconData['name']),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF34C759) : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                iconData['icon'],
                                size: 24,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData['label'],
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Goal name
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Goal name (e.g. Emergency Fund)',
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

                // Target amount
                TextField(
                  controller: _amountController,
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

                // Target date
                GestureDetector(
                  onTap: _selectDate,
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
                          _formattedDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: _targetDate != null ? Colors.black : const Color(0xFF8E8E93),
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

                // Investment suggestion
                if (suggestion != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: (suggestion['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          suggestion['icon'] as IconData,
                          size: 20,
                          color: suggestion['color'] as Color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion['suggestion'] as String,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                suggestion['title'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Monthly contribution
                TextField(
                  controller: _monthlyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Monthly contribution (optional)',
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

                // Save button
                GestureDetector(
                  onTap: () async {
                    final name = _nameController.text.trim();
                    if (name.isEmpty || _targetDate == null) return;

                    final target = int.tryParse(_amountController.text) ?? 0;
                    final monthly = int.tryParse(_monthlyController.text) ?? 0;

                    final goal = SavingsGoal(
                      name: name,
                      target: target,
                      monthly: monthly,
                      targetDate: _targetDate!,
                      icon: _selectedIcon,
                    );

                    await widget.onSave(goal);
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
                      'Create Goal',
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
    );
  }
}
