/// A financial literacy lesson.
/// Clean model. Hardcoded content.
class Lesson {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final List<LessonSection> sections;

  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.sections,
  });
}

/// A section within a lesson.
class LessonSection {
  final String? title;
  final String content;
  final LessonSectionType type;
  final List<String>? bulletPoints;
  final String? highlightText;

  const LessonSection({
    this.title,
    required this.content,
    this.type = LessonSectionType.paragraph,
    this.bulletPoints,
    this.highlightText,
  });
}

/// Types of lesson sections for different visual treatments.
enum LessonSectionType {
  paragraph,
  highlight,
  bulletList,
  quote,
  keyTakeaway,
}
