import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddExpenseSheet extends StatefulWidget {
  final String? preselectedType;

  const AddExpenseSheet({
    super.key,
    this.preselectedType,
  });

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  String _amount = '';
  String _selectedType = 'needs';
  String? _selectedCategory;
  final _noteController = TextEditingController();

  final Map<String, List<String>> _categories = {
    'needs': ['Rent', 'Groceries', 'Utilities', 'Insurance', 'Transport', 'Healthcare'],
    'wants': ['Dining Out', 'Entertainment', 'Shopping', 'Subscriptions', 'Personal Care'],
    'savings': ['Emergency Fund', 'Vacation', 'Retirement', 'Large Purchase'],
  };

  @override
  void initState() {
    super.initState();
    if (widget.preselectedType != null) {
      _selectedType = widget.preselectedType!;
    }
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
                GestureDetector(
                  onTap: _amount.isNotEmpty ? () => Navigator.pop(context) : null,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _amount.isNotEmpty
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFD1D1D6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFAEAEB2),
                  ),
                ),
              ),
              Text(
                _displayAmount,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w300,
                  color: Colors.black,
                  letterSpacing: -2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

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

          const SizedBox(height: 24),

          // Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _showCategoryPicker,
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
                      _selectedCategory ?? 'Category',
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    final categories = _categories[_selectedType] ?? [];
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
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 8),
              ...categories.map((cat) => Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          Navigator.pop(context);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            cat,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: _selectedCategory == cat
                                  ? const Color(0xFF007AFF)
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      if (cat != categories.last)
                        const Divider(height: 1, color: Color(0xFFF2F2F2)),
                    ],
                  )),
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
