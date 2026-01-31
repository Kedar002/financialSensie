import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum InterestMethod { reducing, flat }

class PayoffCalculatorScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PayoffCalculatorScreen({super.key, required this.onBack});

  @override
  State<PayoffCalculatorScreen> createState() => _PayoffCalculatorScreenState();
}

class _PayoffCalculatorScreenState extends State<PayoffCalculatorScreen> {
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  final _emiController = TextEditingController();

  InterestMethod _method = InterestMethod.reducing;

  int? _months;
  double? _totalInterest;
  double? _totalPayment;
  String? _error;

  @override
  void dispose() {
    _principalController.dispose();
    _interestController.dispose();
    _emiController.dispose();
    super.dispose();
  }

  void _calculate() {
    final P = double.tryParse(_principalController.text);
    final r = double.tryParse(_interestController.text);
    final emi = double.tryParse(_emiController.text);

    if (P == null || r == null || emi == null) {
      setState(() {
        _months = null;
        _totalInterest = null;
        _totalPayment = null;
        _error = null;
      });
      return;
    }

    if (P <= 0 || emi <= 0) {
      setState(() {
        _months = null;
        _totalInterest = null;
        _totalPayment = null;
        _error = null;
      });
      return;
    }

    if (_method == InterestMethod.reducing) {
      _calculateReducingBalance(P, r, emi);
    } else {
      _calculateFlatInterest(P, r, emi);
    }
  }

  /// Reducing Balance Method
  /// Iterate month by month until outstanding <= 0
  void _calculateReducingBalance(double P, double r, double emi) {
    // Monthly interest rate: i = r / (12 × 100)
    final i = r / (12 * 100);

    // Check if payoff is possible: EMI must be > first month's interest
    final firstMonthInterest = P * i;
    if (emi <= firstMonthInterest && r > 0) {
      setState(() {
        _months = null;
        _totalInterest = null;
        _totalPayment = null;
        _error = 'EMI must be greater than ₹${firstMonthInterest.toStringAsFixed(0)}';
      });
      return;
    }

    // Handle zero interest rate
    if (r == 0) {
      final months = (P / emi).ceil();
      setState(() {
        _months = months;
        _totalInterest = 0;
        _totalPayment = P;
        _error = null;
      });
      return;
    }

    // Iterate month by month
    double outstanding = P;
    double totalInterest = 0;
    int months = 0;
    const maxMonths = 1200; // 100 years cap

    while (outstanding > 0 && months < maxMonths) {
      months++;

      // Interest_k = Outstanding_{k-1} × i
      final interestK = outstanding * i;
      totalInterest += interestK;

      // Principal_k = EMI - Interest_k
      final principalK = emi - interestK;

      // Outstanding_k = Outstanding_{k-1} - Principal_k
      outstanding -= principalK;
    }

    if (months >= maxMonths) {
      setState(() {
        _months = null;
        _totalInterest = null;
        _totalPayment = null;
        _error = 'Payoff exceeds 100 years';
      });
      return;
    }

    setState(() {
      _months = months;
      _totalInterest = totalInterest;
      _totalPayment = P + totalInterest;
      _error = null;
    });
  }

  /// Flat Interest Method
  /// Interest calculated on original principal only
  void _calculateFlatInterest(double P, double r, double emi) {
    // Monthly interest rate: i = r / (12 × 100)
    final i = r / (12 * 100);

    // Monthly interest (constant): Interest_monthly = P × i
    final interestMonthly = P * i;

    // Check if payoff is possible: EMI must be > monthly interest
    if (emi <= interestMonthly && r > 0) {
      setState(() {
        _months = null;
        _totalInterest = null;
        _totalPayment = null;
        _error = 'EMI must be greater than ₹${interestMonthly.toStringAsFixed(0)}';
      });
      return;
    }

    // Handle zero interest rate
    if (r == 0) {
      final months = (P / emi).ceil();
      setState(() {
        _months = months;
        _totalInterest = 0;
        _totalPayment = P;
        _error = null;
      });
      return;
    }

    // Principal_monthly = EMI - Interest_monthly
    final principalMonthly = emi - interestMonthly;

    // n = P / Principal_monthly (ceiling)
    final months = (P / principalMonthly).ceil();

    // Total Interest = Interest_monthly × n
    final totalInterest = interestMonthly * months;

    setState(() {
      _months = months;
      _totalInterest = totalInterest;
      _totalPayment = P + totalInterest;
      _error = null;
    });
  }

  void _clear() {
    _principalController.clear();
    _interestController.clear();
    _emiController.clear();
    setState(() {
      _months = null;
      _totalInterest = null;
      _totalPayment = null;
      _error = null;
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

  String _formatDuration(int months) {
    if (months < 12) {
      return '$months ${months == 1 ? 'month' : 'months'}';
    }
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    if (remainingMonths == 0) {
      return '$years ${years == 1 ? 'year' : 'years'}';
    }
    return '$years ${years == 1 ? 'yr' : 'yrs'} $remainingMonths ${remainingMonths == 1 ? 'mo' : 'mos'}';
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
                      'Time to Payoff',
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
                        _calculate();
                      },
                    ),

                    const SizedBox(height: 40),

                    // Loan Amount
                    _InputField(
                      label: 'Loan Amount',
                      hint: 'Principal amount',
                      controller: _principalController,
                      suffix: '₹',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculate(),
                    ),

                    const SizedBox(height: 32),

                    // Interest Rate
                    _InputField(
                      label: 'Interest Rate',
                      hint: 'Annual rate',
                      controller: _interestController,
                      suffix: '%',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _calculate(),
                    ),

                    const SizedBox(height: 32),

                    // EMI
                    _InputField(
                      label: 'Monthly EMI',
                      hint: 'Your payment',
                      controller: _emiController,
                      suffix: '₹',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculate(),
                    ),

                    const SizedBox(height: 56),

                    // Error
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 20,
                              color: Color(0xFF888888),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Results
                    if (_months != null) ...[
                      _ResultCard(
                        months: _months!,
                        totalInterest: _totalInterest!,
                        totalPayment: _totalPayment!,
                        formatCurrency: _formatCurrency,
                        formatDuration: _formatDuration,
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
  final int months;
  final double totalInterest;
  final double totalPayment;
  final String Function(double) formatCurrency;
  final String Function(int) formatDuration;
  final InterestMethod method;

  const _ResultCard({
    required this.months,
    required this.totalInterest,
    required this.totalPayment,
    required this.formatCurrency,
    required this.formatDuration,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time to Payoff - Primary result
        const Text(
          'Time to Payoff',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatDuration(months),
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
              ? 'Interest on outstanding balance'
              : 'Interest on original principal',
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
