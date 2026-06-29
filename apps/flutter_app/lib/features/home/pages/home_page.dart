import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// MemoryOS Home Page — dashboard with recent files, stats, and quick actions.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MemoryOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () => context.go('/search'),
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar
                  _QuickSearchBar().animate().fadeIn(duration: 300.ms),
                  const SizedBox(height: 24),

                  // Stats row
                  _StatsRow().animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  const SizedBox(height: 24),

                  // Quick actions
                  Text('Quick Actions', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _QuickActionsGrid().animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 24),

                  // Recent files
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Files', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () => context.go('/timeline'), child: const Text('See all')),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Recent files list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _RecentFileCard(index: index)
                    .animate()
                    .fadeIn(delay: (300 + index * 50).ms, duration: 300.ms)
                    .slideX(begin: 0.1, end: 0),
                childCount: 10,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add Files'),
      ),
    );
  }
}

class _QuickSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'search_bar',
      child: GestureDetector(
        onTap: () => context.go('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Text(
                'Search your memories...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '⌘K',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  static const _stats = [
    _Stat(icon: Icons.photo_library_outlined, label: 'Files', value: '0', color: Color(0xFF6366F1)),
    _Stat(icon: Icons.tag, label: 'Tags', value: '0', color: Color(0xFF8B5CF6)),
    _Stat(icon: Icons.folder_outlined, label: 'Collections', value: '0', color: Color(0xFF06B6D4)),
    _Stat(icon: Icons.storage_outlined, label: 'Size', value: '0 B', color: Color(0xFF10B981)),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _stats
          .map((stat) => Expanded(child: _StatCard(stat: stat)))
          .toList(),
    );
  }
}

class _Stat {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _Stat({required this.icon, required this.label, required this.value, required this.color});
}

class _StatCard extends StatelessWidget {
  final _Stat stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(stat.icon, color: stat.color, size: 20),
            const SizedBox(height: 8),
            Text(
              stat.value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              stat.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  static final _actions = [
    _Action(icon: Icons.add_photo_alternate_outlined, label: 'Import Files', path: null, color: const Color(0xFF6366F1)),
    _Action(icon: Icons.chat_bubble_outline, label: 'Ask AI', path: '/chat', color: const Color(0xFF8B5CF6)),
    _Action(icon: Icons.content_copy_outlined, label: 'Find Duplicates', path: '/duplicates', color: const Color(0xFFF59E0B)),
    _Action(icon: Icons.school_outlined, label: 'Study', path: '/learning', color: const Color(0xFF10B981)),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: _actions
          .map((a) => _ActionCard(action: a))
          .toList(),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final String? path;
  final Color color;
  const _Action({required this.icon, required this.label, required this.path, required this.color});
}

class _ActionCard extends StatelessWidget {
  final _Action action;
  const _ActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (action.path != null) context.go(action.path!);
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: action.color),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFileCard extends StatelessWidget {
  final int index;
  const _RecentFileCard({required this.index});

  static const _fileTypes = [
    (Icons.image_outlined, Color(0xFF6366F1), 'screenshot.png', '2.4 MB'),
    (Icons.picture_as_pdf_outlined, Color(0xFFEF4444), 'kubernetes-guide.pdf', '1.1 MB'),
    (Icons.audio_file_outlined, Color(0xFF10B981), 'meeting-recording.mp3', '45.2 MB'),
    (Icons.description_outlined, Color(0xFF3B82F6), 'aws-security-notes.docx', '234 KB'),
    (Icons.video_file_outlined, Color(0xFF8B5CF6), 'tutorial-video.mp4', '180 MB'),
  ];

  @override
  Widget build(BuildContext context) {
    final file = _fileTypes[index % _fileTypes.length];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: file.$2.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(file.$1, color: file.$2, size: 20),
        ),
        title: Text(file.$3, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        subtitle: Text(file.$4, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: () {},
      ),
    );
  }
}
