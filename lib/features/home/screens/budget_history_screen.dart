import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/budget_snapshot_service.dart';
import '../../../core/models/financial_snapshot.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import 'budget_snapshot_detail_screen.dart';

/// Budget history screen - view past monthly budgets.
/// Shows up to 2 years (24 months) of history.
class BudgetHistoryScreen extends StatefulWidget {
  const BudgetHistoryScreen({super.key});

  @override
  State<BudgetHistoryScreen> createState() => _BudgetHistoryScreenState();
}

class _BudgetHistoryScreenState extends State<BudgetHistoryScreen> {
  final _userRepo = UserRepository();
  final _snapshotService = BudgetSnapshotService();

  int? _userId;
  List<FinancialSnapshot> _snapshots = [];
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
        _snapshots = await _snapshotService.getHistory(user.id!, limit: 24);
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
        title: const Text('Budget History'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.black),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_snapshots.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.black,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        itemCount: _snapshots.length,
        itemBuilder: (context, index) {
          return _buildSnapshotItem(_snapshots[index]);
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
              Icons.history,
              size: 64,
              color: AppTheme.gray400,
            ),
            const SizedBox(height: AppTheme.spacing16),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your monthly budget snapshots will appear here at the end of each payment cycle.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing24),
            OutlinedButton(
              onPressed: _captureCurrentSnapshot,
              child: const Text('Save Current Budget'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotItem(FinancialSnapshot snapshot) {
    final isOverBudget = !snapshot.underBudget && snapshot.actualSpent > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
      child: GestureDetector(
        onTap: () => _viewSnapshot(snapshot),
        child: AppCard(
          child: Row(
            children: [
              // Month indicator
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.gray100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Center(
                  child: Text(
                    _getMonthAbbrev(snapshot.month),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacing16),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.monthDisplay,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Row(
                      children: [
                        Text(
                          'Safe to spend: ${Formatters.currency(snapshot.safeToSpendBudget)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (snapshot.actualSpent > 0) ...[
                          const SizedBox(width: AppTheme.spacing8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOverBudget
                                  ? const Color(0xFFB00020).withValues(alpha: 0.1)
                                  : Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOverBudget ? 'Over' : 'Under',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isOverBudget
                                        ? const Color(0xFFB00020)
                                        : Colors.green,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.gray400),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthAbbrev(String month) {
    try {
      final monthNum = int.parse(month.split('-')[1]);
      const abbrevs = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
      return abbrevs[monthNum - 1];
    } catch (_) {
      return '?';
    }
  }

  void _viewSnapshot(FinancialSnapshot snapshot) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BudgetSnapshotDetailScreen(snapshot: snapshot),
      ),
    );
  }

  Future<void> _captureCurrentSnapshot() async {
    if (_userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _snapshotService.captureSnapshot(_userId!);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget snapshot saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
