import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/emergency_fund_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';

/// Emergency Fund screen - shows runway and progress.
/// Clean, focused on the key metric: months of safety.
class EmergencyFundScreen extends StatefulWidget {
  const EmergencyFundScreen({super.key});

  @override
  State<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  final _userRepo = UserRepository();
  final _fundService = EmergencyFundService();

  int? _userId;
  EmergencyFundStatus? _status;
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
        _status = await _fundService.getStatus(user.id!);
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
                'Emergency Fund',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.spacing32),
              _buildRunwayCard(),
              const SizedBox(height: AppTheme.spacing24),
              _buildProgressCard(),
              const SizedBox(height: AppTheme.spacing24),
              _buildDetailsCard(),
              const SizedBox(height: AppTheme.spacing32),
              OutlinedButton(
                onPressed: _addToFund,
                child: const Text('Add to Fund'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRunwayCard() {
    final runway = _status?.runwayMonths ?? 0;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You can survive',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.months(runway),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'without income',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _status?.progressPercentage ?? 0;
    final current = _status?.currentAmount ?? 0;
    final target = _status?.targetAmount ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                Formatters.percentage(progress),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: progress),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(current),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.currencyCompact(target),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final targetMonths = _status?.targetMonths ?? 6;
    final monthlyExpenses = _status?.monthlyEssential ?? 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            'Target ($targetMonths months)',
            Formatters.currency(_status?.targetAmount ?? 0),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            'Monthly essentials',
            Formatters.currency(monthlyExpenses),
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            'Still needed',
            Formatters.currency(_status?.remainingAmount ?? 0),
            bold: true,
          ),
          const SizedBox(height: AppTheme.spacing16),
          Container(
            padding: const EdgeInsets.all(AppTheme.spacing12),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.gray600),
                const SizedBox(width: AppTheme.spacing8),
                Expanded(
                  child: Text(
                    'Based on ${Formatters.currency(monthlyExpenses)}/month essential expenses × $targetMonths months',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool bold = false}) {
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
              ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  void _addToFund() {
    if (_userId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      builder: (context) => _AddToFundSheet(
        userId: _userId!,
        onAdded: _loadData,
      ),
    );
  }
}

class _AddToFundSheet extends StatefulWidget {
  final int userId;
  final VoidCallback onAdded;

  const _AddToFundSheet({
    required this.userId,
    required this.onAdded,
  });

  @override
  State<_AddToFundSheet> createState() => _AddToFundSheetState();
}

class _AddToFundSheetState extends State<_AddToFundSheet> {
  final _controller = TextEditingController();
  final _fundService = EmergencyFundService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacing24,
        right: AppTheme.spacing24,
        top: AppTheme.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacing24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add to Emergency Fund',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacing24),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Amount',
              prefixText: '₹ ',
            ),
            autofocus: true,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: _isLoading ? null : _add,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.white,
                    ),
                  )
                : const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _add() async {
    final amount = double.tryParse(_controller.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      await _fundService.addToFund(widget.userId, amount);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onAdded();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
