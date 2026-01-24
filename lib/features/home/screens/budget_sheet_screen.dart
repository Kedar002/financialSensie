import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/budget_sheet_service.dart';
import '../../../core/services/budget_snapshot_service.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../shared/utils/formatters.dart';
import 'budget_history_screen.dart';

/// Budget Sheet - Complete monthly financial overview.
/// Steve Jobs approved: Clean, minimal, purposeful.
class BudgetSheetScreen extends StatefulWidget {
  const BudgetSheetScreen({super.key});

  @override
  State<BudgetSheetScreen> createState() => _BudgetSheetScreenState();
}

class _BudgetSheetScreenState extends State<BudgetSheetScreen> {
  final _budgetSheetService = BudgetSheetService();
  final _snapshotService = BudgetSnapshotService();
  final _pdfService = PdfExportService();
  final _userRepo = UserRepository();

  int? _userId;
  BudgetSheet? _budgetSheet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _userRepo.getCurrentUser();
      if (user != null) {
        _userId = user.id;
        _budgetSheet = await _budgetSheetService.getBudgetSheet(user.id!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          DateFormat('MMMM yyyy').format(DateTime.now()).toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w500,
              ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppTheme.black),
            onPressed: _viewHistory,
            tooltip: 'View History',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.black),
            onPressed: _exportPdf,
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.black),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_budgetSheet == null) {
      return const Center(child: Text('No data available'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing16),
          _buildIncomeSection(),
          _buildDivider(),
          _buildNeedsSection(),
          _buildDivider(),
          _buildWantsSection(),
          _buildDivider(),
          _buildSavingsSection(),
          _buildDivider(),
          _buildSafetySection(),
          _buildDivider(),
          _buildSummarySection(),
          const SizedBox(height: AppTheme.spacing48),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing24),
      child: Container(
        height: 1,
        color: AppTheme.gray200,
      ),
    );
  }

  Widget _buildIncomeSection() {
    final sheet = _budgetSheet!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('INCOME'),
        const SizedBox(height: AppTheme.spacing16),
        ...sheet.incomeSources.map((source) => _buildLineItem(
              source.name,
              Formatters.currency(source.monthlyAmount),
            )),
        const SizedBox(height: AppTheme.spacing12),
        _buildTotalRow('Total Income', sheet.totalIncome),
      ],
    );
  }

  Widget _buildNeedsSection() {
    final sheet = _budgetSheet!;
    final hasItems = sheet.essentialFixedExpenses.isNotEmpty ||
        sheet.essentialVariableExpenses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'NEEDS',
          subtitle: '${sheet.needsPercent.toStringAsFixed(0)}% of income',
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (!hasItems)
          _buildEmptyState('No essential expenses added')
        else ...[
          ...sheet.essentialFixedExpenses.map((e) => _buildLineItem(
                e.name,
                Formatters.currency(e.amount),
              )),
          ...sheet.essentialVariableExpenses.map((e) => _buildLineItem(
                _capitalizeCategory(e.category),
                Formatters.currency(e.estimatedAmount),
                isEstimate: true,
              )),
        ],
        const SizedBox(height: AppTheme.spacing12),
        _buildTotalRow('Total Needs', sheet.totalNeeds),
      ],
    );
  }

  Widget _buildWantsSection() {
    final sheet = _budgetSheet!;
    final hasItems = sheet.nonEssentialFixedExpenses.isNotEmpty ||
        sheet.nonEssentialVariableExpenses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'WANTS',
          subtitle: '${sheet.wantsPercent.toStringAsFixed(0)}% of income',
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (!hasItems)
          _buildEmptyState('No discretionary expenses added')
        else ...[
          ...sheet.nonEssentialFixedExpenses.map((e) => _buildLineItem(
                e.name,
                Formatters.currency(e.amount),
              )),
          ...sheet.nonEssentialVariableExpenses.map((e) => _buildLineItem(
                _capitalizeCategory(e.category),
                Formatters.currency(e.estimatedAmount),
                isEstimate: true,
              )),
        ],
        const SizedBox(height: AppTheme.spacing12),
        _buildTotalRow('Total Wants', sheet.totalWants),
      ],
    );
  }

  Widget _buildSavingsSection() {
    final sheet = _budgetSheet!;
    final hasAllocations = sheet.allocations.isNotEmpty;
    final hasGoals = sheet.goals.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'SAVINGS',
          subtitle: '${sheet.savingsPercent.toStringAsFixed(0)}% of income',
        ),
        const SizedBox(height: AppTheme.spacing16),
        if (!hasAllocations && !hasGoals)
          _buildEmptyState('No savings or goals set up')
        else ...[
          if (hasAllocations) ...[
            ...sheet.allocations.map((item) => _buildLineItem(
                  item.name,
                  Formatters.currency(item.amount),
                )),
          ],
          if (hasGoals) ...[
            if (hasAllocations) const SizedBox(height: AppTheme.spacing8),
            ...sheet.goals.map((item) => _buildLineItem(
                  item.name,
                  Formatters.currency(item.amount),
                  subtitle: 'Goal',
                )),
          ],
        ],
        const SizedBox(height: AppTheme.spacing12),
        _buildTotalRow('Total Savings', sheet.totalSavings),
      ],
    );
  }

  Widget _buildSafetySection() {
    final sheet = _budgetSheet!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EMERGENCY FUND'),
        const SizedBox(height: AppTheme.spacing16),
        _buildLineItem(
          'Current Balance',
          Formatters.currency(sheet.emergencyFundCurrent),
        ),
        _buildLineItem(
          'Target',
          Formatters.currency(sheet.emergencyFundTarget),
        ),
        _buildLineItem(
          'Runway',
          '${sheet.emergencyFundRunway.toStringAsFixed(1)} months',
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    final sheet = _budgetSheet!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MONTHLY SUMMARY',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 1.5,
                  color: AppTheme.gray600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing20),
          _buildSummaryRow('Total Income', sheet.totalIncome),
          const SizedBox(height: AppTheme.spacing12),
          _buildSummaryRow('Needs', -sheet.totalNeeds),
          _buildSummaryRow('Wants', -sheet.totalWants),
          _buildSummaryRow('Savings', -sheet.totalSavings),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            height: 1,
            color: AppTheme.gray300,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Safe to Spend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                Formatters.currency(sheet.safeToSpend),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '${sheet.safeToSpendPercent.toStringAsFixed(0)}% of income for daily spending',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: AppTheme.spacing12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineItem(String label, String value,
      {bool isEstimate = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            isEstimate ? '~$value' : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isEstimate ? AppTheme.gray600 : AppTheme.black,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.spacing12,
        horizontal: AppTheme.spacing16,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.gray200),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            Formatters.currency(amount),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    final isNegative = amount < 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          isNegative
              ? '- ${Formatters.currency(amount.abs())}'
              : Formatters.currency(amount),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.gray500,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }

  String _capitalizeCategory(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  void _viewHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BudgetHistoryScreen(),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_userId == null || _budgetSheet == null) return;

    try {
      // First capture a snapshot of current budget
      await _snapshotService.captureSnapshot(_userId!);

      // Get the latest snapshot
      final snapshot = await _snapshotService.getLatestSnapshot(_userId!);
      if (snapshot != null) {
        await _pdfService.previewPdf(snapshot);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }
}
