import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../models/financial_plan.dart';
import 'add_debt_screen.dart';

/// Debt Screen - Track and manage your debts.
/// Priority: High-interest first. Pay more than minimum.
class DebtScreen extends StatefulWidget {
  final List<Debt> debts;

  const DebtScreen({
    super.key,
    required this.debts,
  });

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  late List<Debt> _debts;

  @override
  void initState() {
    super.initState();
    _debts = List.from(widget.debts);
  }

  double get _totalDebt => _debts.fold(0, (sum, d) => sum + d.remainingAmount);
  double get _totalPaid => _debts.fold(0, (sum, d) => sum + d.paidAmount);
  double get _totalOriginal => _debts.fold(0, (sum, d) => sum + d.totalAmount);
  double get _overallProgress => _totalOriginal > 0 ? (_totalPaid / _totalOriginal) * 100 : 0;

  List<Debt> get _highPriority => _debts.where((d) => d.priority == DebtPriority.high && !d.isPaidOff).toList();
  List<Debt> get _mediumPriority => _debts.where((d) => d.priority == DebtPriority.medium && !d.isPaidOff).toList();
  List<Debt> get _lowPriority => _debts.where((d) => d.priority == DebtPriority.low && !d.isPaidOff).toList();
  List<Debt> get _paidOff => _debts.where((d) => d.isPaidOff).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_debts.isEmpty)
                            _buildEmptyState(context)
                          else ...[
                            _buildOverviewCard(context),
                            const SizedBox(height: AppTheme.spacing32),
                            _buildDebtsList(context),
                          ],
                          const SizedBox(height: AppTheme.spacing32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacing8),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
            ),
          ),
          const SizedBox(width: AppTheme.spacing16),
          Text(
            'Debt',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        children: [
          const Icon(
            Icons.celebration_outlined,
            size: 48,
            color: AppTheme.gray300,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Text(
            'Debt Free!',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'You have no debts to track. Keep it that way!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Remaining',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(_totalDebt),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: _overallProgress),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${Formatters.currencyCompact(_totalPaid)} paid',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
              Text(
                '${_overallProgress.toStringAsFixed(0)}% done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ],
          ),
          if (_highPriority.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacing16),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing12),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  const Icon(Icons.priority_high, size: 16, color: AppTheme.black),
                  const SizedBox(width: AppTheme.spacing8),
                  Expanded(
                    child: Text(
                      'Focus on ${_highPriority.first.name} first (${_highPriority.first.interestRate.toStringAsFixed(1)}% interest)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDebtsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_highPriority.isNotEmpty)
          _buildPrioritySection(context, DebtPriority.high, _highPriority),
        if (_mediumPriority.isNotEmpty)
          _buildPrioritySection(context, DebtPriority.medium, _mediumPriority),
        if (_lowPriority.isNotEmpty)
          _buildPrioritySection(context, DebtPriority.low, _lowPriority),
        if (_paidOff.isNotEmpty)
          _buildPaidOffSection(context),
      ],
    );
  }

  Widget _buildPrioritySection(BuildContext context, DebtPriority priority, List<Debt> debts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              priority.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: priority == DebtPriority.high ? AppTheme.black : AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                priority == DebtPriority.high ? 'Pay First' : priority.description.split('(').last.replaceAll(')', ''),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: priority == DebtPriority.high ? AppTheme.white : AppTheme.gray600,
                      fontSize: 11,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...debts.map((debt) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: _buildDebtCard(context, debt),
            )),
        const SizedBox(height: AppTheme.spacing16),
      ],
    );
  }

  Widget _buildPaidOffSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Paid Off',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.gray400,
                  ),
            ),
            const SizedBox(width: AppTheme.spacing8),
            const Icon(Icons.check_circle, size: 16, color: AppTheme.gray400),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        ...(_paidOff.map((debt) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: _buildDebtCard(context, debt, isPaidOff: true),
            ))),
      ],
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt, {bool isPaidOff = false}) {
    return AppCard(
      onTap: isPaidOff ? null : () => _showDebtActions(context, debt),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isPaidOff ? AppTheme.gray400 : AppTheme.black,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      '${debt.interestRate.toStringAsFixed(1)}% interest',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray500,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isPaidOff ? 'Paid!' : Formatters.currencyCompact(debt.remainingAmount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isPaidOff ? AppTheme.gray400 : AppTheme.black,
                        ),
                  ),
                  if (!isPaidOff) ...[
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      'of ${Formatters.currencyCompact(debt.totalAmount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray400,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (!isPaidOff) ...[
            const SizedBox(height: AppTheme.spacing12),
            ProgressBar(progress: debt.progress, height: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.gray100, width: 1),
        ),
      ),
      child: ElevatedButton(
        onPressed: () => _addDebt(context),
        child: Text(_debts.isEmpty ? 'Add Debt' : 'Add Another Debt'),
      ),
    );
  }

  void _addDebt(BuildContext context) async {
    final result = await Navigator.of(context).push<Debt>(
      MaterialPageRoute(
        builder: (context) => const AddDebtScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() => _debts.add(result));
    }
  }

  void _showDebtActions(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMedium)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                debt.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                '${Formatters.currency(debt.remainingAmount)} remaining',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              _buildActionButton(
                context,
                icon: Icons.payment,
                label: 'Record Payment',
                onTap: () {
                  Navigator.pop(context);
                  _recordPayment(context, debt);
                },
              ),
              const SizedBox(height: AppTheme.spacing12),
              _buildActionButton(
                context,
                icon: Icons.delete_outline,
                label: 'Delete Debt',
                onTap: () {
                  Navigator.pop(context);
                  _deleteDebt(debt);
                },
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive ? AppTheme.gray500 : AppTheme.black,
            ),
            const SizedBox(width: AppTheme.spacing12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isDestructive ? AppTheme.gray500 : AppTheme.black,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _recordPayment(BuildContext context, Debt debt) {
    // TODO: Implement payment recording
  }

  void _deleteDebt(Debt debt) {
    setState(() => _debts.removeWhere((d) => d.id == debt.id));
  }
}
