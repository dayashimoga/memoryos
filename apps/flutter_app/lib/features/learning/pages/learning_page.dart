import 'package:flutter/material.dart';

class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> with SingleTickerProviderStateMixin {
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
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _FlashcardsTab(),
          const Center(child: Text('Quizzes coming soon')),
          const Center(child: Text('No cards due today')),
        ],
      ),
    );
  }
}

class _FlashcardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 64),
          const SizedBox(height: 16),
          Text('No flashcards yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Index documents to auto-generate flashcards', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
