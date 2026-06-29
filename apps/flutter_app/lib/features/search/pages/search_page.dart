import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/domain/repositories.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/command_palette.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Universal Search Page — wired to SearchBloc.
class SearchPage extends StatelessWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  Widget build(BuildContext context) {
    return _SearchView(initialQuery: initialQuery);
  }
}

class _SearchView extends StatefulWidget {
  final String? initialQuery;
  const _SearchView({this.initialQuery});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  String _activeFilter = 'All';
  String? _selectedColor;

  static const _filters = [
    'All',
    'Images',
    'Documents',
    'Videos',
    'Audio',
    'Archives',
    'Screenshots'
  ];
  static const _colorFilters = [
    ('#EF4444', 'Red'),
    ('#3B82F6', 'Blue'),
    ('#10B981', 'Green'),
    ('#F59E0B', 'Yellow'),
    ('#8B5CF6', 'Purple'),
    ('#EC4899', 'Pink'),
    ('#06B6D4', 'Cyan'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _focus = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        context
            .read<SearchBloc>()
            .add(SearchQueryChanged(widget.initialQuery!));
      } else {
        context.read<SearchBloc>().add(SearchHistoryRequested());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Search Header ──────────────────────────────────
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
                              : DesignTokens.lightBorder),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () {
                            context.read<SearchBloc>().add(SearchCleared());
                            context.pop();
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              hintText: 'Search files, content, ask AI...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintStyle: TextStyle(
                                color: isDark
                                    ? const Color(0xFF475569)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            onChanged: (v) => context
                                .read<SearchBloc>()
                                .add(SearchQueryChanged(v)),
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        BlocBuilder<SearchBloc, SearchState>(
                          builder: (context, state) {
                            if (state.query.isNotEmpty) {
                              return IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _controller.clear();
                                  context
                                      .read<SearchBloc>()
                                      .add(SearchCleared());
                                  _focus.requestFocus();
                                },
                              );
                            }
                            return IconButton(
                              icon: const Icon(Icons.mic_outlined),
                              onPressed: () {},
                              tooltip: 'Voice search',
                            );
                          },
                        ),
                        // Command palette icon
                        IconButton(
                          icon: const Icon(Icons.terminal_rounded),
                          onPressed: () => CommandPalette.show(context),
                          tooltip: 'Commands (⌘K)',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Active Filter Pills ──────────────────────────
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state.status == SearchStatus.idle && state.query.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final active = _activeFilter == _filters[i];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _activeFilter = _filters[i]);
                            context.read<SearchBloc>().add(SearchFilterChanged(
                                  typeFilter: _filters[i] == 'All'
                                      ? null
                                      : _filters[i].toLowerCase(),
                                ));
                          },
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
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
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
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w500,
                                color: active
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // ── Color Filters ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 28,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _colorFilters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final colorHex = _colorFilters[i].$1;
                    final colorName = _colorFilters[i].$2;
                    final colorVal =
                        Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
                    final active = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (active) {
                            _selectedColor = null;
                            _controller.clear();
                            context.read<SearchBloc>().add(SearchCleared());
                          } else {
                            _selectedColor = colorHex;
                            _controller.text = 'color:$colorName';
                            context
                                .read<SearchBloc>()
                                .add(SearchQueryChanged('color:$colorName'));
                          }
                        });
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: colorVal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: active
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black)
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            if (active)
                              BoxShadow(
                                color: colorVal.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                          ],
                        ),
                        child: active
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 8),

            // ── Body ────────────────────────────────────────
            Expanded(
              child: BlocBuilder<SearchBloc, SearchState>(
                builder: (context, state) {
                  return switch (state.status) {
                    SearchStatus.idle => _HistoryView(
                        history: state.history,
                        onSelect: (q) {
                          _controller.text = q;
                          context.read<SearchBloc>().add(SearchQueryChanged(q));
                        },
                      ),
                    SearchStatus.searching => const _SearchingIndicator(),
                    SearchStatus.loaded => state.hasResults
                        ? _ResultsView(result: state.result!)
                        : _NoResultsView(query: state.query),
                    SearchStatus.error => _ErrorView(error: state.error),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History ──────────────────────────────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  final List<String> history;
  final ValueChanged<String> onSelect;

  const _HistoryView({required this.history, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _SuggestionsView(onSelect: onSelect);
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.history_rounded,
                  size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text('Recent Searches',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: const Color(0xFF64748B))),
            ],
          ),
        ),
        ...history.map((q) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded,
                  size: 18, color: Color(0xFF64748B)),
              title: Text(q,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
              trailing: const Icon(Icons.north_west_rounded,
                  size: 14, color: Color(0xFF94A3B8)),
              onTap: () => onSelect(q),
            )),
      ],
    );
  }
}

