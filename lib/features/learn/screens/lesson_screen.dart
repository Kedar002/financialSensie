import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/lesson.dart';

/// Individual lesson screen.
/// Clean reading experience. No distractions.
/// Steve Jobs would read this.
class LessonScreen extends StatelessWidget {
  final Lesson lesson;

  const LessonScreen({
    super.key,
    required this.lesson,
  });

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
                    _buildTitle(context),
                    const SizedBox(height: AppTheme.spacing32),
                    ...lesson.sections.map((section) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppTheme.spacing24),
                          child: _buildSection(context, section),
                        )),
                    const SizedBox(height: AppTheme.spacing48),
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
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(
          Icons.chevron_left,
          color: AppTheme.black,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: AppTheme.spacing8),
        Text(
          lesson.subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.gray500,
              ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, LessonSection section) {
    switch (section.type) {
      case LessonSectionType.paragraph:
        return _buildParagraph(context, section);
      case LessonSectionType.highlight:
        return _buildHighlight(context, section);
      case LessonSectionType.bulletList:
        return _buildBulletList(context, section);
      case LessonSectionType.quote:
        return _buildQuote(context, section);
      case LessonSectionType.keyTakeaway:
        return _buildKeyTakeaway(context, section);
    }
  }

  Widget _buildParagraph(BuildContext context, LessonSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Text(
            section.title!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],
        Text(
          section.content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.7,
                color: AppTheme.gray600,
              ),
        ),
      ],
    );
  }

  Widget _buildHighlight(BuildContext context, LessonSection section) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Text(
        section.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.white,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildBulletList(BuildContext context, LessonSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.title != null) ...[
          Text(
            section.title!,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],
        if (section.content.isNotEmpty) ...[
          Text(
            section.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTheme.gray600,
                ),
          ),
          const SizedBox(height: AppTheme.spacing12),
        ],
        if (section.bulletPoints != null)
          ...section.bulletPoints!.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacing8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      decoration: const BoxDecoration(
                        color: AppTheme.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        point,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _buildQuote(BuildContext context, LessonSection section) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: const Border(
          left: BorderSide(
            color: AppTheme.black,
            width: 4,
          ),
        ),
      ),
      child: Text(
        section.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
              color: AppTheme.gray600,
            ),
      ),
    );
  }

  Widget _buildKeyTakeaway(BuildContext context, LessonSection section) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing8,
                  vertical: AppTheme.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.black,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Key Takeaway',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.white,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacing12),
          Text(
            section.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
