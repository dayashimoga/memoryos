import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Storage Optimization — duplicate detection, cleanup, storage heatmap.
class DuplicatesPage extends StatefulWidget {
  const DuplicatesPage({super.key});

  @override
  State<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends State<DuplicatesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _startScan() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Optimizer'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Duplicates'),
            Tab(text: 'Blurry'),
            Tab(text: 'Large Files'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _OverviewTab(scanning: _scanning, onScan: _startScan),
          _DuplicatesTab(),
          _BlurryTab(),
          _LargeFilesTab(),
        ],
      ),
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final bool scanning;
  final VoidCallback onScan;

  const _OverviewTab({required this.scanning, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  DesignTokens.success.withOpacity(isDark ? 0.15 : 0.06),
                  DesignTokens.tertiary.withOpacity(isDark ? 0.08 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                color: DesignTokens.success.withOpacity(isDark ? 0.2 : 0.12),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0 B',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        color: DesignTokens.success,
                      ),
                    ),
                    const Text(
                      'Recoverable storage',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: scanning ? null : onScan,
                  icon: scanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, size: 16),
                  label: Text(scanning ? 'Scanning...' : 'Scan Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Issue Categories',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _IssueCard(
            icon: Icons.content_copy_rounded,
            color: DesignTokens.warning,
            title: 'Exact Duplicates',
            subtitle: '0 files — 0 B recoverable',
            onFix: () {},
          ),
          const SizedBox(height: 8),
          _IssueCard(
            icon: Icons.blur_on_rounded,
            color: DesignTokens.error,
            title: 'Blurry Images',
            subtitle: '0 images detected',
            onFix: () {},
          ),
          const SizedBox(height: 8),
          _IssueCard(
            icon: Icons.screenshot_monitor_rounded,
            color: DesignTokens.accent,
            title: 'Empty Screenshots',
            subtitle: '0 screenshots are mostly blank',
            onFix: () {},
          ),
          const SizedBox(height: 8),
          _IssueCard(
            icon: Icons.folder_zip_rounded,
            color: DesignTokens.brand,
            title: 'Large Files',
            subtitle: '0 files over 100 MB',
            onFix: () {},
          ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onFix;

  const _IssueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: onFix,
            child: const Text('Review',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DuplicatesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.content_copy_outlined,
      title: 'No duplicates found',
      subtitle: 'Run a scan to detect exact and near-duplicate files.',
      iconColor: DesignTokens.warning,
    );
  }
}

class _BlurryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.blur_on_outlined,
      title: 'No blurry images',
      subtitle: 'Scan your library to detect low-quality or blurry images.',
      iconColor: DesignTokens.error,
    );
  }
}

class _LargeFilesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.folder_zip_outlined,
      title: 'No large files detected',
      subtitle: 'Large files (>100 MB) will be listed here after a scan.',
      iconColor: DesignTokens.brand,
    );
  }
}
