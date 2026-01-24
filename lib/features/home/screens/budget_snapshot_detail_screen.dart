import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/financial_snapshot.dart';
import '../../../core/services/pdf_export_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';

/// Budget snapshot detail screen - view historical budget sheet.
/// Read-only view with PDF export option.
class BudgetSnapshotDetailScreen extends StatelessWidget {
  final FinancialSnapshot snapshot;
  final _pdfService = PdfExportService();

  BudgetSnapshotDetailScreen({
    super.key,
    required this.snapshot,
  });

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
        title: Text(snapshot.monthDisplay),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.black),
            onPressed: () => _sharePdf(context),
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: AppTheme.black),
            onPressed: () => _exportPdf(context),
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncomeSection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildNeedsSection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildWantsSection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildSavingsSection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildEmergencyFundSection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildSummarySection(context),
            const SizedBox(height: AppTheme.spacing24),
            _buildSafeToSpendCard(context),
            const SizedBox(height: AppTheme.spacing48),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildIncomeSection(BuildContext context) {
    final items = snapshot.incomeList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Income'),
        AppCard(
          child: Column(
            children: [
              if (items.isEmpty)
                _buildEmptyLine(context, 'No income recorded')
              else
                ...items.map((item) => _buildLineItem(
                      context,
                      item['name'] as String? ?? 'Unknown',
                      (item['amount'] as num?)?.toDouble() ?? 0,
                      subtitle: item['frequency'] as String?,
                    )),
              const Divider(height: AppTheme.spacing24),
              _buildTotalLine(context, 'Total Income', snapshot.totalIncome),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeedsSection(BuildContext context) {
    final items = snapshot.needsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Needs',
          subtitle: '${snapshot.needsPercent.toStringAsFixed(0)}%',
        ),
        AppCard(
          child: Column(
            children: [
              if (items.isEmpty)
                _buildEmptyLine(context, 'No essential expenses')
              else
                ...items.map((item) => _buildLineItem(
                      context,
                      item['name'] as String? ?? 'Unknown',
                      (item['amount'] as num?)?.toDouble() ?? 0,
                      isEstimate: item['isEstimate'] == true,
                    )),
              const Divider(height: AppTheme.spacing24),
              _buildTotalLine(context, 'Total Needs', snapshot.totalFixedExpenses),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWantsSection(BuildContext context) {
    final items = snapshot.wantsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Wants',
          subtitle: '${snapshot.wantsPercent.toStringAsFixed(0)}%',
        ),
        AppCard(
          child: Column(
            children: [
              if (items.isEmpty)
                _buildEmptyLine(context, 'No discretionary expenses')
              else
                ...items.map((item) => _buildLineItem(
                      context,
                      item['name'] as String? ?? 'Unknown',
                      (item['amount'] as num?)?.toDouble() ?? 0,
                      isEstimate: item['isEstimate'] == true,
                    )),
              const Divider(height: AppTheme.spacing24),
              _buildTotalLine(context, 'Total Wants', snapshot.totalVariableExpenses),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsSection(BuildContext context) {
    final items = snapshot.savingsList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Savings',
          subtitle: '${snapshot.savingsPercent.toStringAsFixed(0)}%',
        ),
        AppCard(
          child: Column(
            children: [
              if (items.isEmpty)
                _buildEmptyLine(context, 'No savings allocated')
              else
                ...items.map((item) => _buildLineItem(
                      context,
                      item['name'] as String? ?? 'Unknown',
                      (item['amount'] as num?)?.toDouble() ?? 0,
                      subtitle: item['type'] as String?,
                    )),
              const Divider(height: AppTheme.spacing24),
              _buildTotalLine(context, 'Total Savings', snapshot.totalSavings),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyFundSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Emergency Fund'),
        AppCard(
          child: Column(
            children: [
              _buildLineItem(context, 'Current Balance', snapshot.emergencyFundBalance),
              _buildLineItem(context, 'Target', snapshot.emergencyFundTarget),
              _buildLineItem(
                context,
                'Runway',
                snapshot.emergencyFundRunway,
                isCurrency: false,
                suffix: ' months',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Summary'),
        AppCard(
          child: Column(
            children: [
              _buildSummaryLine(context, 'Monthly Income', snapshot.totalIncome),
              _buildSummaryLine(context, 'Needs', snapshot.totalFixedExpenses, isExpense: true),
              _buildSummaryLine(context, 'Wants', snapshot.totalVariableExpenses, isExpense: true),
              _buildSummaryLine(context, 'Savings', snapshot.totalSavings, isExpense: true),
              const Divider(height: AppTheme.spacing24),
              _buildSummaryLine(context, 'Safe to Spend', snapshot.safeToSpendBudget, isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSafeToSpendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Text(
            'Safe to Spend',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.white,
                ),
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(snapshot.safeToSpendBudget),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.white,
                ),
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            '${snapshot.safeToSpendPercent.toStringAsFixed(0)}% of income',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
          if (snapshot.actualSpent > 0) ...[
            const SizedBox(height: AppTheme.spacing16),
            Container(
              height: 1,
              color: AppTheme.gray500,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
                Text(
                  Formatters.currency(snapshot.actualSpent),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  snapshot.underBudget ? 'Under budget' : 'Over budget',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
                Text(
                  Formatters.currency(snapshot.budgetVariance.abs()),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: snapshot.underBudget
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineItem(
    BuildContext context,
    String label,
    double amount, {
    String? subtitle,
    bool isEstimate = false,
    bool isCurrency = true,
    String suffix = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
            ],
          ),
          Text(
            isCurrency
                ? '${isEstimate ? "~" : ""}${Formatters.currency(amount)}'
                : '${amount.toStringAsFixed(1)}$suffix',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalLine(BuildContext context, String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          Formatters.currency(amount),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ],
    );
  }

  Widget _buildSummaryLine(
    BuildContext context,
    String label,
    double amount, {
    bool isExpense = false,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isBold
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            isExpense ? '- ${Formatters.currency(amount)}' : Formatters.currency(amount),
            style: isBold
                ? Theme.of(context).textTheme.titleLarge
                : Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLine(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.gray400,
            ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    try {
      await _pdfService.previewPdf(snapshot);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await _pdfService.sharePdf(snapshot);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing PDF: $e')),
        );
      }
    }
  }
}
