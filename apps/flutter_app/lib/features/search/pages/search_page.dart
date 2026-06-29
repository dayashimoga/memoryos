import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Universal command center search page.
class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late TabController _tabController;

  String _query = '';
  String _activeFilter = 'All';
  bool _showResults = false;

  static const _filters = [
    'All', 'Images', 'Documents', 'Videos', 'Audio', 'Archives', 'Screenshots',
  ];

  static const _suggestions = [
    ('Find the AWS architecture screenshot I saved last year', Icons.screenshot_monitor_rounded),
    ('Show all Kubernetes-related documents', Icons.cloud_rounded),
    ('Invoices from 2024', Icons.receipt_long_rounded),
    ('Meeting recordings last month', Icons.mic_rounded),
    ('Chess opening theory notes', Icons.sports_esports_rounded),
    ('Videos longer than 10 minutes', Icons.video_library_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focusNode = FocusNode();
    _tabController = TabController(length: _filters.length, vsync: this);
    _query = widget.initialQuery ?? '';
    _showResults = _query.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery == null) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    final trimmed = q.trim();
    setState(() {
      _query = trimmed;
      _showResults = trimmed.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Search header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Hero(
                tag: 'search_bar',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignTokens.darkCard
                          : DesignTokens.lightSurface,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusXl),
                      border: Border.all(
                        color: isDark
                            ? DesignTokens.darkBorder
                            : DesignTokens.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 1,
                            textInputAction: TextInputAction.search,
                            keyboardType: TextInputType.text,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search memories...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            onChanged: (v) => Future.delayed(
                              const Duration(milliseconds: 280),
                              () {
                                if (mounted &&
                                    _controller.text == v) {
                                  _onSearch(v);
                                }
                              },
                            ),
                            onSubmitted: _onSearch,
                          ),
                        ),
                        if (_controller.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _controller.clear();
                              setState(() {
                                _query = '';
                                _showResults = false;
                              });
                              _focusNode.requestFocus();
                            },
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.mic_outlined),
                            onPressed: () {},
                            tooltip: 'Voice search',
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Filter tabs ────────────────────────────────────
            if (_showResults) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = _activeFilter == _filters[i];
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _activeFilter = _filters[i]),
                      child: AnimatedContainer(
                        duration: DesignTokens.durationFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? DesignTokens.brand
                              : (isDark
                                  ? DesignTokens.darkCard
                                  : DesignTokens.lightSurface),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusFull),
                          border: Border.all(
                            color: active
                                ? DesignTokens.brand
                                : (isDark
                                    ? DesignTokens.darkBorder
                                    : DesignTokens.lightBorder),
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? Colors.white
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Body ───────────────────────────────────────────
            Expanded(
              child: _showResults
                  ? _ResultsList(query: _query, filter: _activeFilter)
                  : _SuggestionsView(
                      suggestions: _suggestions,
                      onSelect: (q) {
                        _controller.text = q;
                        _onSearch(q);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suggestions ──────────────────────────────────────────────────────────────

class _SuggestionsView extends StatelessWidget {
  final List<(String, IconData)> suggestions;
  final ValueChanged<String> onSelect;

  const _SuggestionsView({required this.suggestions, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: DesignTokens.brand),
              const SizedBox(width: 6),
              Text('Try asking',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: DesignTokens.brand)),
            ],
          ),
        ),
        ...suggestions.asMap().entries.map(
              (e) => _SuggestionTile(
                suggestion: e.value,
                index: e.key,
                onTap: () => onSelect(e.value.$1),
              ),
            ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final (String, IconData) suggestion;
  final int index;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightSurface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(suggestion.$2, size: 18, color: DesignTokens.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.$1,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(Icons.north_west_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (index * 40).ms, duration: 200.ms),
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final String query;
  final String filter;

  const _ResultsList({required this.query, required this.filter});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Text(
                'Results for "$query"',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '0 found',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: DesignTokens.brand),
              ),
            ],
          ),
        ),
        Expanded(
          child: EmptyStateWidget(
            icon: Icons.search_off_rounded,
            title: 'No files indexed yet',
            subtitle: 'Import and index files to enable search. Results will appear here.',
            actionLabel: 'Import Files',
            onAction: () => context.go('/'),
          ),
        ),
      ],
    );
  }
}
