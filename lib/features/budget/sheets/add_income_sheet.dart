import 'package:flutter/material.dart';

class AddIncomeSheet extends StatefulWidget {
  const AddIncomeSheet({super.key});

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _frequency = 'monthly';

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameController.text.isNotEmpty && _amountController.text.isNotEmpty;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Add Income Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Name field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _nameController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Salary, Freelance',
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _amountController,
                onChanged: (_) => setState(() {}),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: const Color(0xFFF9F9F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Frequency selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Frequency',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFrequencyChip('Monthly', 'monthly'),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('Bi-weekly', 'biweekly'),
                      const SizedBox(width: 8),
                      _buildFrequencyChip('Variable', 'variable'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave ? () => Navigator.pop(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E5E5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyChip(String label, String value) {
    final isSelected = _frequency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _frequency = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
