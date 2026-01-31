import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BudgetCalculatorScreen extends StatefulWidget {
  final VoidCallback onBack;

  const BudgetCalculatorScreen({super.key, required this.onBack});

  @override
  State<BudgetCalculatorScreen> createState() => _BudgetCalculatorScreenState();
}

class _BudgetCalculatorScreenState extends State<BudgetCalculatorScreen> {
  final _incomeController = TextEditingController();

  double? _needs;
  double? _wants;
  double? _savings;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text);

    if (income == null || income <= 0) {
      setState(() {
        _needs = null;
        _wants = null;
        _savings = null;
      });
      return;
    }

    // 50-30-20 Rule
    // 50% for Needs (essentials)
    // 30% for Wants (discretionary)
    // 20% for Savings
    setState(() {
      _needs = income * 0.50;
      _wants = income * 0.30;
      _savings = income * 0.20;
    });
  }

  void _clear() {
    _incomeController.clear();
    setState(() {
      _needs = null;
      _wants = null;
      _savings = null;
    });
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(2)} L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)} K';
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: widget.onBack,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Budget Planner',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      '50-30-20 Rule',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF888888),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Monthly Income Input
                    _InputField(
                      label: 'Monthly Income',
                      hint: 'Enter your income',
                      controller: _incomeController,
                      onChanged: (_) => _calculate(),
                    ),

                    const SizedBox(height: 56),

                    // Results
                    if (_needs != null) ...[
                      _AllocationCard(
                        needs: _needs!,
                        wants: _wants!,
                        savings: _savings!,
                        formatCurrency: _formatCurrency,
                      ),

                      const SizedBox(height: 32),

                      // Clear button
                      Center(
                        child: GestureDetector(
                          onTap: _clear,
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '₹',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFCCCCCC),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: const Color(0xFFEEEEEE),
        ),
      ],
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final double needs;
  final double wants;
  final double savings;
  final String Function(double) formatCurrency;

  const _AllocationCard({
    required this.needs,
    required this.wants,
    required this.savings,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Visual bar
        _AllocationBar(
          needs: needs,
          wants: wants,
          savings: savings,
        ),

        const SizedBox(height: 40),

        // Allocation items
        _AllocationItem(
          label: 'Needs',
          description: 'Essentials like rent, groceries, bills',
          amount: '₹${formatCurrency(needs)}',
          percentage: '50%',
          color: const Color(0xFF1A1A1A),
        ),

        const SizedBox(height: 24),

        _AllocationItem(
          label: 'Wants',
          description: 'Dining, entertainment, shopping',
          amount: '₹${formatCurrency(wants)}',
          percentage: '30%',
          color: const Color(0xFF666666),
        ),

        const SizedBox(height: 24),

        _AllocationItem(
          label: 'Savings',
          description: 'Investments, emergency fund, debt',
          amount: '₹${formatCurrency(savings)}',
          percentage: '20%',
          color: const Color(0xFFAAAAAA),
        ),
      ],
    );
  }
}

class _AllocationBar extends StatelessWidget {
  final double needs;
  final double wants;
  final double savings;

  const _AllocationBar({
    required this.needs,
    required this.wants,
    required this.savings,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            Flexible(
              flex: 50,
              child: Container(color: const Color(0xFF1A1A1A)),
            ),
            Flexible(
              flex: 30,
              child: Container(color: const Color(0xFF666666)),
            ),
            Flexible(
              flex: 20,
              child: Container(color: const Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationItem extends StatelessWidget {
  final String label;
  final String description;
  final String amount;
  final String percentage;
  final Color color;

  const _AllocationItem({
    required this.label,
    required this.description,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color indicator
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 16),

        // Label and description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    percentage,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),

        // Amount
        Text(
          amount,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
