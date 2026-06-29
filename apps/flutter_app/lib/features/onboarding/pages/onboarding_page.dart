import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.memory,
      title: 'Your Personal Memory OS',
      description:
          'MemoryOS organizes all your files, screenshots, documents, and media — automatically. 100% offline.',
      color: Color(0xFF6366F1),
    ),
    _OnboardingData(
      icon: Icons.search,
      title: 'Find Anything Instantly',
      description:
          'Search in plain English. "Show me AWS notes from last week" — your AI finds it in milliseconds.',
      color: Color(0xFF8B5CF6),
    ),
    _OnboardingData(
      icon: Icons.security,
      title: 'Your Data, Your Device',
      description:
          'Zero cloud. Zero telemetry. All AI runs locally on your device with AES-256 encryption.',
      color: Color(0xFF06B6D4),
    ),
    _OnboardingData(
      icon: Icons.auto_awesome,
      title: 'AI-Powered Intelligence',
      description:
          'Gemma, Phi, and Qwen run locally to summarize, categorize, and chat about your knowledge base.',
      color: Color(0xFF10B981),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) => _OnboardingSlide(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? colorScheme.primary
                              : colorScheme.outline,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: const Text('Back'),
                        ),
                      const Spacer(),
                      if (_currentPage < _pages.length - 1)
                        ElevatedButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          child: const Text('Next'),
                        )
                      else
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Get Started'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const _OnboardingData(
      {required this.icon,
      required this.title,
      required this.description,
      required this.color});
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingSlide({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [data.color, data.color.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                    color: data.color.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5)
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 56),
          ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 16),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
        ],
      ),
    );
  }
}
