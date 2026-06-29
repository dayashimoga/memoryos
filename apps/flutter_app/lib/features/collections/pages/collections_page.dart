import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Collections page — smart and manual collections grid.
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Smart'),
            Tab(text: 'Manual'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showCreateDialog,
            tooltip: 'New collection',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search within collections
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search collections...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _SmartCollectionsGrid(search: _search),
                _ManualCollectionsGrid(search: _search),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Collection name',
            hintText: 'e.g., Project Alpha',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: create collection via repository
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

// ─── Smart Collections ────────────────────────────────────────────────────────

class _SmartCollectionsGrid extends StatelessWidget {
  final String search;

  static const _collections = [
    _CollData('Cloud & DevOps', Icons.cloud_rounded, Color(0xFF6366F1),
        'Kubernetes, AWS, Docker, Terraform files', 89),
    _CollData('Security', Icons.security_rounded, Color(0xFFEF4444),
        'Security reports, CVE notes, policies', 42),
    _CollData('Finance', Icons.account_balance_rounded, Color(0xFF10B981),
        'Invoices, receipts, bank statements', 40),
    _CollData('Learning', Icons.school_rounded, Color(0xFFEC4899),
        'Notes, tutorials, courses, flashcards', 128),
    _CollData('Meetings', Icons.meeting_room_rounded, Color(0xFF3B82F6),
        'Recordings, notes, action items', 64),
    _CollData('Chess', Icons.sports_esports_rounded, Color(0xFF64748B),
        'Opening theory, game analysis, puzzles', 32),
    _CollData('Screenshots', Icons.screenshot_monitor_rounded, Color(0xFF8B5CF6),
        'UI screenshots, error messages, diagrams', 210),
    _CollData('Travel', Icons.flight_rounded, Color(0xFF14B8A6),
        'Itineraries, bookings, photos', 18),
    _CollData('Medical', Icons.local_hospital_rounded, Color(0xFFEF4444),
        'Reports, prescriptions, lab results', 12),
    _CollData('Work', Icons.work_rounded, Color(0xFF3B82F6),
        'Projects, reports, presentations', 76),
    _CollData('Personal', Icons.person_rounded, Color(0xFF8B5CF6),
        'Personal documents, photos, notes', 54),
    _CollData('Code', Icons.code_rounded, Color(0xFF06B6D4),
        'Source code, configs, scripts', 93),
  ];

  const _SmartCollectionsGrid({required this.search});

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? _collections
        : _collections
            .where((c) => c.name.toLowerCase().contains(search))
            .toList();

    if (filtered.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.search_off_rounded,
        title: 'No collections found',
        subtitle: 'Try a different search term.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, i) => _CollectionCard(data: filtered[i])
          .animate()
          .fadeIn(delay: (i * 30).ms, duration: 250.ms)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
    );
  }
}

class _ManualCollectionsGrid extends StatelessWidget {
  final String search;
  const _ManualCollectionsGrid({required this.search});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.folder_outlined,
      title: 'No manual collections',
      subtitle: 'Create your own collections to organize files your way.',
      actionLabel: 'Create Collection',
      onAction: () {},
    );
  }
}

class _CollData {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final int fileCount;
  const _CollData(this.name, this.icon, this.color, this.description,
      this.fileCount);
}

class _CollectionCard extends StatelessWidget {
  final _CollData data;
  const _CollectionCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard(
      onTap: () => HapticFeedback.selectionClick(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(data.icon, color: data.color, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: data.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(
                  '${data.fileCount}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: data.color,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            data.name,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            data.description,
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
