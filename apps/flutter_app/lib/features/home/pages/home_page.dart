import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Redesigned Home Dashboard — wired to HomeBloc for real data.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      listener: (context, state) {
        if (state.status == HomeStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'An error occurred'),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            context.read<HomeBloc>().add(HomeRefreshRequested());
            await Future.delayed(const Duration(milliseconds: 800));
          },
          color: DesignTokens.brand,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _HomeAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Search / Command Bar ────────────────────
                      _HeroSearchBar().animate().fadeIn(duration: 300.ms),
                      const SizedBox(height: 20),

                      // ── Storage Overview ─────────────────────────
                      if (state.status == HomeStatus.loading)
                        const SkeletonBox(height: 120, radius: 16)
                            .animate()
                            .fadeIn()
                      else
                        _StorageCard(
                          stats: state.stats,
                          indexStats: state.indexStats,
                        )
                            .animate()
                            .fadeIn(delay: 60.ms)
                            .slideY(begin: 0.04, end: 0),

                      const SizedBox(height: 20),

                      // ── AI status banner ─────────────────────────
                      _AiBanner().animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),

                      // ── Quick actions ─────────────────────────────
                      const SectionHeader(title: 'Quick Actions'),
                      const SizedBox(height: 8),
                      _QuickActions().animate().fadeIn(delay: 140.ms),
                      const SizedBox(height: 20),

                      // ── Recent files header ───────────────────────
                      SectionHeader(
                        title: 'Recent Files',
                        action: 'Timeline',
                        onAction: () => context.go('/timeline'),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),

              // ── Recent files list ──────────────────────────────
              if (state.status == HomeStatus.loading)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: const SkeletonBox(height: 80, radius: 12),
                      ).animate().fadeIn(delay: (i * 40).ms),
                      childCount: 6,
                    ),
                  ),
                )
              else if (state.recentFiles.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyStateWidget(
                    icon: Icons.inbox_outlined,
                    title: 'No files yet',
                    subtitle:
                        'Import files to start building your Memory Library.',
                    actionLabel: 'Import Files',
                    onAction: () => _showImportSheet(context),
                    iconColor: DesignTokens.brand,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    itemBuilder: (context, i) =>
                        _FileCard(entry: state.recentFiles[i], index: i)
                            .animate()
                            .fadeIn(delay: (i * 25).ms, duration: 220.ms)
                            .slideY(begin: 0.04, end: 0),
                    childCount: state.recentFiles.length,
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  void _showImportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusXl)),
      ),
      builder: (_) => _ImportSheet(),
    );
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Memory',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
            ),
            TextSpan(
              text: 'OS',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: DesignTokens.brand,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.go('/search'),
          tooltip: 'Search (⌘K)',
        ),
        IconButton(
          icon: const Icon(Icons.auto_awesome_outlined),
          onPressed: () => context.go('/chat'),
          tooltip: 'AI Assistant',
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => context.go('/settings'),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ─── Hero Search Bar ──────────────────────────────────────────────────────────

class _HeroSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => context.go('/search'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                color:
                    isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded,
                    color: DesignTokens.brand, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search files, ask AI, run commands...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                  ),
                ),
                _ShortcutBadge('⌘K'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String label;
  const _ShortcutBadge(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(color: DesignTokens.brand.withOpacity(0.2)),
      ),
      child: Text(label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: DesignTokens.brand,
          )),
    );
  }
}

// ─── Storage Card ─────────────────────────────────────────────────────────────

class _StorageCard extends StatelessWidget {
  final StorageStats stats;
  final IndexStats indexStats;

  const _StorageCard({required this.stats, required this.indexStats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usageRatio = stats.totalSizeBytes > 0 && stats.usedSizeBytes > 0
        ? stats.usedSizeBytes / stats.totalSizeBytes
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  DesignTokens.brand.withOpacity(0.15),
                  DesignTokens.accent.withOpacity(0.08),
                ]
              : [
                  DesignTokens.brand.withOpacity(0.06),
                  DesignTokens.accent.withOpacity(0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: DesignTokens.brand.withOpacity(isDark ? 0.2 : 0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: usageRatio.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: DesignTokens.brand.withOpacity(0.1),
                      color: DesignTokens.brand,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(usageRatio * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: DesignTokens.brand,
                          ),
                        ),
                        const Text(
                          'used',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Library Overview',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MiniStat(
                            label: 'Files',
                            value: '${stats.totalFiles}',
                            color: DesignTokens.brand),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Indexed',
                            value: '${indexStats.indexedFiles}',
                            color: DesignTokens.success),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Pending',
                            value: '${indexStats.pendingFiles}',
                            color: DesignTokens.warning),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (stats.recoverableBytes > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: DesignTokens.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_delete_outlined,
                      size: 14, color: DesignTokens.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${stats.formattedRecoverable} recoverable — duplicates detected',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: DesignTokens.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).go('/duplicates'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text('Clean Up',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.success,
                        )),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: color)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Inter', fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }
}

