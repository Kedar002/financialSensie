import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InterestMethod { reducing, flat }

class EmiCalculatorScreen extends StatefulWidget {
  final VoidCallback onMenuTap;

  const EmiCalculatorScreen({super.key, required this.onMenuTap});

  @override
  State<EmiCalculatorScreen> createState() => _EmiCalculatorScreenState();
}

class _EmiCalculatorScreenState extends State<EmiCalculatorScreen> {
  final _amountController = TextEditingController();
  final _interestController = TextEditingController();
  final _tenureController = TextEditingController();

  InterestMethod _method = InterestMethod.reducing;

  double? _monthlyEmi;
  double? _totalPayment;
  double? _totalInterest;

  @override
  void dispose() {
    _amountController.dispose();
    _interestController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _calculateEmi() {
    final principal = double.tryParse(_amountController.text);
    final annualRate = double.tryParse(_interestController.text);
    final tenureMonths = int.tryParse(_tenureController.text);

    if (principal == null || annualRate == null || tenureMonths == null) {
      setState(() {
        _monthlyEmi = null;
        _totalPayment = null;
        _totalInterest = null;
      });
      return;
    }

    if (principal <= 0 || tenureMonths <= 0) {
      setState(() {
        _monthlyEmi = null;
        _totalPayment = null;
        _totalInterest = null;
      });
      return;
    }

    if (_method == InterestMethod.reducing) {
      _calculateReducingBalance(principal, annualRate, tenureMonths);
    } else {
      _calculateFlatInterest(principal, annualRate, tenureMonths);
    }
  }

  /// Reducing Balance (Diminishing Interest)
  /// Interest is calculated on outstanding principal
  /// EMI = P × i × (1 + i)^n / ((1 + i)^n - 1)
  /// where i = r / (12 × 100)
  void _calculateReducingBalance(double P, double r, int n) {
    // Handle zero interest rate
    if (r == 0) {
      final emi = P / n;
      setState(() {
        _monthlyEmi = emi;
        _totalPayment = P;
        _totalInterest = 0;
      });
      return;
    }

    // Monthly interest rate: i = r / (12 × 100)
    final i = r / (12 * 100);

    // EMI = P × i × (1 + i)^n / ((1 + i)^n - 1)
    final powFactor = pow(1 + i, n);
    final emi = P * i * powFactor / (powFactor - 1);

    // Total Payment = EMI × n
    final totalPayment = emi * n;

    // Total Interest = Total Payment - Principal
    final totalInterest = totalPayment - P;

    setState(() {
      _monthlyEmi = emi;
      _totalPayment = totalPayment;
      _totalInterest = totalInterest;
    });
  }

  /// Flat / Fixed-on-Original Interest
  /// Interest is calculated on original principal for entire tenure
  /// TI = P × (r / 100) × (n / 12)
  /// TR = P + TI
  /// EMI = TR / n
  void _calculateFlatInterest(double P, double r, int n) {
    // Total Interest: TI = P × (r / 100) × (n / 12)
    final totalInterest = P * (r / 100) * (n / 12);

    // Total Repayment: TR = P + TI
    final totalPayment = P + totalInterest;

    // EMI = TR / n
    final emi = totalPayment / n;

    setState(() {
      _monthlyEmi = emi;
      _totalPayment = totalPayment;
      _totalInterest = totalInterest;
    });
  }

  void _clear() {
    _amountController.clear();
    _interestController.clear();
    _tenureController.clear();
    setState(() {
      _monthlyEmi = null;
      _totalPayment = null;
      _totalInterest = null;
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
    return value.toStringAsFixed(2);
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
                    icon: const Icon(Icons.menu, size: 24),
                    onPressed: widget.onMenuTap,
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
                      'EMI Calculator',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Interest Method Toggle
                    _MethodToggle(
                      selected: _method,
                      onChanged: (method) {
                        setState(() => _method = method);
                        _calculateEmi();
                      },
                    ),

                    const SizedBox(height: 40),

                    // Loan Amount
                    _InputField(
                      label: 'Loan Amount',
                      hint: 'Enter amount in rupees',
                      controller: _amountController,
                      suffix: '₹',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateEmi(),
                    ),

                    const SizedBox(height: 32),

                    // Interest Rate
                    _InputField(
                      label: 'Interest Rate',
                      hint: 'Annual interest rate',
                      controller: _interestController,
                      suffix: '%',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculateEmi(),
                    ),

                    const SizedBox(height: 32),

                    // Loan Tenure
                    _InputField(
                      label: 'Loan Tenure',
                      hint: 'Duration in months',
                      controller: _tenureController,
                      suffix: 'months',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateEmi(),
                    ),

                    const SizedBox(height: 56),

                    // Results
                    if (_monthlyEmi != null) ...[
                      _ResultCard(
                        monthlyEmi: _monthlyEmi!,
                        totalPayment: _totalPayment!,
                        totalInterest: _totalInterest!,
                        formatCurrency: _formatCurrency,
                        method: _method,
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

class _MethodToggle extends StatelessWidget {
  final InterestMethod selected;
  final ValueChanged<InterestMethod> onChanged;

  const _MethodToggle({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _ToggleOption(
              label: 'Reducing',
              isSelected: selected == InterestMethod.reducing,
              onTap: () => onChanged(InterestMethod.reducing),
            ),
          ),
          Expanded(
            child: _ToggleOption(
              label: 'Flat',
              isSelected: selected == InterestMethod.flat,
              onTap: () => onChanged(InterestMethod.flat),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.black : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String suffix;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.suffix,
    required this.keyboardType,
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
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
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
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
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

class _ResultCard extends StatelessWidget {
  final double monthlyEmi;
  final double totalPayment;
  final double totalInterest;
  final String Function(double) formatCurrency;
  final InterestMethod method;

  const _ResultCard({
    required this.monthlyEmi,
    required this.totalPayment,
    required this.totalInterest,
    required this.formatCurrency,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Monthly EMI - Primary result
        const Text(
          'Monthly EMI',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${formatCurrency(monthlyEmi)}',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: Colors.black,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: 40),

        // Secondary results
        Row(
          children: [
            Expanded(
              child: _SecondaryResult(
                label: 'Total Payment',
                value: '₹${formatCurrency(totalPayment)}',
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _SecondaryResult(
                label: 'Total Interest',
                value: '₹${formatCurrency(totalInterest)}',
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Method explanation
        Text(
          method == InterestMethod.reducing
              ? 'Interest calculated on outstanding balance'
              : 'Interest calculated on original principal',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}

class _SecondaryResult extends StatelessWidget {
  final String label;
  final String value;

  const _SecondaryResult({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF999999),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
