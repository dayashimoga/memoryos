import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Learning page — flashcards, quizzes, spaced repetition.
class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Flashcards'),
            Tab(text: 'Quizzes'),
            Tab(text: 'Due Today'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => context.go('/chat'),
            tooltip: 'Generate with AI',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FlashcardsTab(),
          _QuizzesTab(),
          _DueTodayTab(),
        ],
      ),
    );
  }
}

// ─── Flashcards ───────────────────────────────────────────────────────────────

class _FlashcardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _LearningStatCard(label: 'Total Cards', value: '0', icon: Icons.style_rounded, color: DesignTokens.brand),
              const SizedBox(width: 12),
              _LearningStatCard(label: 'Due Today', value: '0', icon: Icons.today_rounded, color: DesignTokens.warning),
              const SizedBox(width: 12),
              _LearningStatCard(label: 'Mastered', value: '0', icon: Icons.check_circle_rounded, color: DesignTokens.success),
            ],
          ),
        ),
        Expanded(
          child: EmptyStateWidget(
            icon: Icons.style_outlined,
            title: 'No flashcards yet',
            subtitle: 'Index documents and use AI Chat to auto-generate\nflashcards from your knowledge base.',
            actionLabel: 'Open AI Chat',
            onAction: () => context.go('/chat'),
            iconColor: DesignTokens.brand,
          ),
        ),
      ],
    );
  }
}

class _QuizzesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.quiz_outlined,
      title: 'No quizzes yet',
      subtitle: 'AI-generated quizzes from your documents will appear here.',
      actionLabel: 'Open AI Chat',
      onAction: () => context.go('/chat'),
      iconColor: DesignTokens.accent,
    );
  }
}

class _DueTodayTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.celebration_outlined,
      title: 'You\'re all caught up!',
      subtitle: 'No cards are due for review today. Come back tomorrow.',
      iconColor: DesignTokens.success,
    );
  }
}

class _LearningStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _LearningStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
