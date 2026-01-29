import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../models/goal.dart';
import 'add_to_goal_screen.dart';
import 'edit_goal_screen.dart';

/// Goal detail screen.
/// Rich visual design with cards for each section.
/// Hero card shows progress. Details card shows metrics.
class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({
    super.key,
    required this.goal,
  });

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late Goal _goal;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.spacing16),
                    _buildHeader(context),
                    const SizedBox(height: AppTheme.spacing32),
                    _buildHeroCard(context),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildProgressCard(context),
                    const SizedBox(height: AppTheme.spacing24),
                    _buildDetailsCard(context),
                    const SizedBox(height: AppTheme.spacing32),
                    _buildDeleteAction(context),
                    const SizedBox(height: AppTheme.spacing32),
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
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context, _goal),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacing8),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: AppTheme.black),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _editGoal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacing16,
              vertical: AppTheme.spacing8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _goal.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing12,
                  vertical: AppTheme.spacing6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.black,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  _goal.timeline.label,
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            _goal.instrument.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Saved',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            Formatters.currency(_goal.currentAmount),
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'of ${Formatters.currency(_goal.targetAmount)} target',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context) {
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
                _goal.isCompleted ? 'Complete!' : '${_goal.progress.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _goal.isCompleted ? AppTheme.black : AppTheme.gray600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: _goal.progress),
          const SizedBox(height: AppTheme.spacing16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(_goal.currentAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                Formatters.currencyCompact(_goal.targetAmount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            context,
            'Still needed',
            _goal.isCompleted ? 'Done' : Formatters.currency(_goal.remaining),
            bold: true,
          ),
          const Divider(height: AppTheme.spacing24),
          _buildDetailRow(
            context,
            'Target date',
            _formatDate(_goal.targetDate),
          ),
          if (!_goal.isCompleted && _goal.monthlySavingsNeeded > 0) ...[
            const Divider(height: AppTheme.spacing24),
            _buildDetailRow(
              context,
              'Save per month',
              Formatters.currency(_goal.monthlySavingsNeeded),
            ),
          ],
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
                    _goal.isCompleted
                        ? 'Congratulations! You\'ve reached your goal.'
                        : 'Save ${Formatters.currency(_goal.monthlySavingsNeeded)}/month to reach your goal on time.',
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

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool bold = false}) {
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

  Widget _buildDeleteAction(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _deleteGoal(context),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing8),
          child: Text(
            'Delete goal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray400,
                ),
          ),
        ),
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
        onPressed: _goal.isCompleted ? null : () => _addToGoal(context),
        child: Text(_goal.isCompleted ? 'Goal Complete!' : 'Add to Goal'),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _addToGoal(BuildContext context) async {
    final result = await Navigator.of(context).push<double>(
      MaterialPageRoute(
        builder: (context) => AddToGoalScreen(goalName: _goal.name),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _goal = _goal.copyWith(currentAmount: _goal.currentAmount + result);
      });
    }
  }

  void _editGoal(BuildContext context) async {
    final result = await Navigator.of(context).push<Goal>(
      MaterialPageRoute(
        builder: (context) => EditGoalScreen(goal: _goal),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() => _goal = result);
    }
  }

  void _deleteGoal(BuildContext context) {
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
                'Delete "${_goal.name}"?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppTheme.spacing8),
              Text(
                'This will permanently remove your goal and progress.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.gray600,
                    ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, {'deleted': true});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.black,
                      ),
                      child: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
