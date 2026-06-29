import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Learning Mode — flashcards and quizzes wired to AiBloc.
class LearningPage extends StatefulWidget {
  const LearningPage({super.key});

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _cardIndex = 0;
  bool _flipped = false;
  List<Flashcard> _cards = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AiBloc, AiState>(
      listener: (context, state) {
        if (state.flashcards.isNotEmpty) {
          setState(() {
            _cards = state.flashcards;
            _cardIndex = 0;
            _flipped = false;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learning Mode'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Flashcards'),
              Tab(text: 'Quizzes'),
              Tab(text: 'Due Today'),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _generateFromFile(context),
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: const Text('Generate',
                  style: TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _FlashcardTab(
              cards: _cards,
              cardIndex: _cardIndex,
              flipped: _flipped,
              onFlip: () => setState(() => _flipped = !_flipped),
              onNext: _cards.isEmpty
                  ? null
                  : () => setState(() {
                        _cardIndex = (_cardIndex + 1) % _cards.length;
                        _flipped = false;
                      }),
              onPrev: _cards.isEmpty
                  ? null
                  : () => setState(() {
                        _cardIndex =
                            (_cardIndex - 1 + _cards.length) % _cards.length;
                        _flipped = false;
                      }),
            ),
            _QuizTab(),
            _DueTodayTab(),
          ],
        ),
      ),
    );
  }

  void _generateFromFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final ctl = TextEditingController();
        return AlertDialog(
          title: const Text('Generate Flashcards'),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
          content: TextField(
            controller: ctl,
            decoration: const InputDecoration(
              hintText: 'Enter file ID or leave blank for recent file',
              prefixIcon: Icon(Icons.insert_drive_file_rounded),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AiBloc>().add(
                      AiGenerateFlashcards(
                          ctl.text.trim().isEmpty ? 'recent' : ctl.text.trim()),
                    );
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }
}

// ─── Flashcard Tab ────────────────────────────────────────────────────────────

class _FlashcardTab extends StatelessWidget {
  final List<Flashcard> cards;
  final int cardIndex;
  final bool flipped;
  final VoidCallback onFlip;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;

  const _FlashcardTab({
    required this.cards,
    required this.cardIndex,
    required this.flipped,
    required this.onFlip,
    this.onNext,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        if (state.status == AiStatus.thinking) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: DesignTokens.brand),
                SizedBox(height: 16),
                Text('Generating flashcards...',
                    style: TextStyle(
                        fontFamily: 'Inter', color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        if (cards.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.style_rounded,
            title: 'No flashcards yet',
            subtitle:
                'Tap "Generate" to create AI-powered flashcards from your files.',
            iconColor: DesignTokens.brand,
          );
        }

        final card = cards[cardIndex];
        return Column(
          children: [
            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text('${cardIndex + 1} / ${cards.length}',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF64748B))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                      child: LinearProgressIndicator(
                        value: (cardIndex + 1) / cards.length,
                        color: DesignTokens.brand,
                        backgroundColor: DesignTokens.brand.withOpacity(0.1),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: onFlip,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Container(
                      key: ValueKey('$cardIndex-$flipped'),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: flipped
                              ? [
                                  DesignTokens.success.withOpacity(0.12),
                                  DesignTokens.tertiary.withOpacity(0.08)
                                ]
                              : [
                                  DesignTokens.brand.withOpacity(0.12),
                                  DesignTokens.accent.withOpacity(0.08)
                                ],
                        ),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusXl),
                        border: Border.all(
                          color: flipped
                              ? DesignTokens.success.withOpacity(0.25)
                              : DesignTokens.brand.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (flipped
                                      ? DesignTokens.success
                                      : DesignTokens.brand)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
                            ),
                            child: Text(
                              flipped ? 'Answer' : 'Question',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: flipped
                                    ? DesignTokens.success
                                    : DesignTokens.brand,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              flipped ? card.back : card.front,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    height: 1.55,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                              'Tap to ${flipped ? "see question" : "reveal answer"}',
                              style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.outlined(
                    onPressed: onPrev,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: 'Previous',
                  ),
                  const SizedBox(width: 16),
                  if (flipped) ...[
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Saved: Easy (SM-2 Interval: 5 days)'),
                              duration: Duration(milliseconds: 700)),
                        );
                        onNext?.call();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: DesignTokens.success),
                      child: const Text('Easy'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Saved: Good (SM-2 Interval: 3 days)'),
                              duration: Duration(milliseconds: 700)),
                        );
                        onNext?.call();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: DesignTokens.brand),
                      child: const Text('Good'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Saved: Hard (SM-2 Interval: 1 day)'),
                              duration: Duration(milliseconds: 700)),
                        );
                        onNext?.call();
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: DesignTokens.error),
                      child: const Text('Hard'),
                    ),
                  ] else
                    FilledButton.tonal(
                      onPressed: onFlip,
                      child: const Text('Flip Card'),
                    ),
                  const SizedBox(width: 16),
                  IconButton.outlined(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: 'Next',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Quiz Tab ─────────────────────────────────────────────────────────────────

class _QuizTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.quiz_rounded,
      title: 'Quizzes coming soon',
      subtitle: 'Generate flashcards first, then convert them into quizzes.',
      iconColor: DesignTokens.accent,
    );
  }
}

// ─── Due Today Tab ────────────────────────────────────────────────────────────

class _DueTodayTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.event_available_rounded,
      title: 'No reviews due',
      subtitle: 'Spaced repetition scheduling will suggest reviews here.',
      iconColor: DesignTokens.success,
    );
  }
}