// ─── AI Banner ────────────────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return PremiumCard(
          backgroundColor:
              isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: state.modelLoaded
                      ? const LinearGradient(
                          colors: [DesignTokens.brand, DesignTokens.success])
                      : const LinearGradient(
                          colors: [DesignTokens.brand, DesignTokens.accent]),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  state.modelLoaded
                      ? Icons.check_circle_rounded
                      : Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.modelLoaded
                          ? 'AI Model Active'
                          : 'AI Ready to Setup',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      state.modelLoaded
                          ? 'All AI features enabled — fully local & private'
                          : 'Download a model to unlock AI features',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!state.modelLoaded)
                FilledButton.tonal(
                  onPressed: () => context.go('/models'),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Download',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  static const _actions = [
    _QA(Icons.add_photo_alternate_rounded, 'Import', DesignTokens.brand, null),
    _QA(Icons.chat_bubble_rounded, 'Ask AI', DesignTokens.accent, '/chat'),
    _QA(Icons.hub_rounded, 'Galaxy', Color(0xFF8B5CF6), '/galaxy'),
    _QA(Icons.transform_rounded, 'Converter', Colors.orange, '/toolbox'),
    _QA(Icons.move_to_inbox_rounded, 'Organizer', Colors.teal, '/inbox'),
    _QA(Icons.auto_delete_rounded, 'Cleanup', DesignTokens.warning,
        '/duplicates'),
    _QA(Icons.school_rounded, 'Study', DesignTokens.success, '/learning'),
    _QA(Icons.lock_rounded, 'Vault', Color(0xFF64748B), '/vault'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _actions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => _ActionChip(action: _actions[i]),
      ),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final String? path;
  const _QA(this.icon, this.label, this.color, this.path);
}

class _ActionChip extends StatelessWidget {
  final _QA action;
  const _ActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        if (action.path != null) {
          context.go(action.path!);
        } else {
          // Import
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusXl)),
            ),
            builder: (_) => _ImportSheet(),
          );
        }
      },
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
              color:
                  isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.color, size: 16),
            const SizedBox(width: 6),
            Text(action.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF1E293B),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── File Card ────────────────────────────────────────────────────────────────

class _FileCard extends StatelessWidget {
  final FileEntry entry;
  final int index;

  const _FileCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumCard(
      onTap: () => context.go('/file/${entry.id}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large preview area
          Container(
            height: index % 2 == 0 ? 140 : 180, // Staggered height
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? DesignTokens.darkBg : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusLg),
              ),
            ),
            child: Center(
              child: FileTypeDisplay.iconBox(entry.extension, boxSize: 56),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.filename,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _FileContextMenu(entry: entry),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(entry.formattedSize,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 10)),
                    const Spacer(),
                    Text(entry.timeAgo,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FileContextMenu extends StatelessWidget {
  final FileEntry entry;
  const _FileContextMenu({required this.entry});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          size: 18,
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF475569)
              : const Color(0xFF94A3B8)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
      onSelected: (action) async {
        switch (action) {
          case 'open':
            context.go('/file/${entry.id}');
          case 'favorite':
            context.read<HomeBloc>();
          case 'ask_ai':
            context.go('/chat');
          case 'delete':
            _confirmDelete(context);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
            value: 'open',
            child: ListTile(
                dense: true,
                leading: Icon(Icons.open_in_new_rounded, size: 16),
                title: Text('Open'))),
        const PopupMenuItem(
            value: 'favorite',
            child: ListTile(
                dense: true,
                leading: Icon(Icons.favorite_border_rounded, size: 16),
                title: Text('Add to favorites'))),
        const PopupMenuItem(
            value: 'ask_ai',
            child: ListTile(
                dense: true,
                leading: Icon(Icons.auto_awesome_rounded, size: 16),
                title: Text('Ask AI about this'))),
        const PopupMenuDivider(),
        const PopupMenuItem(
            value: 'delete',
            child: ListTile(
                dense: true,
                leading:
                    Icon(Icons.delete_rounded, size: 16, color: Colors.red),
                title: Text('Remove', style: TextStyle(color: Colors.red)))),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from index?'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        content: Text(
            'Remove "${entry.filename}" from MemoryOS?\nThe original file will NOT be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HomeBloc>();
            },
            style: FilledButton.styleFrom(backgroundColor: DesignTokens.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

// ─── Import Sheet ─────────────────────────────────────────────────────────────

class _ImportSheet extends StatelessWidget {
  static const _options = [
    (Icons.photo_library_rounded, 'Photo Library', 'Import photos and videos'),
    (Icons.folder_open_rounded, 'Files & Folders', 'Import any file type'),
    (
      Icons.screenshot_monitor_rounded,
      'Screenshots Folder',
      'Import screenshot directory'
    ),
    (Icons.mic_rounded, 'Voice Note', 'Record a new voice memo'),
    (Icons.link_rounded, 'URL / Web Page', 'Save a web page to your library'),
  ];

  Future<void> _handleImport(BuildContext context, String optionName) async {
    final homeBloc = context.read<HomeBloc>();
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context); // Dismiss sheet first
    try {
      if (optionName == 'Photo Library') {
        final result = await fp.FilePicker.platform.pickFiles(
          type: fp.FileType.media,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          homeBloc.add(HomeFileImported(path));
        }
      } else if (optionName == 'Files & Folders' ||
          optionName == 'Screenshots Folder') {
        final result = await fp.FilePicker.platform.pickFiles(
          type: fp.FileType.any,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          homeBloc.add(HomeFileImported(path));
        }
      } else if (optionName == 'Voice Note') {
        final result = await fp.FilePicker.platform.pickFiles(
          type: fp.FileType.audio,
          allowMultiple: false,
        );
        if (result != null && result.files.single.path != null) {
          final path = result.files.single.path!;
          homeBloc.add(HomeFileImported(path));
        }
      } else if (optionName == 'URL / Web Page') {
        if (context.mounted) {
          _showUrlImportDialog(context);
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to import: $e'),
          backgroundColor: DesignTokens.error,
        ),
      );
    }
  }

  void _showUrlImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Web Page'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
            labelText: 'Web Page URL',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(ctx);
                context.read<HomeBloc>().add(HomeFileImported(url));
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Import',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._options.map(
              (opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: DesignTokens.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(opt.$1, color: DesignTokens.brand, size: 20),
                ),
                title: Text(opt.$2,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                subtitle: Text(opt.$3,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                onTap: () => _handleImport(context, opt.$2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
