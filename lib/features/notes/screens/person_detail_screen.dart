import 'package:flutter/material.dart';
import '../models/person.dart';
import '../models/money_transaction.dart';
import '../repositories/person_repository.dart';

class PersonDetailScreen extends StatefulWidget {
  final Person person;
  final int initialBalance;
  final int initialTotalCommerce;

  const PersonDetailScreen({
    super.key,
    required this.person,
    required this.initialBalance,
    required this.initialTotalCommerce,
  });

  @override
  State<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends State<PersonDetailScreen> {
  final PersonRepository _repository = PersonRepository();
  List<MoneyTransaction> _transactions = [];
  int _balance = 0;
  int _totalCommerce = 0;
  bool _isLoading = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _balance = widget.initialBalance;
    _totalCommerce = widget.initialTotalCommerce;
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final transactions = await _repository.getTransactions(widget.person.id!);
    final balance = await _repository.getBalance(widget.person.id!);
    final totalCommerce = await _repository.getTotalCommerce(widget.person.id!);

    setState(() {
      _transactions = transactions;
      _balance = balance;
      _totalCommerce = totalCommerce;
      _isLoading = false;
    });
  }

  void _showAddTransactionSheet({required bool isGiven}) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGiven ? 'Money Given' : 'Money Received',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isGiven
                    ? 'Record money you gave to ${widget.person.name}'
                    : 'Record money you received from ${widget.person.name}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
              const SizedBox(height: 24),
              // Amount field
              TextField(
                controller: amountController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: const TextStyle(color: Color(0xFFD1D1D6)),
                  prefixText: '\u20B9 ',
                  prefixStyle: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Note field
              TextField(
                controller: noteController,
                style: const TextStyle(fontSize: 17),
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  hintStyle: const TextStyle(color: Color(0xFFAEAEB2)),
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
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () async {
                    final amount = int.tryParse(amountController.text) ?? 0;
                    if (amount > 0) {
                      final transaction = MoneyTransaction(
                        personId: widget.person.id!,
                        amount: amount * 100, // Convert to paise
                        type: isGiven ? 'given' : 'received',
                        note: noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim(),
                        date: DateTime.now(),
                        createdAt: DateTime.now(),
                      );
                      await _repository.addTransaction(transaction);
                      _hasChanges = true;
                      if (context.mounted) Navigator.pop(context);
                      _loadTransactions();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Add',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Future<void> _deleteTransaction(MoneyTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Transaction',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This transaction will be permanently deleted.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteTransaction(transaction.id!);
      _hasChanges = true;
      _loadTransactions();
    }
  }

  Future<void> _deletePerson() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Person',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '${widget.person.name} and all transactions will be permanently deleted.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF8E8E93),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF3B30),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.delete(widget.person.id!);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  String _formatAmount(int paise) {
    final rupees = paise / 100;
    if (rupees == rupees.toInt()) {
      return rupees.toInt().toString();
    }
    return rupees.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _balance > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _hasChanges);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, _hasChanges),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _deletePerson,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.delete_outline,
                          size: 24,
                          color: Color(0xFFFF3B30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Person Info
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: Center(
                        child: Text(
                          widget.person.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name
                    Text(
                      widget.person.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Balance card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Balance',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _balance == 0
                                        ? 'Settled'
                                        : '\u20B9${_formatAmount(_balance.abs())}',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: _balance == 0
                                          ? const Color(0xFF8E8E93)
                                          : (isPositive
                                              ? const Color(0xFF34C759)
                                              : const Color(0xFFFF3B30)),
                                    ),
                                  ),
                                  if (_balance != 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      isPositive
                                          ? 'owes you'
                                          : 'you owe',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isPositive
                                            ? const Color(0xFF34C759)
                                            : const Color(0xFFFF3B30),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total Commerce',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF8E8E93),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\u20B9${_formatAmount(_totalCommerce)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showAddTransactionSheet(isGiven: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34C759),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Gave',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showAddTransactionSheet(isGiven: false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF3B30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_downward, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Received',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Transactions header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transactions list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      )
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Color(0xFFD1D1D6),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Color(0xFF8E8E93),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _transactions[index];
                              return _TransactionCard(
                                transaction: transaction,
                                onDelete: () => _deleteTransaction(transaction),
                                formatAmount: _formatAmount,
                                formatDate: _formatDate,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final MoneyTransaction transaction;
  final VoidCallback onDelete;
  final String Function(int) formatAmount;
  final String Function(DateTime) formatDate;

  const _TransactionCard({
    required this.transaction,
    required this.onDelete,
    required this.formatAmount,
    required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final isGiven = transaction.type == 'given';

    return Dismissible(
      key: Key(transaction.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isGiven
                    ? const Color(0xFF34C759).withValues(alpha: 0.1)
                    : const Color(0xFFFF3B30).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isGiven ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
                color: isGiven
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGiven ? 'Gave' : 'Received',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8E8E93),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDate(transaction.date),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFAEAEB2),
                    ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${isGiven ? '+' : '-'}\u20B9${formatAmount(transaction.amount)}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isGiven
                    ? const Color(0xFF34C759)
                    : const Color(0xFFFF3B30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
