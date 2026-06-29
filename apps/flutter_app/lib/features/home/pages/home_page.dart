import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Fully redesigned home dashboard — intelligent workspace.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _HomeAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _HeroSearchBar()
                      .animate()
                      .fadeIn(duration: 300.ms),
                  const SizedBox(height: 20),

                  // Storage ring + stats
                  _StorageOverviewCard()
                      .animate()
                      .fadeIn(delay: 60.ms, duration: 300.ms)
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 20),

                  // AI Suggestions banner
                  _AiSuggestionsBanner()
                      .animate()
                      .fadeIn(delay: 120.ms, duration: 300.ms),
                  const SizedBox(height: 20),

                  // Quick actions
                  SectionHeader(
                    title: 'Quick Actions',
                    trailing: null,
                  ),
                  const SizedBox(height: 8),
                  _QuickActionsRow()
                      .animate()
                      .fadeIn(delay: 180.ms, duration: 300.ms),
                  const SizedBox(height: 20),

                  // Smart collections
                  SectionHeader(
                    title: 'Smart Collections',
                    action: 'See all',
                    onAction: () => context.go('/collections'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Smart collections horizontal scroll
          SliverToBoxAdapter(
            child: _SmartCollectionsRow()
                .animate()
                .fadeIn(delay: 240.ms, duration: 300.ms),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Recent Files',
                action: 'Timeline',
                onAction: () => context.go('/timeline'),
              ),
            ),
          ),

          // Recent files list — virtualized
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RichFileCard(
                  entry: _demoEntries[index % _demoEntries.length],
                  index: index,
                )
                    .animate()
                    .fadeIn(delay: (260 + index * 30).ms, duration: 250.ms)
                    .slideX(begin: 0.03, end: 0),
                childCount: 12,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: _ContextualFab(),
    );
  }
}

// ─── Demo Data ────────────────────────────────────────────────────────────────

const _demoEntries = [
  _DemoEntry('kubernetes-architecture.png', 'png', 2_400_000, ['cloud', 'k8s'], 'Architecture diagram for microservices deployment'),
  _DemoEntry('aws-security-notes.pdf', 'pdf', 1_100_000, ['aws', 'security'], 'IAM best practices and VPC configuration notes'),
  _DemoEntry('meeting-recording.mp3', 'mp3', 45_200_000, ['meeting', 'work'], 'Weekly sync — Q3 roadmap discussion'),
  _DemoEntry('invoice-2024-11.xlsx', 'xlsx', 234_000, ['finance', 'invoice'], 'November 2024 client invoice — \$4,500'),
  _DemoEntry('chess-openings.md', 'md', 88_000, ['chess', 'learning'], 'Sicilian Defense variations and key lines'),
  _DemoEntry('tutorial-video.mp4', 'mp4', 180_000_000, ['learning', 'dev'], 'Flutter state management deep dive'),
];

