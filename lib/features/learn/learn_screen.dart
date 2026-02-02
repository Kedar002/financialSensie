import 'package:flutter/material.dart';
import 'data/learn_content.dart';
import 'level_screen.dart';

class LearnScreen extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const LearnScreen({super.key, this.onMenuTap});

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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (onMenuTap != null)
                    GestureDetector(
                      onTap: onMenuTap,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.menu, size: 20, color: Colors.black),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),

            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 32, 20, 8),
              child: Text(
                'Learn',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Text(
                'Master personal finance,\none lesson at a time.',
                style: TextStyle(
                  fontSize: 17,
                  color: Color(0xFF8E8E93),
                  height: 1.4,
                ),
              ),
            ),

            // Levels
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                itemCount: learnLevels.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final level = learnLevels[index];
                  return _LevelCard(
                    level: level,
                    levelNumber: index + 1,
                    onTap: () => _openLevel(context, level),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLevel(BuildContext context, LearnLevel level) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LevelScreen(level: level),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LearnLevel level;
  final int levelNumber;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.levelNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Level number
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$levelNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    level.subtitle,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
            // Lessons count
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${level.lessons.length}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'lessons',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFFC7C7CC),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
