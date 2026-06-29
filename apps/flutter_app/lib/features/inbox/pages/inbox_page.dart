import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Smart Inbox — AI-powered file triage.
///
/// Groups newly indexed files by AI-suggested action: Organize, Review,
/// Archive, Delete. Each card shows the AI reasoning and lets the user
/// apply the suggestion.
class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  // Tracks dismissed cards (applied or rejected)
  final _dismissed = <int>{};

  // Demo inbox items — replaced by AI repository stream when FFI is wired
  final _items = [
    _InboxItem(
      filename: 'kubernetes-notes-2024.md',
      extension: 'md',
      sizeBytes: 18432,
      suggestion: _Suggestion.organize,
      aiReason:
          'Add to Cloud & DevOps collection — matches K8s networking content',
      confidence: 0.94,
      targetCollection: 'Cloud & DevOps',
    ),
    _InboxItem(
      filename: 'screenshot_20241203_142301.png',
      extension: 'png',
      sizeBytes: 2097152,
      suggestion: _Suggestion.review,
      aiReason: 'Screenshot appears empty — consider deleting',
      confidence: 0.87,
      targetCollection: null,
    ),
    _InboxItem(
      filename: 'invoice_amazon_nov2024.pdf',
      extension: 'pdf',
      sizeBytes: 145920,
      suggestion: _Suggestion.organize,
      aiReason: 'Invoice detected — add to Finance collection',
      confidence: 0.96,
      targetCollection: 'Finance',
    ),
    _InboxItem(
      filename: 'chess_analysis_sicilian.pgn',
      extension: 'pgn',
      sizeBytes: 4096,
      suggestion: _Suggestion.organize,
      aiReason: 'Chess game file — add to Chess collection',
      confidence: 0.99,
      targetCollection: 'Chess',
    ),
    _InboxItem(
      filename: 'copy_of_copy_of_report.docx',
      extension: 'docx',
      sizeBytes: 256000,
      suggestion: _Suggestion.delete,
      aiReason: 'Likely duplicate — exact match found in your library',
      confidence: 0.91,
      targetCollection: null,
    ),
    _InboxItem(
      filename: 'travel_itinerary_japan.pdf',
      extension: 'pdf',
      sizeBytes: 512000,
      suggestion: _Suggestion.organize,
      aiReason: 'Travel document detected — add to Travel collection',
      confidence: 0.95,
      targetCollection: 'Travel',
    ),
  ];

  List<_InboxItem> get _active => _items
      .asMap()
      .entries
      .where((e) => !_dismissed.contains(e.key))
      .map((e) => e.value)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final active = _active;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Smart Inbox'),
            const SizedBox(width: 8),
            if (active.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.brand,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${active.length}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: active.isEmpty
                ? null
                : () {
                    setState(() {
                      _dismissed.addAll(_items
                          .asMap()
                          .entries
                          .where((e) =>
                              e.value.suggestion == _Suggestion.organize &&
                              !_dismissed.contains(e.key))
                          .map((e) => e.key));
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('All suggestions applied ✓')),
                    );
                  },
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Apply All',
                style: TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: active.isEmpty
          ? EmptyStateWidget(
              icon: Icons.inbox_rounded,
              title: 'Inbox empty',
              subtitle:
                  'All items have been organized. New imports will appear here.',
              iconColor: DesignTokens.success,
            )
          : Column(
              children: [
                // Stats bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: isDark ? DesignTokens.darkCard : DesignTokens.lightBg,
                  child: Row(
                    children: [
                      _SuggestionChip(
                          _Suggestion.organize,
                          _items
                              .where(
                                  (i) => i.suggestion == _Suggestion.organize)
                              .length),
                      const SizedBox(width: 8),
                      _SuggestionChip(
                          _Suggestion.review,
                          _items
                              .where((i) => i.suggestion == _Suggestion.review)
                              .length),
                      const SizedBox(width: 8),
                      _SuggestionChip(
                          _Suggestion.delete,
                          _items
                              .where((i) => i.suggestion == _Suggestion.delete)
                              .length),
                    ],
                  ),
                ),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    children: _items
                        .asMap()
                        .entries
                        .where((e) => !_dismissed.contains(e.key))
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _InboxCard(
                              item: e.value,
                              index: e.key,
                              onApply: () =>
                                  setState(() => _dismissed.add(e.key)),
                              onDismiss: () =>
                                  setState(() => _dismissed.add(e.key)),
                            )
                                .animate()
                                .fadeIn(
                                  delay: (e.key * 50).ms,
                                  duration: 200.ms,
                                )
                                .slideX(begin: 0.04, end: 0),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final _Suggestion suggestion;
  final int count;

  const _SuggestionChip(this.suggestion, this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: suggestion.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(suggestion.icon, size: 12, color: suggestion.color),
          const SizedBox(width: 4),
          Text('$count ${suggestion.label}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: suggestion.color,
              )),
        ],
      ),
    );
  }
}

class _InboxCard extends StatefulWidget {
  final _InboxItem item;
  final int index;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _InboxCard({
    required this.item,
    required this.index,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  State<_InboxCard> createState() => _InboxCardState();
}

class _InboxCardState extends State<_InboxCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      backgroundColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File icon
              FileTypeDisplay.iconBox(item.extension, boxSize: 44),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.filename,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.suggestion.color.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(item.suggestion.icon,
                                  size: 10, color: item.suggestion.color),
                              const SizedBox(width: 4),
                              Text(item.suggestion.label,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: item.suggestion.color,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(item.confidence * 100).round()}% confident',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.aiReason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                      maxLines: _expanded ? null : 1,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Icon(
                  _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: const Color(0xFF94A3B8),
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
              ),
            ],
          ),
          if (_expanded || true) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onApply,
                    icon: const Icon(Icons.check_rounded, size: 15),
                    label: Text(
                      item.suggestion == _Suggestion.organize
                          ? 'Add to ${item.targetCollection ?? "Collection"}'
                          : item.suggestion == _Suggestion.delete
                              ? 'Delete File'
                              : 'Mark Reviewed',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: item.suggestion.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: widget.onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Skip',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Data ─────────────────────────────────────────────────────────────────────

enum _Suggestion {
  organize,
  review,
  delete;

  String get label => switch (this) {
        _Suggestion.organize => 'Organize',
        _Suggestion.review => 'Review',
        _Suggestion.delete => 'Delete',
      };

  IconData get icon => switch (this) {
        _Suggestion.organize => Icons.drive_file_move_rounded,
        _Suggestion.review => Icons.visibility_rounded,
        _Suggestion.delete => Icons.delete_rounded,
      };

  Color get color => switch (this) {
        _Suggestion.organize => DesignTokens.brand,
        _Suggestion.review => DesignTokens.warning,
        _Suggestion.delete => DesignTokens.error,
      };
}

class _InboxItem {
  final String filename;
  final String extension;
  final int sizeBytes;
  final _Suggestion suggestion;
  final String aiReason;
  final double confidence;
  final String? targetCollection;

  const _InboxItem({
    required this.filename,
    required this.extension,
    required this.sizeBytes,
    required this.suggestion,
    required this.aiReason,
    required this.confidence,
    this.targetCollection,
  });
}
