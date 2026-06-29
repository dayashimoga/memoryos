import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// File Detail — 3-tab layout with real AI actions via AiBloc.
class FileDetailPage extends StatefulWidget {
  final String fileId;
  const FileDetailPage({super.key, required this.fileId});

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Trigger AI check and summary when opened
    context.read<AiBloc>().add(AiCheckModel());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Construct a representative FileEntry from the fileId
    // (In production, HomeBloc holds the file — lookup via FileRepository)
    final entry = FileEntry(
      id: widget.fileId,
      path: '/home/user/files/${widget.fileId}',
      filename: '${widget.fileId}.file',
      extension: 'file',
      fileType: FileType.unknown,
      sizeBytes: 0,
      createdAt: DateTime.now(),
      modifiedAt: DateTime.now(),
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          entry.filename,
          style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? DesignTokens.error : null,
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              HapticFeedback.selectionClick();
            },
            tooltip: 'Favorite',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () {
              context.read<AiBloc>().add(AiSummarizeFile(widget.fileId));
              _tabs.animateTo(1);
            },
            tooltip: 'Summarize with AI',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
            onSelected: (v) => _handleAction(context, v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'explain',
                  child: ListTile(dense: true, leading: Icon(Icons.image_search_rounded, size: 16), title: Text('Explain Screenshot'))),
              const PopupMenuItem(
                  value: 'flashcards',
                  child: ListTile(dense: true, leading: Icon(Icons.style_rounded, size: 16), title: Text('Generate Flashcards'))),
              const PopupMenuItem(
                  value: 'tag',
                  child: ListTile(dense: true, leading: Icon(Icons.label_rounded, size: 16), title: Text('Auto-tag'))),
              const PopupMenuDivider(),
              const PopupMenuItem(
                  value: 'vault',
                  child: ListTile(dense: true, leading: Icon(Icons.lock_rounded, size: 16), title: Text('Move to Vault'))),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(dense: true, leading: Icon(Icons.delete_rounded, size: 16, color: Colors.red), title: Text('Remove', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'AI Insights'),
            Tab(text: 'Related'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DetailsTab(entry: entry),
          _AiInsightsTab(fileId: widget.fileId),
          _RelatedTab(fileId: widget.fileId),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'explain':
        context.read<AiBloc>().add(AiExplainFile(widget.fileId, AiExplainMode.screenshot));
        _tabs.animateTo(1);
      case 'flashcards':
        context.read<AiBloc>().add(AiGenerateFlashcards(widget.fileId));
        context.go('/learning');
      case 'tag':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Auto-tagging in progress...')),
        );
      case 'vault':
        context.go('/vault');
      case 'delete':
        _confirmDelete(context);
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove file?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        content: const Text('This removes the file from your index. The original file will NOT be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            style: FilledButton.styleFrom(backgroundColor: DesignTokens.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─── Details Tab ──────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  final FileEntry entry;
  const _DetailsTab({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = [
      ('Type', entry.fileType.name, Icons.insert_drive_file_rounded),
      ('Size', entry.formattedSize, Icons.data_usage_rounded),
      ('Created', '${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}', Icons.calendar_today_rounded),
      ('Modified', entry.timeAgo, Icons.edit_calendar_rounded),
      ('Extension', '.${entry.extension}', Icons.code_rounded),
      ('Status', 'Indexed', Icons.check_circle_rounded),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Preview placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightBg,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            border: Border.all(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FileTypeDisplay.iconBox(entry.extension, boxSize: 64),
              const SizedBox(height: 12),
              Text(entry.filename,
                  style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms),

        const SizedBox(height: 20),
        const SectionHeader(title: 'File Information'),
        const SizedBox(height: 8),

        // Metadata grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: metadata
              .map((m) => _MetaCard(label: m.$1, value: m.$2, icon: m.$3))
              .toList(),
        ),

        const SizedBox(height: 16),

        // Tags
        const SectionHeader(title: 'Tags'),
        const SizedBox(height: 8),
        if (entry.tags.isEmpty)
          PremiumCard(
            child: Row(
              children: [
                const Icon(Icons.label_outline_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No tags — use AI to auto-tag this file',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Color(0xFF64748B))),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Auto-tag',
                      style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.tags
                .map((t) => Chip(
                      label: Text(t,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () {},
                    ))
                .toList(),
          ),
      ],
    );
  }
}

class _MetaCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetaCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: DesignTokens.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                    )),
                Text(value,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AI Insights Tab ─────────────────────────────────────────────────────────

class _AiInsightsTab extends StatelessWidget {
  final String fileId;
  const _AiInsightsTab({required this.fileId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Model status banner
            if (!state.modelLoaded) _ModelNudge(),

            const SizedBox(height: 8),

            // Summary section
            PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          size: 16, color: DesignTokens.brand),
                      const SizedBox(width: 8),
                      const Text('AI Summary',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const Spacer(),
                      TextButton(
                        onPressed: state.status == AiStatus.thinking
                            ? null
                            : () => context
                                .read<AiBloc>()
                                .add(AiSummarizeFile(fileId)),
                        style: TextButton.styleFrom(
                            minimumSize: const Size(0, 32)),
                        child: const Text('Summarize',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (state.status == AiStatus.thinking)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            color: DesignTokens.brand, strokeWidth: 2),
                      ),
                    )
                  else if (state.lastSummary != null)
                    Text(state.lastSummary!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(height: 1.6))
                  else
                    Text('Tap "Summarize" to generate an AI summary of this file.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF94A3B8),
                            )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Explain actions
            const SectionHeader(title: 'Explain'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ExplainButton(
                    label: 'Screenshot',
                    icon: Icons.image_search_rounded,
                    onTap: () => context.read<AiBloc>().add(
                        AiExplainFile(fileId, AiExplainMode.screenshot)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExplainButton(
                    label: 'Code',
                    icon: Icons.code_rounded,
                    onTap: () => context.read<AiBloc>().add(
                        AiExplainFile(fileId, AiExplainMode.code)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ExplainButton(
                    label: 'Diagram',
                    icon: Icons.account_tree_rounded,
                    onTap: () => context.read<AiBloc>().add(
                        AiExplainFile(fileId, AiExplainMode.diagram)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ExplainButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ExplainButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: DesignTokens.brand, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ModelNudge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: DesignTokens.warning.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 14, color: DesignTokens.warning),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('No AI model loaded',
                style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: DesignTokens.warning)),
          ),
          TextButton(
            onPressed: () => GoRouter.of(context).go('/models'),
            style: TextButton.styleFrom(minimumSize: const Size(0, 0)),
            child: const Text('Get Model',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: DesignTokens.warning)),
          ),
        ],
      ),
    );
  }
}

// ─── Related Tab ─────────────────────────────────────────────────────────────

class _RelatedTab extends StatelessWidget {
  final String fileId;
  const _RelatedTab({required this.fileId});

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.hub_outlined,
      title: 'No related files',
      subtitle: 'Once files are indexed and vector search is active, related files will appear here.',
      iconColor: DesignTokens.brand,
    );
  }
}
