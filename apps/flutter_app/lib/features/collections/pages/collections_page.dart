import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Collections page — wired to CollectionsBloc.
class CollectionsPage extends StatefulWidget {
  const CollectionsPage({super.key});

  @override
  State<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends State<CollectionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<CollectionsBloc>().add(CollectionsLoadRequested());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) => [
              SliverAppBar(
                floating: true,
                snap: true,
                title: const Text('Collections'),
                bottom: TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'Smart'),
                    Tab(text: 'Manual'),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _showCreateDialog(context),
                    tooltip: 'Create collection',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _SearchBar(
                    onChanged: (v) => setState(() => _filter = v.toLowerCase()),
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabs,
              children: [
                _CollectionGrid(
                  collections: state.smart
                      .where((c) => c.name.toLowerCase().contains(_filter))
                      .toList(),
                  status: state.status,
                  isSmart: true,
                  onTap: (c) => context.go('/collections/${c.id}'),
                  onDelete: null, // Smart collections can't be deleted
                ),
                _CollectionGrid(
                  collections: state.manual
                      .where((c) => c.name.toLowerCase().contains(_filter))
                      .toList(),
                  status: state.status,
                  isSmart: false,
                  onTap: (c) => context.go('/collections/${c.id}'),
                  onDelete: (c) => context
                      .read<CollectionsBloc>()
                      .add(CollectionDeleted(c.id)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final ctl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Collection name',
            prefixIcon: Icon(Icons.folder_rounded),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              context.read<CollectionsBloc>().add(CollectionCreated(v.trim()));
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = ctl.text.trim();
              if (name.isNotEmpty) {
                context.read<CollectionsBloc>().add(CollectionCreated(name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Search collections...',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            fontSize: 13,
          ),
        ),
        style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
      ),
    );
  }
}

class _CollectionGrid extends StatelessWidget {
  final List<Collection> collections;
  final CollectionsStatus status;
  final bool isSmart;
  final void Function(Collection)? onTap;
  final void Function(Collection)? onDelete;

  const _CollectionGrid({
    required this.collections,
    required this.status,
    required this.isSmart,
    this.onTap,
    this.onDelete,
  });

  static const _smartCollections = [
    _SmartMeta('Cloud & DevOps', Icons.cloud_rounded, Color(0xFF0EA5E9), 'Infrastructure, Docker, Kubernetes, AWS'),
    _SmartMeta('Security', Icons.security_rounded, Color(0xFFEF4444), 'CVEs, certificates, passwords, audits'),
    _SmartMeta('Finance', Icons.attach_money_rounded, Color(0xFF10B981), 'Invoices, receipts, tax, banking'),
    _SmartMeta('Learning', Icons.school_rounded, Color(0xFF6366F1), 'Tutorials, notes, flashcards, books'),
    _SmartMeta('Meetings', Icons.groups_rounded, Color(0xFFF59E0B), 'Meeting notes, recordings, agendas'),
    _SmartMeta('Chess', Icons.sports_esports_rounded, Color(0xFF8B5CF6), 'Openings, analysis, games, tactics'),
    _SmartMeta('Screenshots', Icons.screenshot_monitor_rounded, Color(0xFF64748B), 'Screenshots from any app'),
    _SmartMeta('Travel', Icons.flight_rounded, Color(0xFF0891B2), 'Itineraries, tickets, visas, photos'),
    _SmartMeta('Medical', Icons.local_hospital_rounded, Color(0xFFDC2626), 'Reports, prescriptions, health data'),
    _SmartMeta('Research', Icons.science_rounded, Color(0xFF7C3AED), 'Papers, experiments, citations'),
    _SmartMeta('Code & Dev', Icons.code_rounded, Color(0xFF16A34A), 'Source code, configs, READMEs'),
    _SmartMeta('Personal', Icons.person_rounded, Color(0xFFDB2777), 'Personal memories, diary, photos'),
  ];

  @override
  Widget build(BuildContext context) {
    if (status == CollectionsStatus.loading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: 6,
        itemBuilder: (_, i) => const SkeletonBox(radius: 16)
            .animate()
            .fadeIn(delay: (i * 40).ms),
      );
    }

    final items = isSmart && collections.isEmpty
        ? _smartCollections
            .map((m) => _CollectionGridItem(
                  name: m.name,
                  icon: m.icon,
                  color: m.color,
                  subtitle: m.subtitle,
                  fileCount: 0,
                  isSmartTemplate: true,
                  onTap: () {},
                  onDelete: null,
                ))
            .toList()
        : collections
            .asMap()
            .entries
            .map((e) {
              final c = e.value;
              final meta = isSmart && e.key < _smartCollections.length
                  ? _smartCollections[e.key]
                  : null;
              return _CollectionGridItem(
                name: c.name,
                icon: meta?.icon ?? Icons.folder_rounded,
                color: meta?.color ?? DesignTokens.brand,
                subtitle: '${c.fileCount} files',
                fileCount: c.fileCount,
                isSmartTemplate: false,
                onTap: () => onTap?.call(c),
                onDelete: onDelete != null ? () => onDelete!(c) : null,
              );
            })
            .toList();

    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: isSmart ? Icons.auto_awesome_rounded : Icons.folder_open_rounded,
        title: isSmart ? 'No smart collections' : 'No manual collections',
        subtitle: isSmart
            ? 'Import and index files to populate smart collections.'
            : 'Create your first collection to organize files.',
        actionLabel: isSmart ? null : 'Create Collection',
        iconColor: DesignTokens.brand,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 800 ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          items[i].animate().fadeIn(delay: (i * 35).ms, duration: 200.ms)
              .slideY(begin: 0.04, end: 0),
    );
  }
}

class _SmartMeta {
  final String name;
  final IconData icon;
  final Color color;
  final String subtitle;
  const _SmartMeta(this.name, this.icon, this.color, this.subtitle);
}

class _CollectionGridItem extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String subtitle;
  final int fileCount;
  final bool isSmartTemplate;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _CollectionGridItem({
    required this.name,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.fileCount,
    required this.isSmartTemplate,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_CollectionGridItem> createState() => _CollectionGridItemState();
}

class _CollectionGridItemState extends State<_CollectionGridItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1, end: 0.96)
        .animate(CurvedAnimation(parent: _pressCtl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _pressCtl.forward(),
      onTapUp: (_) {
        _pressCtl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
                color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  const Spacer(),
                  if (widget.isSmartTemplate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DesignTokens.brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      ),
                      child: const Text('Auto',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.brand)),
                    )
                  else if (widget.onDelete != null)
                    InkWell(
                      onTap: widget.onDelete,
                      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                widget.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
