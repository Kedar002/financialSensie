import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../data/lessons_data.dart';
import '../models/lesson.dart';
import 'lesson_screen.dart';

/// Learn screen - Financial literacy hub.
/// Ten lessons. Life-changing knowledge.
/// Steve Jobs would be proud.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntro(context),
                    const SizedBox(height: AppTheme.spacing32),
                    _buildLessonsList(context),
                    const SizedBox(height: AppTheme.spacing64),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.chevron_left,
              color: AppTheme.black,
              size: 28,
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Text(
            'Learn',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Literacy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          'Master the fundamentals of personal finance. Each lesson takes 5 minutes and could change your financial future.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.gray600,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildLessonsList(BuildContext context) {
    return Column(
      children: LessonsData.allLessons.asMap().entries.map((entry) {
        final index = entry.key;
        final lesson = entry.value;
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < LessonsData.allLessons.length - 1
                ? AppTheme.spacing12
                : 0,
          ),
          child: _buildLessonCard(context, lesson, index + 1),
        );
      }).toList(),
    );
  }

  Widget _buildLessonCard(BuildContext context, Lesson lesson, int number) {
    return GestureDetector(
      onTap: () => _openLesson(context, lesson),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppTheme.spacing4),
                  Text(
                    lesson.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.gray500,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.gray400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openLesson(BuildContext context, Lesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(lesson: lesson),
      ),
    );
  }
}
