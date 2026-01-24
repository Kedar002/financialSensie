import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/income_repository.dart';
import '../../../core/repositories/expense_repository.dart';
import '../../../core/services/financial_calculation_service.dart';
import '../../../core/models/income_source.dart';
import '../../../core/models/fixed_expense.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';

/// Profile screen - view and edit financial setup.
/// Shows income, expenses, and summary.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userRepo = UserRepository();
  final _incomeRepo = IncomeRepository();
  final _fixedExpenseRepo = FixedExpenseRepository();
  final _calcService = FinancialCalculationService();

  int? _userId;
  List<IncomeSource> _incomes = [];
  List<FixedExpense> _expenses = [];
  FinancialSummary? _summary;
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
        _incomes = await _incomeRepo.getByUserId(user.id!);
        _expenses = await _fixedExpenseRepo.getByUserId(user.id!);
        _summary = await _calcService.getSummary(user.id!);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.black),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.black,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacing24),
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing32),
              _buildSummaryCard(),
              const SizedBox(height: AppTheme.spacing32),
              const SectionHeader(title: 'Income'),
              ..._incomes.map(_buildIncomeItem),
              if (_incomes.isEmpty) _buildEmptyItem('No income added'),
              const SizedBox(height: AppTheme.spacing24),
              const SectionHeader(title: 'Fixed Expenses'),
              ..._expenses.map(_buildExpenseItem),
              if (_expenses.isEmpty) _buildEmptyItem('No expenses added'),
              const SizedBox(height: AppTheme.spacing48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        children: [
          _buildSummaryRow(
            'Monthly Income',
            Formatters.currency(_summary?.monthlyIncome ?? 0),
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(
            'Fixed Expenses',
            '- ${Formatters.currency(_summary?.fixedExpenses ?? 0)}',
          ),
          const SizedBox(height: AppTheme.spacing16),
          _buildSummaryRow(
            'Allocations',
            '- ${Formatters.currency(_summary?.allocations ?? 0)}',
          ),
          const Divider(height: AppTheme.spacing32),
          _buildSummaryRow(
            'Safe to Spend',
            Formatters.currency(_summary?.safeToSpendBudget ?? 0),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: bold
              ? Theme.of(context).textTheme.titleLarge
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildIncomeItem(IncomeSource income) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  income.frequency,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Text(
              Formatters.currency(income.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseItem(FixedExpense expense) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: AppCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  expense.category,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            Text(
              Formatters.currency(expense.amount),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyItem(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
