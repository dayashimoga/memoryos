import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';

/// Navigation destinations definition.
class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  final String? badge;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
    this.badge,
  });
}

const _destinations = [
  NavDestination(
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: 'Home',
    path: '/',
  ),
  NavDestination(
    icon: Icons.search_outlined,
    activeIcon: Icons.search_rounded,
    label: 'Search',
    path: '/search',
  ),
  NavDestination(
    icon: Icons.auto_awesome_mosaic_outlined,
    activeIcon: Icons.auto_awesome_mosaic_rounded,
    label: 'Timeline',
    path: '/timeline',
  ),
  NavDestination(
    icon: Icons.folder_outlined,
    activeIcon: Icons.folder_rounded,
    label: 'Collections',
    path: '/collections',
  ),
  NavDestination(
    icon: Icons.chat_bubble_outline_rounded,
    activeIcon: Icons.chat_bubble_rounded,
    label: 'AI Chat',
    path: '/chat',
  ),
  NavDestination(
    icon: Icons.school_outlined,
    activeIcon: Icons.school_rounded,
    label: 'Learning',
    path: '/learning',
  ),
  NavDestination(
    icon: Icons.lock_outline_rounded,
    activeIcon: Icons.lock_rounded,
    label: 'Vault',
    path: '/vault',
  ),
  NavDestination(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Settings',
    path: '/settings',
  ),
];

/// Adaptive shell — premium sidebar on desktop/tablet, polished bottom nav on mobile.
class ShellPage extends StatefulWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  bool _railExpanded = true;

  int _selectedIndex(String location) {
    for (int i = 0; i < _destinations.length; i++) {
      final path = _destinations[i].path;
      if (path == '/' && location == '/') return i;
      if (path != '/' && location.startsWith(path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Desktop: > 1200px (expanded sidebar)
        // Tablet: 700–1200px (compact rail)
        // Mobile: < 700px (bottom nav)
        if (width >= 1200) {
          return _DesktopShell(
            child: widget.child,
            selectedIndex: selectedIndex,
            expanded: _railExpanded,
            onToggleExpanded: () =>
                setState(() => _railExpanded = !_railExpanded),
          );
        } else if (width >= 700) {
          return _TabletShell(
            child: widget.child,
            selectedIndex: selectedIndex,
          );
        } else {
          return _MobileShell(
            child: widget.child,
            selectedIndex: selectedIndex,
          );
        }
      },
    );
  }
}

// ─── Desktop Shell ────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  const _DesktopShell({
    required this.child,
    required this.selectedIndex,
    required this.expanded,
    required this.onToggleExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: DesignTokens.durationNormal,
            curve: DesignTokens.curveSmooth,
            width: expanded ? 220 : 72,
            child: Container(
              color: sidebarBg,
              child: Column(
                children: [
                  // ── App branding ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        _BrandIcon(),
                        if (expanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedOpacity(
                              opacity: expanded ? 1 : 0,
                              duration: DesignTokens.durationFast,
                              child: Text(
                                'MemoryOS',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        IconButton(
                          icon: Icon(
                            expanded
                                ? Icons.menu_open_rounded
                                : Icons.menu_rounded,
                            size: 20,
                          ),
                          onPressed: onToggleExpanded,
                          tooltip:
                              expanded ? 'Collapse sidebar' : 'Expand sidebar',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Navigation items ─────────────────────────
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      itemCount: _destinations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 2),
                      itemBuilder: (context, i) {
                        final dest = _destinations[i];
                        final selected = selectedIndex == i;
                        return _SidebarItem(
                          destination: dest,
                          selected: selected,
                          expanded: expanded,
                          onTap: () => context.go(dest.path),
                        );
                      },
                    ),
                  ),

                  // ── Storage indicator ─────────────────────────
                  if (expanded)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: _StorageMiniWidget(),
                    ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Tablet Shell ─────────────────────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const _TabletShell({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 72,
            color: sidebarBg,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _BrandIcon(),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    itemCount: _destinations.length,
                    itemBuilder: (context, i) {
                      final dest = _destinations[i];
                      final selected = selectedIndex == i;
                      return Tooltip(
                        message: dest.label,
                        preferBelow: false,
                        child: _SidebarItem(
                          destination: dest,
                          selected: selected,
                          expanded: false,
                          onTap: () => context.go(dest.path),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ─── Mobile Shell ─────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  // Show only top 5 in bottom nav
  static const _mobileCount = 5;

  const _MobileShell({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final mobileDests = _destinations.take(_mobileCount).toList();
    final clampedIndex = selectedIndex.clamp(0, _mobileCount - 1);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.darkBorder
                  : DesignTokens.lightBorder,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: clampedIndex,
          height: 64,
          onDestinationSelected: (i) => context.go(mobileDests[i].path),
          destinations: mobileDests
              .asMap()
              .entries
              .map((e) => NavigationDestination(
                    icon: Icon(e.value.icon),
                    selectedIcon: Icon(e.value.activeIcon,
                        color: DesignTokens.brand),
                    label: e.value.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Sidebar Item ─────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  final NavDestination destination;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = widget.selected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor;
    if (selected) {
      bgColor = DesignTokens.brand.withOpacity(0.12);
    } else if (_hovered) {
      bgColor = isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04);
    } else {
      bgColor = Colors.transparent;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        margin: const EdgeInsets.symmetric(vertical: 1),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            child: AnimatedContainer(
              duration: DesignTokens.durationFast,
              padding: EdgeInsets.symmetric(
                horizontal: widget.expanded ? 12 : 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                mainAxisSize:
                    widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(
                    selected
                        ? widget.destination.activeIcon
                        : widget.destination.icon,
                    size: 20,
                    color: selected
                        ? DesignTokens.brand
                        : (isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B)),
                  ),
                  if (widget.expanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.destination.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontSize: 13,
                          color: selected
                              ? DesignTokens.brand
                              : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF475569)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.destination.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DesignTokens.brand,
                          borderRadius: BorderRadius.circular(
                              DesignTokens.radiusFull),
                        ),
                        child: Text(
                          widget.destination.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Brand Icon ───────────────────────────────────────────────────────────────

class _BrandIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DesignTokens.brand, DesignTokens.accent],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.brand.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.memory_rounded, color: Colors.white, size: 20),
    );
  }
}

// ─── Storage Mini Widget ──────────────────────────────────────────────────────

class _StorageMiniWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? DesignTokens.darkOverlay
            : DesignTokens.brand.withOpacity(0.06),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: isDark
              ? DesignTokens.darkBorder
              : DesignTokens.brand.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded,
                  size: 14, color: DesignTokens.brand),
              const SizedBox(width: 6),
              Text(
                'Storage',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.brand,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.0, // will be driven by StorageStats bloc
              backgroundColor:
                  DesignTokens.brand.withOpacity(0.1),
              color: DesignTokens.brand,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '0 files · 0 B',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: isDark
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
