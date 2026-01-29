import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../models/goal.dart';
import 'add_goal_screen.dart';
import 'goal_detail_screen.dart';

/// Goals screen - your savings goals.
/// Grouped by timeline. Rich cards with progress visualization.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> _goals = [];

  List<Goal> get _shortTermGoals =>
      _goals.where((g) => g.timeline == GoalTimeline.shortTerm).toList();

  List<Goal> get _midTermGoals =>
      _goals.where((g) => g.timeline == GoalTimeline.midTerm).toList();

  List<Goal> get _longTermGoals =>
      _goals.where((g) => g.timeline == GoalTimeline.longTerm).toList();

  double get _totalSaved => _goals.fold(0, (sum, g) => sum + g.currentAmount);
  double get _totalTarget => _goals.fold(0, (sum, g) => sum + g.targetAmount);
  double get _overallProgress => _totalTarget > 0 ? (_totalSaved / _totalTarget) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _goals.isEmpty ? _buildEmptyState(context) : _buildGoalsList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing24),
          Text(
            'Goals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.spacing32),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              children: [
                const Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: AppTheme.gray300,
                ),
                const SizedBox(height: AppTheme.spacing16),
                Text(
                  'No goals yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'Set a savings goal to start tracking your progress',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.gray500,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacing32),
          ElevatedButton(
            onPressed: () => _addGoal(context),
            child: const Text('Create Goal'),
          ),
          const SizedBox(height: AppTheme.spacing64),
        ],
      ),
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.spacing24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goals',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              GestureDetector(
                onTap: () => _addGoal(context),
                child: Container(
                  padding: const EdgeInsets.all(AppTheme.spacing8),
                  decoration: BoxDecoration(
                    color: AppTheme.gray100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: const Icon(Icons.add, size: 20, color: AppTheme.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing24),
          _buildOverviewCard(context),
          const SizedBox(height: AppTheme.spacing32),
          if (_shortTermGoals.isNotEmpty)
            _buildSection(context, 'Short-term', 'Under 1 year', _shortTermGoals),
          if (_midTermGoals.isNotEmpty)
            _buildSection(context, 'Mid-term', '1-5 years', _midTermGoals),
          if (_longTermGoals.isNotEmpty)
            _buildSection(context, 'Long-term', '5+ years', _longTermGoals),
          const SizedBox(height: AppTheme.spacing64),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total saved',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacing8),
          Text(
            Formatters.currency(_totalSaved),
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: AppTheme.spacing4),
          Text(
            'of ${Formatters.currency(_totalTarget)} target',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.gray500,
                ),
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: _overallProgress),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_goals.length} ${_goals.length == 1 ? 'goal' : 'goals'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
              Text(
                '${_overallProgress.toStringAsFixed(0)}% complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String subtitle, List<Goal> goals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: AppTheme.spacing8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing8,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppTheme.gray100,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray600,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing16),
        ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacing12),
              child: _buildGoalCard(context, goal),
            )),
        const SizedBox(height: AppTheme.spacing16),
      ],
    );
  }

  Widget _buildGoalCard(BuildContext context, Goal goal) {
    return AppCard(
      onTap: () => _openGoalDetail(context, goal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacing4),
                    Text(
                      goal.instrument.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.gray500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    goal.isCompleted ? 'Done!' : Formatters.currencyCompact(goal.remaining),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: goal.isCompleted ? AppTheme.black : AppTheme.gray600,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    goal.isCompleted ? '' : 'to go',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray400,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.spacing8),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: AppTheme.gray300,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing16),
          ProgressBar(progress: goal.progress),
          const SizedBox(height: AppTheme.spacing12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Formatters.currencyCompact(goal.currentAmount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
              Text(
                Formatters.currencyCompact(goal.targetAmount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.gray500,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addGoal(BuildContext context) async {
    final result = await Navigator.of(context).push<Goal>(
      MaterialPageRoute(
        builder: (context) => const AddGoalScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && mounted) {
      setState(() => _goals.add(result));
    }
  }

  void _openGoalDetail(BuildContext context, Goal goal) async {
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index == -1) return;

    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => GoalDetailScreen(goal: goal),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (result is Map && result['deleted'] == true) {
          _goals.removeAt(index);
        } else if (result is Goal) {
          _goals[index] = result;
        }
      });
    }
  }
}
