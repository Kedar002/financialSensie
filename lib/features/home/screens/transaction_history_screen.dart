import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/models/transaction.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';

/// Transaction history screen - view all spending.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _userRepo = UserRepository();
  final _transactionRepo = TransactionRepository();

  List<Transaction> _transactions = [];
  PaymentCycle? _cycle;
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
        _cycle = await _userRepo.getCurrentPaymentCycle();

        if (_cycle != null) {
          _transactions = await _transactionRepo.getCycleTransactions(
            user.id!,
            _cycle!.startDate,
            _cycle!.endDate,
          );
        }
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
        title: const Text('Transactions'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.black),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_transactions.isEmpty) {
      return _buildEmptyState();
    }

    // Group transactions by date
    final grouped = _groupByDate(_transactions);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final date = grouped.keys.elementAt(index);
          final dayTransactions = grouped[date]!;
          return _buildDaySection(date, dayTransactions);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No spending yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your transactions will appear here',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final grouped = <String, List<Transaction>>{};

    for (final t in transactions) {
      final date = DateTime.fromMillisecondsSinceEpoch(t.date * 1000);
      final key = _getDateKey(date);

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(t);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return Formatters.date(date);
    }
  }

  Widget _buildDaySection(String dateLabel, List<Transaction> transactions) {
    final dayTotal = transactions.fold<double>(0.0, (sum, t) => sum + t.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                Formatters.currency(dayTotal),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        ...transactions.map((t) => _buildTransactionItem(t)),
        const SizedBox(height: AppTheme.spacing16),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Dismissible(
      key: Key('transaction_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.spacing16),
        color: const Color(0xFFB00020),
        child: const Icon(Icons.delete, color: AppTheme.white),
      ),
      confirmDismiss: (direction) => _confirmDelete(transaction),
      onDismissed: (direction) => _deleteTransaction(transaction),
      child: AppCard(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(
                _getCategoryIcon(transaction.category),
                color: AppTheme.black,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatCategory(transaction.category),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (transaction.description != null &&
                      transaction.description!.isNotEmpty)
                    Text(
                      transaction.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '- ${Formatters.currency(transaction.amount)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.medical_services;
      default:
        return Icons.receipt;
    }
  }

  String _formatCategory(String category) {
    return category[0].toUpperCase() + category.substring(1);
  }

  Future<bool?> _confirmDelete(Transaction transaction) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text(
          'Delete ${Formatters.currency(transaction.amount)} for ${_formatCategory(transaction.category)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    if (transaction.id != null) {
      await _transactionRepo.deleteTransaction(transaction.id!);
    }
  }
}
