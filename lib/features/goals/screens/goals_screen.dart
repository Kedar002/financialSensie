import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/services/goal_service.dart';
import '../../../core/models/planned_expense.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import 'add_goal_screen.dart';

/// Goals screen - list of planned expenses.
/// Shows progress towards each goal.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _userRepo = UserRepository();
  final _goalService = GoalService();

  int? _userId;
  List<PlannedExpense> _goals = [];
  GoalsSummary? _summary;
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
        _goals = await _goalService.getActiveGoals(user.id!);
        _summary = await _goalService.getSummary(user.id!);
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
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppTheme.spacing24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppTheme.spacing24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goals',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      IconButton(
                        onPressed: _addGoal,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_summary != null && _goals.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacing24),
                    _buildSummaryCard(),
                  ],
                  const SizedBox(height: AppTheme.spacing24),
                ]),
              ),
            ),
            if (_goals.isEmpty)
              SliverFillRemaining(
                child: _buildEmptyState(),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppTheme.spacing16,
                      ),
                      child: _GoalCard(
                        goal: _goals[index],
                        onTap: () => _showGoalActions(_goals[index]),
                      ),
                    ),
                    childCount: _goals.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly commitment',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  Formatters.currency(_summary!.totalMonthlyRequired),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppTheme.gray200,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Total saved',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Text(
                  Formatters.currencyCompact(_summary!.totalSavedAmount),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'No goals yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            'Plan for future expenses and save automatically.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacing24),
          ElevatedButton(
            onPressed: _addGoal,
            child: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }

  void _addGoal() async {
    if (_userId == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddGoalScreen(userId: _userId!),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  void _showGoalActions(PlannedExpense goal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                  vertical: AppTheme.spacing8,
                ),
                child: Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Add contribution'),
                onTap: () {
                  Navigator.pop(context);
                  _addContribution(goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Mark as completed'),
                onTap: () {
                  Navigator.pop(context);
                  _markAsCompleted(goal);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete goal'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGoal(goal);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addContribution(PlannedExpense goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusMedium),
        ),
      ),
      builder: (context) => _AddContributionSheet(
        goal: goal,
        onAdded: _loadData,
      ),
    );
  }

  void _markAsCompleted(PlannedExpense goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete goal?'),
        content: Text('Mark "${goal.name}" as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm == true && goal.id != null) {
      await _goalService.markAsCompleted(goal.id!);
      _loadData();
    }
  }

  void _deleteGoal(PlannedExpense goal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete goal?'),
        content: Text('Delete "${goal.name}"? This cannot be undone.'),
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

    if (confirm == true && goal.id != null) {
      await _goalService.deleteGoal(goal.id!);
      _loadData();
    }
  }
}

class _GoalCard extends StatelessWidget {
  final PlannedExpense goal;
  final VoidCallback? onTap;

  const _GoalCard({required this.goal, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                Formatters.daysRemaining(goal.daysRemaining),
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: goal.progressPercentage),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(goal.currentAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.currencyCompact(goal.targetAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            '${Formatters.currency(goal.monthlyRequired)}/month',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ],
        ),
      ),
    );
  }
}

class _AddContributionSheet extends StatefulWidget {
  final PlannedExpense goal;
  final VoidCallback onAdded;

  const _AddContributionSheet({
    required this.goal,
    required this.onAdded,
  });

  @override
  State<_AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends State<_AddContributionSheet> {
  final _controller = TextEditingController();
  final _goalService = GoalService();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.goal.remainingAmount;

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
            'Add to ${widget.goal.name}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            '${Formatters.currency(remaining)} remaining',
            style: Theme.of(context).textTheme.bodyMedium,
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
    if (widget.goal.id == null) return;

    setState(() => _isLoading = true);

    try {
      await _goalService.contributeToGoal(widget.goal.id!, amount);
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
