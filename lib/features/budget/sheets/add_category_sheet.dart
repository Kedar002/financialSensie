import 'package:flutter/material.dart';

class AddCategorySheet extends StatefulWidget {
  final String type; // 'needs', 'wants', 'savings'
  final Function(String name, IconData icon, int amount) onSave;

  const AddCategorySheet({
    super.key,
    required this.type,
    required this.onSave,
  });

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  IconData _selectedIcon = Icons.category_outlined;

  final List<IconData> _availableIcons = [
    Icons.home_outlined,
    Icons.shopping_cart_outlined,
    Icons.bolt_outlined,
    Icons.security_outlined,
    Icons.directions_car_outlined,
    Icons.medical_services_outlined,
    Icons.restaurant_outlined,
    Icons.movie_outlined,
    Icons.shopping_bag_outlined,
    Icons.subscriptions_outlined,
    Icons.spa_outlined,
    Icons.palette_outlined,
    Icons.flight_outlined,
    Icons.school_outlined,
    Icons.fitness_center_outlined,
    Icons.pets_outlined,
    Icons.child_care_outlined,
    Icons.phone_android_outlined,
    Icons.wifi_outlined,
    Icons.local_gas_station_outlined,
    Icons.train_outlined,
    Icons.local_pharmacy_outlined,
    Icons.checkroom_outlined,
    Icons.coffee_outlined,
  ];

  bool get _canSave => _nameController.text.isNotEmpty;

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
              GestureDetector(
                onTap: () => _showIconPicker(),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _selectedIcon,
                    size: 32,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to change icon',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 20),

              // Name field
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                onChanged: (_) => setState(() {}),
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
                  hintText: 'Amount (optional)',
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
                onTap: _canSave
                    ? () {
                        widget.onSave(
                          _nameController.text,
                          _selectedIcon,
                          int.tryParse(_amountController.text) ?? 0,
                        );
                        Navigator.pop(context);
                      }
                    : null,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _canSave ? Colors.black : const Color(0xFFE5E5E5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Save',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _canSave ? Colors.white : const Color(0xFF8E8E93),
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

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5E5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Icon',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: _availableIcons.length,
                itemBuilder: (context, index) {
                  final icon = _availableIcons[index];
                  final isSelected = icon == _selectedIcon;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedIcon = icon);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        size: 24,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
