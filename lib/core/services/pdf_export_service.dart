import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/financial_snapshot.dart';
import '../../shared/utils/formatters.dart';

/// Service for generating PDF exports of budget sheets.
/// Uses Steve Jobs approved design (black, white, gray).
class PdfExportService {
  // Colors - Steve Jobs approved
  static const _black = PdfColors.black;
  static const _gray = PdfColor.fromInt(0xFF757575);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  static const _white = PdfColors.white;

  /// Generate PDF from a financial snapshot
  Future<Uint8List> generateBudgetPdf(FinancialSnapshot snapshot) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(snapshot),
          pw.SizedBox(height: 24),
          _buildIncomeSection(snapshot),
          pw.SizedBox(height: 20),
          _buildNeedsSection(snapshot),
          pw.SizedBox(height: 20),
          _buildWantsSection(snapshot),
          pw.SizedBox(height: 20),
          _buildSavingsSection(snapshot),
          pw.SizedBox(height: 20),
          _buildEmergencyFundSection(snapshot),
          pw.SizedBox(height: 24),
          _buildSummarySection(snapshot),
          pw.SizedBox(height: 32),
          _buildSafeToSpendBox(snapshot),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  /// Preview PDF in system viewer
  Future<void> previewPdf(FinancialSnapshot snapshot) async {
    final pdfBytes = await generateBudgetPdf(snapshot);
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'Budget_${snapshot.month}.pdf',
    );
  }

  /// Share PDF
  Future<void> sharePdf(FinancialSnapshot snapshot) async {
    final pdfBytes = await generateBudgetPdf(snapshot);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Budget_${snapshot.month}.pdf',
    );
  }

  // Header with month and title
  pw.Widget _buildHeader(FinancialSnapshot snapshot) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Budget Sheet',
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: _black,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          snapshot.monthDisplay,
          style: pw.TextStyle(
            fontSize: 16,
            color: _gray,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: _black, thickness: 2),
      ],
    );
  }

  // Income section
  pw.Widget _buildIncomeSection(FinancialSnapshot snapshot) {
    return _buildSection(
      title: 'Income',
      items: snapshot.incomeList.map((item) => _LineItem(
        name: item['name'] as String? ?? 'Unknown',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        subtitle: item['frequency'] as String?,
      )).toList(),
      total: snapshot.totalIncome,
    );
  }

  // Needs section
  pw.Widget _buildNeedsSection(FinancialSnapshot snapshot) {
    return _buildSection(
      title: 'Needs (Essential)',
      subtitle: '${snapshot.needsPercent.toStringAsFixed(0)}% of income',
      items: snapshot.needsList.map((item) => _LineItem(
        name: item['name'] as String? ?? 'Unknown',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        isEstimate: item['isEstimate'] == true,
      )).toList(),
      total: snapshot.totalFixedExpenses,
    );
  }

  // Wants section
  pw.Widget _buildWantsSection(FinancialSnapshot snapshot) {
    return _buildSection(
      title: 'Wants (Discretionary)',
      subtitle: '${snapshot.wantsPercent.toStringAsFixed(0)}% of income',
      items: snapshot.wantsList.map((item) => _LineItem(
        name: item['name'] as String? ?? 'Unknown',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        isEstimate: item['isEstimate'] == true,
      )).toList(),
      total: snapshot.totalVariableExpenses,
    );
  }

  // Savings section
  pw.Widget _buildSavingsSection(FinancialSnapshot snapshot) {
    return _buildSection(
      title: 'Savings & Goals',
      subtitle: '${snapshot.savingsPercent.toStringAsFixed(0)}% of income',
      items: snapshot.savingsList.map((item) => _LineItem(
        name: item['name'] as String? ?? 'Unknown',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        subtitle: item['type'] as String?,
      )).toList(),
      total: snapshot.totalSavings,
    );
  }

  // Emergency fund section
  pw.Widget _buildEmergencyFundSection(FinancialSnapshot snapshot) {
    final runway = snapshot.emergencyFundRunway;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Emergency Fund',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Current Balance', style: pw.TextStyle(color: _gray, fontSize: 10)),
                  pw.Text(
                    Formatters.currency(snapshot.emergencyFundBalance),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Target', style: pw.TextStyle(color: _gray, fontSize: 10)),
                  pw.Text(
                    Formatters.currency(snapshot.emergencyFundTarget),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Runway', style: pw.TextStyle(color: _gray, fontSize: 10)),
                  pw.Text(
                    '${runway.toStringAsFixed(1)} months',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Summary section
  pw.Widget _buildSummarySection(FinancialSnapshot snapshot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _gray, width: 0.5),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Monthly Income', snapshot.totalIncome),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Needs', -snapshot.totalFixedExpenses),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Wants', -snapshot.totalVariableExpenses),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Savings', -snapshot.totalSavings),
          pw.Divider(color: _gray),
          _buildSummaryRow('Safe to Spend', snapshot.safeToSpendBudget, isBold: true),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    final isNegative = amount < 0;
    final displayAmount = isNegative ? '- ${Formatters.currency(amount.abs())}' : Formatters.currency(amount);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          displayAmount,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Safe to spend box
  pw.Widget _buildSafeToSpendBox(FinancialSnapshot snapshot) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: _black,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Monthly Safe to Spend',
            style: pw.TextStyle(
              fontSize: 12,
              color: _white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            Formatters.currency(snapshot.safeToSpendBudget),
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: _white,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${snapshot.safeToSpendPercent.toStringAsFixed(0)}% of income',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromInt(0xFFBDBDBD),
            ),
          ),
          if (snapshot.actualSpent > 0) ...[
            pw.SizedBox(height: 16),
            pw.Divider(color: PdfColor.fromInt(0xFF424242)),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Spent', style: pw.TextStyle(color: _white, fontSize: 11)),
                pw.Text(
                  Formatters.currency(snapshot.actualSpent),
                  style: pw.TextStyle(color: _white, fontSize: 11),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Remaining', style: pw.TextStyle(color: _white, fontSize: 11)),
                pw.Text(
                  Formatters.currency(snapshot.budgetVariance),
                  style: pw.TextStyle(
                    color: snapshot.underBudget ? PdfColors.green200 : PdfColors.red200,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Section builder
  pw.Widget _buildSection({
    required String title,
    String? subtitle,
    required List<_LineItem> items,
    required double total,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _black,
              ),
            ),
            if (subtitle != null)
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: _gray,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 8),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.name,
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                  if (item.subtitle != null)
                    pw.Text(
                      item.subtitle!,
                      style: pw.TextStyle(fontSize: 9, color: _gray),
                    ),
                ],
              ),
              pw.Text(
                '${item.isEstimate ? "~" : ""}${Formatters.currency(item.amount)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ],
          ),
        )),
        pw.SizedBox(height: 8),
        pw.Divider(color: _gray, thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Total',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              Formatters.currency(total),
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  // Footer
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 16),
      child: pw.Text(
        'Generated by FinanceSensei',
        style: pw.TextStyle(fontSize: 9, color: _gray),
      ),
    );
  }
}

class _LineItem {
  final String name;
  final double amount;
  final String? subtitle;
  final bool isEstimate;

  const _LineItem({
    required this.name,
    required this.amount,
    this.subtitle,
    this.isEstimate = false,
  });
}
