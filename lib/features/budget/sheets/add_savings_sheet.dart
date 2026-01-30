import 'package:flutter/material.dart';

class AddSavingsSheet extends StatefulWidget {
  const AddSavingsSheet({super.key});

  @override
  State<AddSavingsSheet> createState() => _AddSavingsSheetState();
}

class _AddSavingsSheetState extends State<AddSavingsSheet> {
  String _amount = '';
  String? _selectedGoal;

  final List<String> _goals = [
    'Emergency Fund',
    'Vacation',
    'Retirement',
    'Large Purchase',
    'Education',
  ];

  void _onKeyPress(String key) {
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
        } else {
          _amount += key;
        }
      }
    });
  }

  String get _formattedAmount {
    if (_amount.isEmpty) return '₹0';
    return '₹$_amount';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                const Text(
                  'Add to Savings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _amount.isNotEmpty && _selectedGoal != null
                      ? () => Navigator.pop(context)
                      : null,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _amount.isNotEmpty && _selectedGoal != null
                          ? const Color(0xFF007AFF)
                          : const Color(0xFF999999),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Amount display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              _formattedAmount,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                letterSpacing: -1,
              ),
            ),
          ),

          // Goal selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => _showGoalPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedGoal ?? 'Select Goal',
                      style: TextStyle(
                        fontSize: 17,
                        color: _selectedGoal != null
                            ? Colors.black
                            : const Color(0xFF999999),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF999999),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Keypad
          _buildKeypad(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showGoalPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Goal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ..._goals.map((goal) => ListTile(
                    title: Text(goal),
                    trailing: _selectedGoal == goal
                        ? const Icon(Icons.check, color: Color(0xFF007AFF))
                        : null,
                    onTap: () {
                      setState(() => _selectedGoal = goal);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKeypad() {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3']),
          _buildKeypadRow(['4', '5', '6']),
          _buildKeypadRow(['7', '8', '9']),
          _buildKeypadRow(['.', '0', '⌫']),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      children: keys.map((key) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _onKeyPress(key),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              child: key == '⌫'
                  ? const Icon(Icons.backspace_outlined, size: 24)
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
