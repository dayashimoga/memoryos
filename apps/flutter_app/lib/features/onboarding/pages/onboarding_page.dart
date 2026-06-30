import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboardingKey = 'onboarding_complete_v1';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _completing = false;

  static const _pages = [
    _OnboardingData(
      icon: Icons.memory_rounded,
      title: 'Your Private Digital Brain',
      description:
          'MemoryOS indexes everything you save — files, photos, notes, screenshots — and makes it instantly searchable. 100% offline. No cloud, ever.',
      color: Color(0xFF6366F1),
      gradient: [Color(0xFF6366F1), Color(0xFF4F46E5)],
      emoji: '🧠',
    ),
    _OnboardingData(
      icon: Icons.search_rounded,
      title: 'Find Anything Instantly',
      description:
          'Type in plain English. "Show me that invoice from March" or "AWS notes from last week" — results appear in milliseconds with local full-text search.',
      color: Color(0xFF8B5CF6),
      gradient: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      emoji: '🔍',
    ),
    _OnboardingData(
      icon: Icons.lock_rounded,
      title: 'Your Data, Your Device',
      description:
          'Zero cloud. Zero telemetry. AES-256 encrypted vault for sensitive files. All AI runs on-device — no API keys, no subscriptions.',
      color: Color(0xFF06B6D4),
      gradient: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      emoji: '🔒',
    ),
    _OnboardingData(
      icon: Icons.construction_rounded,
      title: 'Powerful File Toolbox',
      description:
          'Convert documents, resize images, normalize audio, create encrypted archives and backups — all locally using a Rust-powered engine at native speed.',
      color: Color(0xFFF59E0B),
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      emoji: '⚡',
    ),
    _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      title: 'Offline AI Intelligence',
      description:
          'Gemma, Phi-3, and Qwen run locally to summarize, categorize, and chat about your knowledge base. AI that respects your privacy.',
      color: Color(0xFF10B981),
      gradient: [Color(0xFF10B981), Color(0xFF059669)],
      emoji: '✨',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() => _completing = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingKey, true);
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _OnboardingSlide(data: _pages[i], isDark: isDark),
              ),
            ),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                children: [
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: i == _currentPage ? 28 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          gradient: i == _currentPage
                              ? LinearGradient(
                                  colors: _pages[_currentPage].gradient)
                              : null,
                          color: i != _currentPage
                              ? (isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFE2E8F0))
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action buttons
                  Row(
                    children: [
                      if (_currentPage > 0)
                        OutlinedButton(
                          onPressed: () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Back',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600)),
                        ),
                      const Spacer(),
                      if (_currentPage < _pages.length - 1)
                        FilledButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: page.color,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _completing ? null : _complete,
                          icon: _completing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.rocket_launch_rounded,
                                  size: 18),
                          label: const Text(
                            'Get Started',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: page.color,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
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
  final List<Color> gradient;
  final String emoji;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
    required this.emoji,
  });
}

class _OnboardingSlide extends StatelessWidget {
  final _OnboardingData data;
  final bool isDark;
  const _OnboardingSlide({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon hero
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: data.gradient,
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(data.icon,
                    color: Colors.white.withOpacity(0.15), size: 100),
                Icon(data.icon, color: Colors.white, size: 60),
              ],
            ),
          )
              .animate()
              .scale(
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                  begin: const Offset(0.5, 0.5))
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 16),

          // Emoji badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: data.color.withOpacity(0.25)),
            ),
            child: Text(data.emoji, style: const TextStyle(fontSize: 18)),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 32),

          // Title
          Text(
            data.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 250.ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0, delay: 250.ms, duration: 400.ms),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF475569),
                  height: 1.65,
                  letterSpacing: 0.1,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
        ],
      ),
    );
  }
}

/// Call this in main() before runApp to know if onboarding is needed.
Future<bool> isOnboardingComplete() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingKey) ?? false;
}