class _SuggestionsView extends StatelessWidget {
  final ValueChanged<String> onSelect;
  static const _suggestions = [
    ('Find the AWS architecture diagram', Icons.cloud_rounded),
    ('Show screenshots from last week', Icons.screenshot_monitor_rounded),
    ('Kubernetes networking notes', Icons.notes_rounded),
    ('Invoices from 2024', Icons.receipt_rounded),
    ('Chess opening theory', Icons.sports_esports_rounded),
    ('Meeting recordings this month', Icons.mic_rounded),
    ('Large files over 100MB', Icons.folder_zip_rounded),
    ('PDF files with "security" in content', Icons.picture_as_pdf_rounded),
  ];

  const _SuggestionsView({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded,
                  size: 16, color: DesignTokens.brand),
              const SizedBox(width: 6),
              Text('Try asking',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: DesignTokens.brand)),
            ],
          ),
        ),
        ..._suggestions.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => onSelect(e.value.$1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? DesignTokens.darkCard
                          : DesignTokens.lightSurface,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                          color: isDark
                              ? DesignTokens.darkBorder
                              : DesignTokens.lightBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(e.value.$2, size: 18, color: DesignTokens.brand),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(e.value.$1,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ),
                        const Icon(Icons.north_west_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (e.key * 40).ms, duration: 200.ms),
              ),
            ),
      ],
    );
  }
}

// ─── Results ──────────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final SearchResult result;
  const _ResultsView({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Text(
                '${result.total} result${result.total != 1 ? 's' : ''} for "${result.query}"',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${result.elapsed.inMilliseconds}ms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DesignTokens.brand,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: result.hits.length,
            itemBuilder: (context, i) {
              final hit = result.hits[i];
              return _ResultTile(hit: hit, index: i);
            },
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final RankedFile hit;
  final int index;
  const _ResultTile({required this.hit, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        onTap: () => context.go('/file/${hit.file.id}'),
        child: Row(
          children: [
            FileTypeDisplay.iconBox(hit.file.extension, boxSize: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hit.file.filename,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (hit.matchSnippet != null) ...[
                    const SizedBox(height: 2),
                    Text(hit.matchSnippet!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _MatchBadge(hit.matchType),
                      const Spacer(),
                      Text(hit.file.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: (index * 30).ms, duration: 200.ms),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final SearchMatchType type;
  const _MatchBadge(this.type);

  String get _label {
    return switch (type) {
      SearchMatchType.filename => 'Filename',
      SearchMatchType.ocrText => 'OCR Text',
      SearchMatchType.summary => 'AI Summary',
      SearchMatchType.tag => 'Tag',
      SearchMatchType.metadata => 'Metadata',
    };
  }

  Color get _color {
    return switch (type) {
      SearchMatchType.filename => DesignTokens.brand,
      SearchMatchType.ocrText => DesignTokens.tertiary,
      SearchMatchType.summary => DesignTokens.accent,
      SearchMatchType.tag => DesignTokens.success,
      SearchMatchType.metadata => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(_label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _color,
          )),
    );
  }
}

class _SearchingIndicator extends StatelessWidget {
  const _SearchingIndicator();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: DesignTokens.brand,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          Text('Searching...',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  final String query;
  const _NoResultsView({required this.query});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      title: 'No results for "$query"',
      subtitle:
          'Try different keywords, or import and index files to enable search.',
      iconColor: DesignTokens.brand,
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String? error;
  const _ErrorView({this.error});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.error_outline_rounded,
      title: 'Search failed',
      subtitle: error ?? 'An unexpected error occurred. Please try again.',
      iconColor: DesignTokens.error,
    );
  }
}
