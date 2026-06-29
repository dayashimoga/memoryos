import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Storage Optimizer — wired to StorageBloc for real analysis data.
class DuplicatesPage extends StatelessWidget {
  const DuplicatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StorageBloc, StorageState>(
      listener: (context, state) {
        if (state.status == StorageStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error ?? 'Scan failed'),
              backgroundColor: DesignTokens.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Storage Optimizer'),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Duplicates'),
                  Tab(text: 'Similar Images'),
                  Tab(text: 'Large Files'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(state: state),
                _DuplicatesTab(state: state),
                _SimilarTab(state: state),
                _LargeFilesTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final StorageState state;
  const _OverviewTab({required this.state});

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final analysis = state.analysis;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScanning = state.status == StorageStatus.scanning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recoverable storage card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.success.withOpacity(isDark ? 0.15 : 0.06),
                  DesignTokens.tertiary.withOpacity(isDark ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                  color: DesignTokens.success.withOpacity(isDark ? 0.2 : 0.12)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isScanning
                          ? 'Scanning...'
                          : analysis != null
                              ? _formatBytes(analysis.recoverableBytes)
                              : '—',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: DesignTokens.success,
                      ),
                    ),
                    const Text(
                      'Recoverable storage',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: isScanning
                      ? null
                      : () => context
                          .read<StorageBloc>()
                          .add(StorageScanRequested()),
                  icon: isScanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.radar_rounded, size: 16),
                  label: Text(isScanning ? 'Scanning...' : 'Scan Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Analysis Results',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          if (isScanning) ...[
            _IssueCardSkeleton(),
            const SizedBox(height: 8),
            _IssueCardSkeleton(),
            const SizedBox(height: 8),
            _IssueCardSkeleton(),
          ] else if (analysis == null) ...[
            PremiumCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.radar_rounded,
                          size: 36, color: Color(0xFF64748B)),
                      const SizedBox(height: 8),
                      Text('Run a scan to analyze your storage',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            )
          ] else ...[
            _IssueCard(
              icon: Icons.content_copy_rounded,
              color: DesignTokens.warning,
              title: 'Exact Duplicates',
              subtitle:
                  '${state.duplicates.length} groups — ${_formatBytes(analysis.duplicateBytes)} recoverable',
              count: state.duplicates.length,
              onReview: () => DefaultTabController.of(context).animateTo(1),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0),
            const SizedBox(height: 8),
            _IssueCard(
              icon: Icons.blur_on_rounded,
              color: DesignTokens.error,
              title: 'Blurry Images',
              subtitle: '${analysis.blurryCount} blurry images detected',
              count: analysis.blurryCount,
              onReview: () {},
            )
                .animate()
                .fadeIn(delay: 60.ms, duration: 200.ms)
                .slideY(begin: 0.04, end: 0),
            const SizedBox(height: 8),
            _IssueCard(
              icon: Icons.screenshot_monitor_rounded,
              color: DesignTokens.accent,
              title: 'Empty Screenshots',
              subtitle:
                  '${analysis.emptyScreenshotCount} mostly blank screenshots',
              count: analysis.emptyScreenshotCount,
              onReview: () {},
            )
                .animate()
                .fadeIn(delay: 120.ms, duration: 200.ms)
                .slideY(begin: 0.04, end: 0),
            const SizedBox(height: 8),
            _IssueCard(
              icon: Icons.folder_zip_rounded,
              color: DesignTokens.brand,
              title: 'Similar Images',
              subtitle: '${state.similar.length} visual similarity clusters',
              count: state.similar.length,
              onReview: () => DefaultTabController.of(context).animateTo(2),
            )
                .animate()
                .fadeIn(delay: 180.ms, duration: 200.ms)
                .slideY(begin: 0.04, end: 0),
          ],

          if (analysis != null && analysis.recoverableBytes > 0) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    _confirmCleanup(context, analysis.recoverableBytes),
                icon: const Icon(Icons.auto_delete_rounded),
                label:
                    Text('Clean Up ${_formatBytes(analysis.recoverableBytes)}'),
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCleanup(BuildContext context, int bytes) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cleanup'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        content: Text(
          'This will safely remove ${_formatBytes(bytes)} of duplicate and redundant files from your index.\n\nOriginal files will NOT be permanently deleted — they will be moved to Trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              final ids = context
                  .read<StorageBloc>()
                  .state
                  .duplicates
                  .expand((g) => g.files.skip(1).map((f) => f.id))
                  .toList();
              if (ids.isNotEmpty) {
                context.read<StorageBloc>().add(StorageDeleteRequested(ids));
              }
            },
            style:
                FilledButton.styleFrom(backgroundColor: DesignTokens.success),
            child: const Text('Clean Up'),
          ),
        ],
      ),
    );
  }
}

