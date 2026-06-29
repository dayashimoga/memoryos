import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Rich file detail page — metadata, OCR text, AI summary, quick actions.
class FileDetailPage extends StatefulWidget {
  final String fileId;
  const FileDetailPage({super.key, required this.fileId});

  @override
  State<FileDetailPage> createState() => _FileDetailPageState();
}

class _FileDetailPageState extends State<FileDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _isFavorite = false;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Details'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? DesignTokens.error : null,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _isFavorite = !_isFavorite);
            },
            tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            onSelected: (action) {
              if (action == 'delete') _showDeleteConfirm(context);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'share', child: ListTile(dense: true, leading: Icon(Icons.share_rounded, size: 16), title: Text('Share'))),
              const PopupMenuItem(value: 'rename', child: ListTile(dense: true, leading: Icon(Icons.edit_rounded, size: 16), title: Text('Rename'))),
              const PopupMenuItem(value: 'move', child: ListTile(dense: true, leading: Icon(Icons.drive_file_move_rounded, size: 16), title: Text('Move to collection'))),
              const PopupMenuItem(value: 'vault', child: ListTile(dense: true, leading: Icon(Icons.lock_rounded, size: 16), title: Text('Add to vault'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_rounded, size: 16, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'AI Insights'),
            Tab(text: 'Related'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _DetailsTab(fileId: widget.fileId),
          _AiInsightsTab(fileId: widget.fileId),
          _RelatedTab(),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete File?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        content: const Text(
            'This will remove the file from MemoryOS index.\nThe original file will NOT be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style:
                FilledButton.styleFrom(backgroundColor: DesignTokens.error),
            child: const Text('Remove from Index'),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final String fileId;
  const _DetailsTab({required this.fileId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        // Preview placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.darkCard
                : DesignTokens.lightBg,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? DesignTokens.darkBorder
                    : DesignTokens.lightBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 48, color: DesignTokens.brand),
              const SizedBox(height: 8),
              Text('Preview unavailable',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('File ID: ${widget.fileId}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Metadata card
        PremiumCard(
          child: Column(
            children: [
              _MetaRow(Icons.title_rounded, 'Filename', 'Unknown'),
              const Divider(height: 1),
              _MetaRow(Icons.storage_rounded, 'Size', '—'),
              const Divider(height: 1),
              _MetaRow(Icons.calendar_today_rounded, 'Created', '—'),
              const Divider(height: 1),
              _MetaRow(Icons.update_rounded, 'Modified', '—'),
              const Divider(height: 1),
              _MetaRow(Icons.fingerprint_rounded, 'SHA-256', 'Not indexed'),
              const Divider(height: 1),
              _MetaRow(Icons.folder_rounded, 'Path', '—'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Tags
        PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.tag_rounded, size: 16, color: DesignTokens.brand),
                  const SizedBox(width: 8),
                  Text('Tags',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32)),
                    child: const Text('Add Tag',
                        style:
                            TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              Text('No tags yet — AI will suggest tags after indexing',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B))),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AiInsightsTab extends StatelessWidget {
  final String fileId;
  const _AiInsightsTab({required this.fileId});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        _InsightCard(
          icon: Icons.auto_awesome_rounded,
          iconColor: DesignTokens.brand,
          title: 'AI Summary',
          body: 'No AI model loaded. Download a model from Settings → AI Models to generate summaries.',
          action: 'Get Models',
          onAction: () {},
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.text_fields_rounded,
          iconColor: DesignTokens.tertiary,
          title: 'OCR Text',
          body: 'File not indexed yet. Import files and enable indexing.',
          action: null,
          onAction: null,
        ),
        const SizedBox(height: 12),
        _InsightCard(
          icon: Icons.style_rounded,
          iconColor: DesignTokens.accent,
          title: 'Flashcards',
          body: '0 flashcards generated for this file.',
          action: 'Generate',
          onAction: () {},
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.action,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (action != null && onAction != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28)),
                  child: Text(action!,
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5)),
        ],
      ),
    );
  }
}

class _RelatedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.link_rounded,
      title: 'No related files',
      subtitle: 'After indexing, MemoryOS will show files related by content, tags, and AI embeddings.',
      iconColor: DesignTokens.tertiary,
    );
  }
}
