import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Timeline — chronological visual browser with day/week/month grouping.
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Trigger a load if not already loaded
    final homeBloc = context.read<HomeBloc>();
    if (homeBloc.state.status == HomeStatus.initial) {
      homeBloc.add(HomeLoadRequested());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Days'),
            Tab(text: 'Weeks'),
            Tab(text: 'Months'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == HomeStatus.loaded &&
              state.recentFiles.isNotEmpty) {
            return TabBarView(
              controller: _tabController,
              children: [
                _TimelineView(files: state.recentFiles, groupBy: _GroupBy.day),
                _TimelineView(files: state.recentFiles, groupBy: _GroupBy.week),
                _TimelineView(
                    files: state.recentFiles, groupBy: _GroupBy.month),
              ],
            );
          }
          return EmptyStateWidget(
            icon: Icons.auto_awesome_mosaic_outlined,
            title: 'No files in timeline yet',
            subtitle:
                'Import files to see them organized chronologically here.',
            actionLabel: 'Import Files',
            onAction: () => context.go('/'),
          );
        },
      ),
    );
  }
}

enum _GroupBy { day, week, month }

class _TimelineView extends StatelessWidget {
  const _TimelineView({required this.files, required this.groupBy});

  final List<FileEntry> files;
  final _GroupBy groupBy;

  @override
  Widget build(BuildContext context) {
    final grouped = _groupFiles(files, groupBy);
    if (grouped.isEmpty) {
      return const Center(child: Text('No files found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final group = grouped[index];
        return _TimelineGroup(
          label: group.label,
          fileCount: group.files.length,
          files: group.files,
        );
      },
    );
  }

  List<_FileGroup> _groupFiles(List<FileEntry> files, _GroupBy by) {
    final Map<String, List<FileEntry>> groups = {};
    final sorted = List<FileEntry>.from(files)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    for (final file in sorted) {
      final key = _groupKey(file.createdAt, by);
      groups.putIfAbsent(key, () => []).add(file);
    }

    return groups.entries
        .map((e) => _FileGroup(label: e.key, files: e.value))
        .toList();
  }

  String _groupKey(DateTime dt, _GroupBy by) {
    switch (by) {
      case _GroupBy.day:
        return DateFormat('EEEE, MMMM d, yyyy').format(dt);
      case _GroupBy.week:
        final weekStart = dt.subtract(Duration(days: dt.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case _GroupBy.month:
        return DateFormat('MMMM yyyy').format(dt);
    }
  }
}

class _FileGroup {
  final String label;
  final List<FileEntry> files;
  const _FileGroup({required this.label, required this.files});
}

class _TimelineGroup extends StatelessWidget {
  const _TimelineGroup({
    required this.label,
    required this.fileCount,
    required this.files,
  });

  final String label;
  final int fileCount;
  final List<FileEntry> files;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$fileCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...files.map((file) => _TimelineFileCard(file: file)),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TimelineFileCard extends StatelessWidget {
  const _TimelineFileCard({required this.file});

  final FileEntry file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor =
        DesignTokens.categoryColors[file.fileType.name.toLowerCase()] ??
            theme.colorScheme.surfaceContainerHighest;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 12,
            child: Center(
              child: Container(
                width: 2,
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                onTap: () => context.push('/file/${file.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.15),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        child: Icon(
                          _iconForType(file.fileType),
                          color: typeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              file.filename,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${file.formattedSize} · ${DateFormat('h:mm a').format(file.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          file.extension.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForType(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image_rounded;
      case FileType.video:
        return Icons.videocam_rounded;
      case FileType.audio:
        return Icons.audiotrack_rounded;
      case FileType.document:
        return Icons.description_rounded;
      case FileType.pdf:
        return Icons.picture_as_pdf_rounded;
      case FileType.markdown:
        return Icons.article_rounded;
      case FileType.spreadsheet:
        return Icons.table_chart_rounded;
      case FileType.presentation:
        return Icons.slideshow_rounded;
      case FileType.archive:
        return Icons.folder_zip_rounded;
      case FileType.code:
        return Icons.code_rounded;
      case FileType.text:
        return Icons.text_snippet_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
}
