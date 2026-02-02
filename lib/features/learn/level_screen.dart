import 'package:flutter/material.dart';
import 'data/learn_content.dart';
import 'lesson_screen.dart';

class LevelScreen extends StatelessWidget {
  final LearnLevel level;

  const LevelScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Text(
                level.title,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                '${level.lessons.length} lessons · ${_getTotalReadTime()}',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ),

            // Lessons list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: level.lessons.length,
                itemBuilder: (context, index) {
                  final lesson = level.lessons[index];
                  return _LessonTile(
                    lesson: lesson,
                    lessonNumber: index + 1,
                    isLast: index == level.lessons.length - 1,
                    onTap: () => _openLesson(context, lesson),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTotalReadTime() {
    int totalMinutes = 0;
    for (final lesson in level.lessons) {
      final match = RegExp(r'(\d+)').firstMatch(lesson.readTime);
      if (match != null) {
        totalMinutes += int.parse(match.group(1)!);
      }
    }
    return '$totalMinutes min read';
  }

  void _openLesson(BuildContext context, LearnLesson lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonScreen(lesson: lesson),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final LearnLesson lesson;
  final int lessonNumber;
  final bool isLast;
  final VoidCallback onTap;

  const _LessonTile({
    required this.lesson,
    required this.lessonNumber,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFFF2F2F7),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Lesson number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$lessonNumber',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.readTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC7C7CC),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