class _DemoEntry {
  final String filename;
  final String ext;
  final int sizeBytes;
  final List<String> tags;
  final String summary;
  const _DemoEntry(this.filename, this.ext, this.sizeBytes, this.tags, this.summary);

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

// ─── App Bar ──────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 16,
      title: Row(
        children: [
          RichText(
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
          const Spacer(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () => context.go('/search'),
          tooltip: 'Search (⌘K)',
        ),
        IconButton(
          icon: Badge(
            label: const Text('3'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
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
                color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              ),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    color: DesignTokens.brand, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search your memories...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.brand.withOpacity(0.08),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSm),
                    border: Border.all(
                        color: DesignTokens.brand.withOpacity(0.2)),
                  ),
                  child: const Text(
                    '⌘K',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.brand,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Storage Overview Card ────────────────────────────────────────────────────

class _StorageOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              // Storage ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 0.0,
                      strokeWidth: 6,
                      backgroundColor: DesignTokens.brand.withOpacity(0.1),
                      color: DesignTokens.brand,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '0%',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: DesignTokens.brand,
                          ),
                        ),
                        Text(
                          'used',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w400,
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MiniStat(
                            label: 'Files',
                            value: '0',
                            color: DesignTokens.brand),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Tags',
                            value: '0',
                            color: DesignTokens.accent),
                        const SizedBox(width: 16),
                        _MiniStat(
                            label: 'Groups',
                            value: '0',
                            color: DesignTokens.tertiary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Recoverable storage hint
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DesignTokens.success.withOpacity(0.08),
              borderRadius:
                  BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_delete_outlined,
                    size: 14, color: DesignTokens.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Index files to discover recoverable storage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: DesignTokens.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/duplicates'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text(
                    'Scan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.success,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// ─── AI Suggestions Banner ────────────────────────────────────────────────────

class _AiSuggestionsBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      backgroundColor: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.brand, DesignTokens.accent],
              ),
              borderRadius:
                  BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Ready',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Download a model to enable AI features',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: () => context.go('/models'),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Download',
                style: TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Actions Row ────────────────────────────────────────────────────────

class _QuickActionsRow extends StatelessWidget {
  static final _actions = [
    _QA(Icons.add_photo_alternate_rounded, 'Import', DesignTokens.brand, null),
    _QA(Icons.chat_bubble_rounded, 'Ask AI', DesignTokens.accent, '/chat'),
    _QA(Icons.content_copy_rounded, 'Duplicates', DesignTokens.warning, '/duplicates'),
    _QA(Icons.school_rounded, 'Study', DesignTokens.success, '/learning'),
    _QA(Icons.lock_rounded, 'Vault', const Color(0xFF64748B), '/vault'),
    _QA(Icons.analytics_rounded, 'Storage', DesignTokens.tertiary, '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _actions
            .map((a) => _QuickActionChip(action: a))
            .toList(),
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

class _QuickActionChip extends StatelessWidget {
  final _QA action;
  const _QuickActionChip({required this.action});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          if (action.path != null) context.go(action.path!);
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
                color: isDark
                    ? DesignTokens.darkBorder
                    : DesignTokens.lightBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: action.color, size: 16),
              const SizedBox(width: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Smart Collections Row ────────────────────────────────────────────────────

class _SmartCollectionsRow extends StatelessWidget {
  static const _collections = [
    _Col('Cloud & DevOps', Icons.cloud_rounded, Color(0xFF6366F1), '89 files'),
    _Col('Finance', Icons.account_balance_rounded, Color(0xFF10B981), '40 files'),
    _Col('Learning', Icons.school_rounded, Color(0xFFEC4899), '128 files'),
    _Col('Meetings', Icons.meeting_room_rounded, Color(0xFF3B82F6), '64 files'),
    _Col('Chess', Icons.sports_esports_rounded, Color(0xFF64748B), '32 files'),
    _Col('Screenshots', Icons.screenshot_monitor_rounded, Color(0xFF8B5CF6), '210 files'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _collections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _CollectionChip(col: _collections[i]),
      ),
    );
  }
}

class _Col {
  final String name;
  final IconData icon;
  final Color color;
  final String count;
  const _Col(this.name, this.icon, this.color, this.count);
}

class _CollectionChip extends StatelessWidget {
  final _Col col;
  const _CollectionChip({required this.col});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => context.go('/collections'),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(DesignTokens.space12),
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: col.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(col.icon, color: col.color, size: 18),
            ),
            const Spacer(),
            Text(
              col.name,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              col.count,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Rich File Card ────────────────────────────────────────────────────────────

class _RichFileCard extends StatelessWidget {
  final _DemoEntry entry;
  final int index;

  const _RichFileCard({required this.entry, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space8),
      child: PremiumCard(
        onTap: () {},
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail / icon box
            FileTypeDisplay.iconBox(entry.ext, boxSize: 48),
            const SizedBox(width: DesignTokens.space12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filename
                  Text(
                    entry.filename,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),

                  // AI Summary
                  Text(
                    entry.summary,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Tags + size
                  Row(
                    children: [
                      ...entry.tags
                          .take(2)
                          .map((t) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.brand.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(
                                        DesignTokens.radiusFull),
                                  ),
                                  child: Text(
                                    t,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: DesignTokens.brand,
                                    ),
                                  ),
                                ),
                              )),
                      const Spacer(),
                      Text(
                        entry.formattedSize,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            _FileCardContextMenu(filename: entry.filename),
          ],
        ),
      ),
    );
  }
}

class _FileCardContextMenu extends StatelessWidget {
  final String filename;
  const _FileCardContextMenu({required this.filename});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF475569)
            : const Color(0xFF94A3B8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'open', child: ListTile(dense: true, leading: Icon(Icons.open_in_new_rounded, size: 16), title: Text('Open'))),
        const PopupMenuItem(value: 'summary', child: ListTile(dense: true, leading: Icon(Icons.auto_awesome_rounded, size: 16), title: Text('AI Summary'))),
        const PopupMenuItem(value: 'rename', child: ListTile(dense: true, leading: Icon(Icons.edit_rounded, size: 16), title: Text('Rename'))),
        const PopupMenuItem(value: 'move', child: ListTile(dense: true, leading: Icon(Icons.drive_file_move_rounded, size: 16), title: Text('Move to collection'))),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_rounded, size: 16, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)))),
      ],
    );
  }
}

// ─── Contextual FAB ───────────────────────────────────────────────────────────

class _ContextualFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(DesignTokens.radiusXl)),
          ),
          builder: (ctx) => _ImportBottomSheet(),
        );
      },
      backgroundColor: DesignTokens.brand,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Import',
          style: TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 14)),
      elevation: 4,
    );
  }
}

class _ImportBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.photo_library_rounded, 'Photo Library', 'Import photos and videos'),
      (Icons.folder_open_rounded, 'Files & Folders', 'Import any file type'),
      (Icons.screenshot_monitor_rounded, 'Screenshots', 'Import screenshots folder'),
      (Icons.mic_rounded, 'Voice Note', 'Record a voice memo'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
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
          Text('Import Files',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DesignTokens.brand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(item.$1, color: DesignTokens.brand, size: 20),
              ),
              title: Text(item.$2,
                  style: const TextStyle(
                      fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(item.$3,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
