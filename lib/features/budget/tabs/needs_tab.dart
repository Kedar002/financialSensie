import 'package:flutter/material.dart';
import '../../../core/models/needs_category.dart';
import '../../../core/models/needs_template.dart';
import '../../../core/repositories/needs_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import '../sheets/templates_sheet.dart';

class NeedsTab extends StatefulWidget {
  final VoidCallback onMenuTap;

  const NeedsTab({super.key, required this.onMenuTap});

  @override
  State<NeedsTab> createState() => _NeedsTabState();
}

class _NeedsTabState extends State<NeedsTab> {
  final NeedsRepository _repository = NeedsRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  List<NeedsCategory> _categories = [];
  Map<int, int> _spentByCategory = {};
  bool _isLoading = true;
  bool _isSummaryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final categories = await _repository.getAll();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final spent = await _expenseRepository.getSpentByCategory(
      'needs',
      start: monthStart,
      end: monthEnd,
    );
    setState(() {
      _categories = categories;
      _spentByCategory = spent;
      _isLoading = false;
    });
  }

  Future<void> _loadCategories() async {
    await _loadData();
  }

  int get _totalBudget {
    return _categories.fold(0, (sum, cat) => sum + cat.amount);
  }

  int get _totalSpent {
    // _spentByCategory values are in paise, convert to rupees
    return (_spentByCategory.values.fold(0, (sum, val) => sum + val) / 100).round();
  }

  int get _remaining {
    return _totalBudget - _totalSpent;
  }

  double get _spentProgress {
    if (_totalBudget <= 0) return 0.0;
    return (_totalSpent / _totalBudget).clamp(0.0, 1.0);
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
                    onTap: () => _showTemplates(context),
                    child: const Icon(
                      Icons.file_copy_outlined,
                      size: 24,
                      color: Color(0xFF007AFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showAddCategory(context),
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
                        // Summary Card (Expandable)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isSummaryExpanded = !_isSummaryExpanded;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row with title and expand indicator
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Needs',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                    AnimatedRotation(
                                      turns: _isSummaryExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 250),
                                      child: const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 20,
                                        color: Color(0xFFC7C7CC),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Main amount (Remaining when collapsed, Budget when expanded)
                                Text(
                                  '₹${_formatAmount(_isSummaryExpanded ? _totalBudget : _remaining)}',
                                  style: TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                    color: _remaining < 0 && !_isSummaryExpanded
                                        ? const Color(0xFFFF3B30)
                                        : Colors.black,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isSummaryExpanded
                                      ? 'Total budget'
                                      : 'remaining of ₹${_formatAmount(_totalBudget)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),

                                // Expanded content
                                AnimatedCrossFade(
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Column(
                                    children: [
                                      const SizedBox(height: 24),

                                      // Budget breakdown
                                      _SummaryRow(
                                        label: 'Spent',
                                        amount: _totalSpent,
                                        color: Colors.black,
                                        formatAmount: _formatAmount,
                                      ),
                                      const SizedBox(height: 12),
                                      _SummaryRow(
                                        label: 'Remaining',
                                        amount: _remaining,
                                        color: _remaining >= 0
                                            ? const Color(0xFF34C759)
                                            : const Color(0xFFFF3B30),
                                        formatAmount: _formatAmount,
                                        isBold: true,
                                      ),

                                      const SizedBox(height: 20),

                                      // Progress bar
                                      Container(
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F2F7),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _spentProgress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _remaining >= 0
                                                  ? const Color(0xFF007AFF)
                                                  : const Color(0xFFFF3B30),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Progress text
                                      Text(
                                        _totalBudget > 0
                                            ? '${(_spentProgress * 100).round()}% of budget used'
                                            : 'No budget set',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ],
                                  ),
                                  crossFadeState: _isSummaryExpanded
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 250),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Categories Grid or Empty State
                        if (_categories.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.folder_outlined,
                                  size: 48,
                                  color: Color(0xFFC7C7CC),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No categories yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _showAddCategory(context),
                                  child: const Text(
                                    'Add your first category',
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
                              childAspectRatio: 1.4,
                            ),
                            itemCount: _categories.length,
                            itemBuilder: (context, index) {
                              final cat = _categories[index];
                              final spent = _spentByCategory[cat.id] ?? 0;
                              return GestureDetector(
                                onTap: () => _showEditCategory(context, cat),
                                child: _CategoryCard(
                                  name: cat.name,
                                  budget: cat.amount,
                                  spent: spent,
                                  icon: _getIconData(cat.icon),
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

  void _showAddCategory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddCategorySheet(
        onSave: (name, amount, icon) async {
          final category = NeedsCategory(
            name: name,
            amount: amount,
            icon: icon,
          );
          await _repository.insert(category);
          await _loadCategories();
        },
      ),
    );
  }

  void _showEditCategory(BuildContext context, NeedsCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditCategorySheet(
        category: category,
        onSave: (name, amount, icon) async {
          final updated = category.copyWith(
            name: name,
            amount: amount,
            icon: icon,
          );
          await _repository.update(updated);
          await _loadCategories();
        },
        onDelete: () async {
          await _repository.delete(category.id!);
          await _loadCategories();
        },
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TemplatesSheet(
        onTemplateImported: (template) => _importTemplate(context, template),
      ),
    );
  }

  Future<void> _importTemplate(BuildContext context, NeedsTemplate template) async {
    for (final item in template.items) {
      final category = NeedsCategory(
        name: item.name,
        amount: item.amount,
        icon: 'category_outlined',
      );
      await _repository.insert(category);
    }
    await _loadCategories();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${template.items.length} items imported'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
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
      case 'home_outlined':
        return Icons.home_outlined;
      case 'shopping_cart_outlined':
        return Icons.shopping_cart_outlined;
      case 'bolt_outlined':
        return Icons.bolt_outlined;
      case 'security_outlined':
        return Icons.security_outlined;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      case 'medical_services_outlined':
        return Icons.medical_services_outlined;
      case 'school_outlined':
        return Icons.school_outlined;
      case 'phone_outlined':
        return Icons.phone_outlined;
      case 'wifi_outlined':
        return Icons.wifi_outlined;
      case 'water_drop_outlined':
        return Icons.water_drop_outlined;
      case 'savings_outlined':
        return Icons.savings_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

class _AddCategorySheet extends StatefulWidget {
  final Future<void> Function(String name, int amount, String icon) onSave;

  const _AddCategorySheet({required this.onSave});

  @override
  State<_AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<_AddCategorySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedIcon = 'category_outlined';

  final List<Map<String, dynamic>> _icons = [
    {'name': 'home_outlined', 'icon': Icons.home_outlined, 'label': 'Home'},
    {'name': 'shopping_cart_outlined', 'icon': Icons.shopping_cart_outlined, 'label': 'Groceries'},
    {'name': 'bolt_outlined', 'icon': Icons.bolt_outlined, 'label': 'Utilities'},
    {'name': 'security_outlined', 'icon': Icons.security_outlined, 'label': 'Insurance'},
    {'name': 'directions_car_outlined', 'icon': Icons.directions_car_outlined, 'label': 'Transport'},
    {'name': 'medical_services_outlined', 'icon': Icons.medical_services_outlined, 'label': 'Health'},
    {'name': 'school_outlined', 'icon': Icons.school_outlined, 'label': 'Education'},
    {'name': 'phone_outlined', 'icon': Icons.phone_outlined, 'label': 'Phone'},
    {'name': 'savings_outlined', 'icon': Icons.savings_outlined, 'label': 'Buffer'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Add Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
                              color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
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
                              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Name field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Category name',
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

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Budget amount',
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
                  if (name.isEmpty) return;

                  final amount = int.tryParse(_amountController.text) ?? 0;
                  await widget.onSave(name, amount, _selectedIcon);
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
    );
  }
}

class _EditCategorySheet extends StatefulWidget {
  final NeedsCategory category;
  final Future<void> Function(String name, int amount, String icon) onSave;
  final Future<void> Function() onDelete;

  const _EditCategorySheet({
    required this.category,
    required this.onSave,
    required this.onDelete,
  });

  @override
  State<_EditCategorySheet> createState() => _EditCategorySheetState();
}

class _EditCategorySheetState extends State<_EditCategorySheet> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late String _selectedIcon;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'home_outlined', 'icon': Icons.home_outlined, 'label': 'Home'},
    {'name': 'shopping_cart_outlined', 'icon': Icons.shopping_cart_outlined, 'label': 'Groceries'},
    {'name': 'bolt_outlined', 'icon': Icons.bolt_outlined, 'label': 'Utilities'},
    {'name': 'security_outlined', 'icon': Icons.security_outlined, 'label': 'Insurance'},
    {'name': 'directions_car_outlined', 'icon': Icons.directions_car_outlined, 'label': 'Transport'},
    {'name': 'medical_services_outlined', 'icon': Icons.medical_services_outlined, 'label': 'Health'},
    {'name': 'school_outlined', 'icon': Icons.school_outlined, 'label': 'Education'},
    {'name': 'phone_outlined', 'icon': Icons.phone_outlined, 'label': 'Phone'},
    {'name': 'savings_outlined', 'icon': Icons.savings_outlined, 'label': 'Buffer'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category.name);
    _amountController = TextEditingController(
      text: widget.category.amount > 0 ? widget.category.amount.toString() : '',
    );
    _selectedIcon = widget.category.icon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Edit Category',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
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
                              color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
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
                              color: isSelected ? Colors.black : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Name field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Category name',
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

              // Amount field
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Budget amount',
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
                  if (name.isEmpty) return;

                  final amount = int.tryParse(_amountController.text) ?? 0;
                  await widget.onSave(name, amount, _selectedIcon);
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

              const SizedBox(height: 12),

              // Delete button
              GestureDetector(
                onTap: () async {
                  await widget.onDelete();
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'Delete',
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
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final String Function(int) formatAmount;
  final bool isBold;

  const _SummaryRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.formatAmount,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF8E8E93),
          ),
        ),
        Text(
          '₹${formatAmount(amount.abs())}${amount < 0 ? ' over' : ''}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String name;
  final int budget;
  final int spent;
  final IconData icon;

  const _CategoryCard({
    required this.name,
    required this.budget,
    required this.spent,
    required this.icon,
  });

  String _formatAmount(int amount) {
    // Amount is in paise, convert to rupees
    final rupees = amount / 100;
    if (rupees == rupees.truncate()) {
      return rupees.truncate().toString();
    }
    return rupees.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final budgetInPaise = budget * 100; // Convert budget to paise for comparison
    final progress = budgetInPaise > 0 ? (spent / budgetInPaise).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > budgetInPaise && budget > 0;

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
                  color: isOverBudget ? const Color(0xFFFFE5E5) : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isOverBudget ? const Color(0xFFFF3B30) : Colors.black87,
                ),
              ),
              const Spacer(),
              if (budget > 0)
                Text(
                  '₹${_formatAmount(spent)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isOverBudget ? const Color(0xFFFF3B30) : Colors.black87,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            budget > 0 ? '₹$budget budget' : 'No budget',
            style: TextStyle(
              fontSize: 12,
              color: budget > 0 ? const Color(0xFF8E8E93) : const Color(0xFFC7C7CC),
            ),
          ),
          if (budget > 0) ...[
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
                    color: isOverBudget ? const Color(0xFFFF3B30) : const Color(0xFF34C759),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
