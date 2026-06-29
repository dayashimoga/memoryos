import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Natural language search page.
class SearchPage extends StatefulWidget {
  final String? initialQuery;

  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;
  String _query = '';
  bool _isSearching = false;
  String _selectedFilter = 'All';

  static const _filterChips = ['All', 'Images', 'Documents', 'Videos', 'Audio', 'Screenshots'];
  static const _suggestedQueries = [
    'Find AWS notes',
    'Show Kubernetes screenshots',
    'Invoice from last month',
    'Meeting recordings',
    'Chess opening theory',
    'Cloud security vulnerabilities',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery ?? '');
    _query = widget.initialQuery ?? '';
    if (_query.isNotEmpty) _performSearch(_query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    setState(() {
      _query = query;
      _isSearching = query.isNotEmpty;
    });
    // TODO: dispatch SearchBloc event
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Hero(
          tag: 'search_bar',
          child: Material(
            color: Colors.transparent,
            child: TextField(
              controller: _controller,
              autofocus: widget.initialQuery == null,
              decoration: InputDecoration(
                hintText: 'Search your memories...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onChanged: (val) => Future.delayed(
                const Duration(milliseconds: 300),
                () => _performSearch(val),
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: _query.isEmpty ? _buildSuggestionsView() : _buildResultsView(),
    );
  }

  Widget _buildSuggestionsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Try asking...',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ..._suggestedQueries.asMap().entries.map((e) => ListTile(
              leading: const Icon(Icons.history, size: 20),
              title: Text(e.value),
              onTap: () {
                _controller.text = e.value;
                _performSearch(e.value);
              },
            ).animate().fadeIn(delay: (e.key * 50).ms)),
      ],
    );
  }

  Widget _buildResultsView() {
    return Column(
      children: [
        // Filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: _filterChips
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f),
                        selected: _selectedFilter == f,
                        onSelected: (_) => setState(() => _selectedFilter = f),
                      ),
                    ))
                .toList(),
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 15,
            itemBuilder: (context, index) => _SearchResultCard(
              index: index,
              query: _query,
            ).animate().fadeIn(delay: (index * 30).ms).slideY(begin: 0.05, end: 0),
          ),
        ),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final int index;
  final String query;

  const _SearchResultCard({required this.index, required this.query});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.article_outlined, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Result file ${index + 1}.pdf',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '...contains information about "$query"...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: const Text('Document'),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '3 days ago',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
