import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Timeline — chronological visual browser with day/week/month grouping.
class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
      ),
      body: const _TimelineBody(),
    );
  }
}

class _TimelineBody extends StatelessWidget {
  const _TimelineBody();

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
