import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Timeline — chronological visual browser with day/week/month grouping.
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  _TimelineGroup _group = _TimelineGroup.day;
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          // Group selector
          PopupMenuButton<_TimelineGroup>(
            initialValue: _group,
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Group by',
            onSelected: (g) => setState(() => _group = g),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: _TimelineGroup.day, child: Text('Day')),
              const PopupMenuItem(value: _TimelineGroup.week, child: Text('Week')),
              const PopupMenuItem(value: _TimelineGroup.month, child: Text('Month')),
              const PopupMenuItem(value: _TimelineGroup.year, child: Text('Year')),
            ],
          ),
          // Grid / list toggle
          IconButton(
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridView = !_gridView),
            tooltip: _gridView ? 'List view' : 'Grid view',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _TimelineBody(group: _group, gridView: _gridView),
    );
  }
}

enum _TimelineGroup { day, week, month, year }

class _TimelineBody extends StatelessWidget {
  final _TimelineGroup group;
  final bool gridView;

  const _TimelineBody({required this.group, required this.gridView});

  String _groupLabel(int index) {
    switch (group) {
      case _TimelineGroup.day:
        if (index == 0) return 'Today';
        if (index == 1) return 'Yesterday';
        return '$index days ago';
      case _TimelineGroup.week:
        if (index == 0) return 'This week';
        return '$index weeks ago';
      case _TimelineGroup.month:
        if (index == 0) return 'This month';
        return '$index months ago';
      case _TimelineGroup.year:
        if (index == 0) return 'This year';
        return '${2026 - index}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // When no files are indexed, show an empty state
    return EmptyStateWidget(
      icon: Icons.auto_awesome_mosaic_outlined,
      title: 'No files in timeline yet',
      subtitle: 'Import files to see them organized chronologically here.',
      actionLabel: 'Import Files',
      onAction: () => context.go('/'),
    );
  }
}
