import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// AI Chat — wired to AiBloc for real model status and conversation.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AiBloc, AiState>(
      listener: (context, state) {
        if (state.status == AiStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'AI error'),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
      },
      builder: (context, state) => _ChatView(aiState: state),
    );
  }
}

class _ChatView extends StatefulWidget {
  final AiState aiState;
  const _ChatView({required this.aiState});

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  static const _quickPrompts = [
    ('Summarize my cloud notes', Icons.cloud_rounded),
    ('What did I learn this week?', Icons.school_rounded),
    ('Find my security documents', Icons.security_rounded),
    ('Create flashcards from my AWS notes', Icons.style_rounded),
    ('What chess openings have I studied?', Icons.sports_esports_rounded),
    ('Suggest related topics to explore', Icons.explore_rounded),
  ];

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    context.read<AiBloc>().add(AiSendMessage(text));
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.aiState.messages.length < widget.aiState.messages.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.aiState;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _AiAvatar(),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Assistant',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                Text(
                  switch (state.status) {
                    AiStatus.checking => 'Checking model...',
                    AiStatus.ready => 'Model active',
                    AiStatus.noModel => 'No model loaded',
                    AiStatus.thinking => 'Thinking...',
                    AiStatus.error => 'Error',
                    AiStatus.idle => 'Idle',
                  },
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: switch (state.status) {
                      AiStatus.ready => DesignTokens.success,
                      AiStatus.thinking => DesignTokens.accent,
                      AiStatus.error => DesignTokens.error,
                      _ => const Color(0xFF94A3B8),
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.memory_rounded),
            onPressed: () => context.go('/models'),
            tooltip: 'AI Models',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: state.messages.isEmpty
                ? null
                : () => context.read<AiBloc>().add(AiClearConversation()),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // No model banner
          if (state.status == AiStatus.noModel) _ModelBanner(),

          // Messages
          Expanded(
            child: state.messages.isEmpty
                ? _WelcomeView(
                    prompts: _quickPrompts,
                    onSelect: (p) {
                      _controller.text = p;
                      _send();
                    })
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: state.messages.length +
                        (state.status == AiStatus.thinking ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == state.messages.length) {
                        return _TypingBubble()
                            .animate()
                            .fadeIn()
                            .slideY(begin: 0.08, end: 0);
                      }
                      return _MessageBubble(message: state.messages[i])
                          .animate()
                          .fadeIn(duration: 200.ms)
                          .slideY(begin: 0.06, end: 0);
                    },
                  ),
          ),

          // Quick prompts (only when empty)
          if (state.messages.isEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                physics: const BouncingScrollPhysics(),
                children: _quickPrompts
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            avatar: Icon(p.$2, size: 14),
                            label: Text(p.$1,
                                style: const TextStyle(
                                    fontFamily: 'Inter', fontSize: 12)),
                            onPressed: () {
                              _controller.text = p.$1;
                              _send();
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color:
                  isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.lightBorder,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: isDark
                            ? DesignTokens.darkCard
                            : DesignTokens.lightBg,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusXl),
                        border: Border.all(
                            color: isDark
                                ? DesignTokens.darkBorder
                                : DesignTokens.lightBorder),
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: state.modelLoaded
                              ? 'Ask about your memories...'
                              : 'Download a model to start chatting...',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: state.status == AiStatus.thinking ? null : _send,
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: state.status == AiStatus.thinking
                              ? [
                                  const Color(0xFF94A3B8),
                                  const Color(0xFF64748B)
                                ]
                              : [DesignTokens.brand, DesignTokens.accent],
                        ),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.brand.withOpacity(
                                state.status == AiStatus.thinking ? 0 : 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: state.status == AiStatus.thinking
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.arrow_upward_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Model Banner ─────────────────────────────────────────────────────────────

class _ModelBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: DesignTokens.warning.withOpacity(0.08),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: DesignTokens.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No AI model loaded — responses are powered by fallback logic',
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: DesignTokens.warning),
            ),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/models'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 32)),
            child: const Text('Get Models',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: DesignTokens.warning)),
          ),
        ],
      ),
    );
  }
}

// ─── Welcome View ─────────────────────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  final List<(String, IconData)> prompts;
  final ValueChanged<String> onSelect;

  const _WelcomeView({required this.prompts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AiAvatar(radius: 36),
            const SizedBox(height: 20),
            Text('MemoryOS AI',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
              'Ask anything about your files, get summaries,\ngenerate flashcards, or explore your knowledge base.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _AiAvatar(radius: 16),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? DesignTokens.brand
                    : (isDark
                        ? DesignTokens.darkCard
                        : DesignTokens.lightSurface),
                borderRadius:
                    BorderRadius.circular(DesignTokens.radiusLg).copyWith(
                  bottomRight: isUser ? const Radius.circular(4) : null,
                  bottomLeft: !isUser ? const Radius.circular(4) : null,
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: isDark
                            ? DesignTokens.darkBorder
                            : DesignTokens.lightBorder),
              ),
              child: Text(
                message.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isUser
                          ? Colors.white
                          : (isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF1E293B)),
                      height: 1.55,
                    ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: DesignTokens.brand.withOpacity(0.15),
              child: const Icon(Icons.person_rounded,
                  size: 16, color: DesignTokens.brand),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AiAvatar(radius: 16),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg)
                  .copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(
                  color: isDark
                      ? DesignTokens.darkBorder
                      : DesignTokens.lightBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: DesignTokens.brand,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(
                      begin: 0.5,
                      end: 1.0,
                      delay: (i * 140).ms,
                      duration: 420.ms,
                    )
                    .then()
                    .scaleXY(begin: 1.0, end: 0.5, duration: 420.ms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Avatar ────────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  final double radius;
  const _AiAvatar({this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DesignTokens.brand, DesignTokens.accent],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: DesignTokens.brand.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: radius * 0.75),
    );
  }
}