class _IssueCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(height: 72, radius: 12);
  }
}

class _IssueCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onReview;

  const _IssueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (count > 0)
            TextButton(
              onPressed: onReview,
              child: const Text('Review',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

// ─── Duplicates Tab ───────────────────────────────────────────────────────────

class _DuplicatesTab extends StatelessWidget {
  final StorageState state;
  const _DuplicatesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.duplicates.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.content_copy_outlined,
        title: 'No duplicates found',
        subtitle: 'Run a scan to detect exact duplicate files.',
        actionLabel: 'Scan Now',
        onAction: () => context.read<StorageBloc>().add(StorageScanRequested()),
        iconColor: DesignTokens.warning,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.duplicates.length,
      itemBuilder: (context, i) {
        final group = state.duplicates[i];
        return _DuplicateGroupCard(group: group, index: i);
      },
    );
  }
}

class _DuplicateGroupCard extends StatefulWidget {
  final DuplicateGroup group;
  final int index;
  const _DuplicateGroupCard({required this.group, required this.index});

  @override
  State<_DuplicateGroupCard> createState() => _DuplicateGroupCardState();
}

class _DuplicateGroupCardState extends State<_DuplicateGroupCard> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String _fmt(int bytes) {
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
      if (bytes < 1024 * 1024 * 1024)
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusFull),
                  ),
                  child: Text(
                    '${widget.group.files.length} duplicates',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.warning,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_fmt(widget.group.wastedBytes)} wasted',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          ...widget.group.files.asMap().entries.map(
                (e) => CheckboxListTile(
                  dense: true,
                  title: Text(e.value.filename,
                      style:
                          const TextStyle(fontFamily: 'Inter', fontSize: 13)),
                  subtitle: Text(e.value.formattedSize,
                      style:
                          const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                  value: _selected.contains(e.value.id),
                  onChanged: e.key == 0
                      ? null // Keep first file (original)
                      : (v) => setState(() {
                            if (v == true) {
                              _selected.add(e.value.id);
                            } else {
                              _selected.remove(e.value.id);
                            }
                          }),
                  controlAffinity: ListTileControlAffinity.trailing,
                  checkboxShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context
                        .read<StorageBloc>()
                        .add(StorageDeleteRequested(_selected.toList()));
                    setState(() => _selected.clear());
                  },
                  style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.error),
                  child: Text('Delete ${_selected.length} selected'),
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (widget.index * 40).ms, duration: 200.ms);
  }
}

// ─── Similar Images Tab ───────────────────────────────────────────────────────

class _SimilarTab extends StatelessWidget {
  final StorageState state;
  const _SimilarTab({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.similar.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.photo_library_outlined,
        title: 'No similar images',
        subtitle:
            'Run a scan to find near-duplicate and visually similar images.',
        actionLabel: 'Scan Now',
        onAction: () => context.read<StorageBloc>().add(StorageScanRequested()),
        iconColor: DesignTokens.accent,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.similar.length,
      itemBuilder: (context, i) {
        final group = state.similar[i];
        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${group.files.length} similar images',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                      '${(group.similarity * 100).toStringAsFixed(0)}% similar',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: DesignTokens.accent,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 8),
              ...group.files.map((f) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: FileTypeDisplay.iconBox(f.extension, boxSize: 32),
                    title: Text(f.filename,
                        style:
                            const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                    subtitle: Text(f.formattedSize,
                        style:
                            const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                  )),
            ],
          ),
        ).animate().fadeIn(delay: (i * 40).ms, duration: 200.ms);
      },
    );
  }
}

// ─── Large Files Tab ──────────────────────────────────────────────────────────

class _LargeFilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.folder_zip_outlined,
      title: 'No large files detected',
      subtitle: 'Files over 50 MB will appear here after scanning.',
      actionLabel: 'Scan Now',
      onAction: () => context.read<StorageBloc>().add(StorageScanRequested()),
      iconColor: DesignTokens.brand,
    );
  }
}
