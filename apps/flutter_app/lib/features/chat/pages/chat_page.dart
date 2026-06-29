import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// AI Chat page — fully-featured conversational interface over the knowledge base.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  final _messages = <_ChatMessage>[
    _ChatMessage(
      role: ChatRole.assistant,
      content:
          "Hi! I'm your MemoryOS AI assistant. I can answer questions about your files, summarize documents, generate flashcards, and help you find anything in your knowledge base.\n\nDownload a model in **Settings → AI Models** to enable full AI capabilities.",
    ),
  ];
  bool _isTyping = false;
  bool _modelLoaded = false;

  static const _quickPrompts = [
    ('What did I learn about Kubernetes?', Icons.cloud_rounded),
    ('Summarize my cloud security notes', Icons.security_rounded),
    ('Find my recent invoices', Icons.receipt_rounded),
    ('What chess openings have I studied?', Icons.sports_esports_rounded),
    ('Create flashcards from my AWS notes', Icons.style_rounded),
    ('Explain this screenshot', Icons.screenshot_rounded),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.selectionClick();
    setState(() {
      _messages.add(_ChatMessage(role: ChatRole.user, content: text));
      _controller.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          role: ChatRole.assistant,
          content: _modelLoaded
              ? 'Based on your indexed knowledge base...'
              : 'No AI model is loaded. Please download a model from **Settings → AI Models** to get real responses.',
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

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
                  _modelLoaded ? 'Model ready' : 'No model loaded',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: _modelLoaded
                        ? DesignTokens.success
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => context.go('/models'),
            tooltip: 'Manage AI Models',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => setState(() {
              _messages.removeWhere((m) => m.role == ChatRole.user);
              _messages.removeWhere((m) =>
                  _messages.indexOf(m) > 0 && m.role == ChatRole.assistant);
            }),
            tooltip: 'Clear conversation',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Model not loaded banner ────────────────────────
          if (!_modelLoaded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: DesignTokens.warning.withOpacity(0.08),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: DesignTokens.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Download an AI model to enable real responses',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: DesignTokens.warning,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/models'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Get Models',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: DesignTokens.warning)),
                  ),
                ],
              ),
            ),

          // ── Messages ───────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingBubble()
                      .animate()
                      .fadeIn()
                      .slideY(begin: 0.1, end: 0);
                }
                return _MessageBubble(message: _messages[index])
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.06, end: 0);
              },
            ),
          ),

          // ── Quick prompts ──────────────────────────────────
          if (_messages.length <= 1)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

          // ── Input area ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: isDark
                  ? DesignTokens.darkSurface
                  : DesignTokens.lightSurface,
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
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        style: Theme.of(context).textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Ask about your memories...',
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
                    onTap: _send,
                    child: AnimatedContainer(
                      duration: DesignTokens.durationFast,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [DesignTokens.brand, DesignTokens.accent],
                        ),
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.brand.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
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

// ─── Message Bubble ───────────────────────────────────────────────────────────

enum ChatRole { user, assistant }

class _ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  _ChatMessage({required this.role, required this.content})
      : timestamp = DateTime.now();
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
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
                    : (isDark ? DesignTokens.darkCard : DesignTokens.lightSurface),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg).copyWith(
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
                      height: 1.5,
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
              color:
                  isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
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
                  decoration: BoxDecoration(
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
