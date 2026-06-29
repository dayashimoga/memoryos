import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Smart Inbox — AI-assisted triage for newly imported files.
class SmartInboxPage extends StatefulWidget {
  const SmartInboxPage({super.key});

  @override
  State<SmartInboxPage> createState() => _SmartInboxPageState();
}

class _SmartInboxPageState extends State<SmartInboxPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Inbox'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: const Text('Process All'),
          ),
        ],
      ),
      body: EmptyStateWidget(
        icon: Icons.inbox_rounded,
        title: 'Inbox is empty',
        subtitle: 'Newly imported files appear here for AI triage.\nAI will suggest actions: rename, categorize, or delete.',
        actionLabel: 'Import Files',
        onAction: () => context.go('/'),
        iconColor: DesignTokens.tertiary,
      ),
    );
  }
}
