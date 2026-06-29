import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/command_palette.dart';

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
      path: '/'),
  NavDestination(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
      path: '/search'),
  NavDestination(
      icon: Icons.auto_awesome_mosaic_outlined,
      activeIcon: Icons.auto_awesome_mosaic_rounded,
      label: 'Timeline',
      path: '/timeline'),
  NavDestination(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder_rounded,
      label: 'Collections',
      path: '/collections'),
  NavDestination(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'AI Chat',
      path: '/chat'),
  NavDestination(
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      label: 'Learning',
      path: '/learning'),
  NavDestination(
      icon: Icons.hub_outlined,
      activeIcon: Icons.hub_rounded,
      label: 'Galaxy',
      path: '/galaxy'),
  NavDestination(
      icon: Icons.inbox_outlined,
      activeIcon: Icons.inbox_rounded,
      label: 'Inbox',
      path: '/inbox'),
  NavDestination(
      icon: Icons.construction_outlined,
      activeIcon: Icons.construction_rounded,
      label: 'Toolbox',
      path: '/toolbox'),
  NavDestination(
      icon: Icons.storage_outlined,
      activeIcon: Icons.storage_rounded,
      label: 'Storage',
      path: '/duplicates'),
  NavDestination(
      icon: Icons.lock_outlined,
      activeIcon: Icons.lock_rounded,
      label: 'Vault',
      path: '/vault'),
  NavDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
      path: '/settings'),
];

/// Adaptive navigation shell wrapping all feature pages.
class ShellPage extends StatefulWidget {
  final Widget child;
  final String location;

  const ShellPage({super.key, required this.child, required this.location});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  bool _sidebarExpanded = true;

  int get _currentIndex {
    for (int i = 0; i < _destinations.length; i++) {
      final path = _destinations[i].path;
      if (path == '/' && widget.location == '/') return i;
      if (path != '/' && widget.location.startsWith(path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width >= 1200)
      return _DesktopShell(
          child: widget.child,
          location: widget.location,
          expanded: _sidebarExpanded,
          onToggle: () => setState(() => _sidebarExpanded = !_sidebarExpanded));
    if (size.width >= 700)
      return _TabletShell(child: widget.child, location: widget.location);
    return _MobileShell(
        child: widget.child,
        currentIndex: _currentIndex,
        location: widget.location);
  }
}

// ─── Desktop Shell ────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  final Widget child;
  final String location;
  final bool expanded;
  final VoidCallback onToggle;

  const _DesktopShell(
      {required this.child,
      required this.location,
      required this.expanded,
      required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg =
        isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface;
    final borderColor =
        isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder;
    final width = expanded ? 228.0 : 68.0;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          final isCtrl = HardwareKeyboard.instance.isControlPressed;
          final isMeta = HardwareKeyboard.instance.isMetaPressed;
          if ((isCtrl || isMeta) &&
              event.logicalKey == LogicalKeyboardKey.keyK) {
            CommandPalette.show(context);
          }
        }
      },
      child: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            width: width,
            decoration: BoxDecoration(
              color: sidebarBg,
              border: Border(right: BorderSide(color: borderColor)),
            ),
            child: Column(
              children: [
                // Brand header
                _SidebarHeader(expanded: expanded, onToggle: onToggle),
                const Divider(height: 1),

                // Nav items
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: _destinations
                          .map((d) => _SidebarItem(
                                dest: d,
                                expanded: expanded,
                                active: _isActive(d, location),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // Footer: storage mini-widget + settings
                _SidebarFooter(expanded: expanded, location: location),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: ClipRect(child: child),
          ),
        ],
      ),
    );
  }

  bool _isActive(NavDestination d, String loc) {
    if (d.path == '/') return loc == '/';
    return loc.startsWith(d.path);
  }
}

class _SidebarHeader extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _SidebarHeader({required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Brand icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [DesignTokens.brand, DesignTokens.accent],
                ),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.brand.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.memory_rounded,
                  color: Colors.white, size: 18),
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Memory',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                      ),
                      TextSpan(
                        text: 'OS',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: DesignTokens.brand,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
            IconButton(
              icon: Icon(
                expanded
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 20,
              ),
              onPressed: onToggle,
              tooltip: expanded ? 'Collapse sidebar' : 'Expand sidebar',
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final NavDestination dest;
  final bool expanded;
  final bool active;

  const _SidebarItem(
      {required this.dest, required this.expanded, required this.active});

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = DesignTokens.brand;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          GoRouter.of(context).go(widget.dest.path);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
              horizontal: widget.expanded ? 12 : 0, vertical: 10),
          decoration: BoxDecoration(
            color: widget.active
                ? activeColor.withOpacity(isDark ? 0.15 : 0.08)
                : _hovered
                    ? (isDark
                        ? Colors.white.withOpacity(0.04)
                        : Colors.black.withOpacity(0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: widget.active
                ? Border.all(color: activeColor.withOpacity(0.2))
                : null,
          ),
          child: Tooltip(
            message: widget.expanded ? '' : widget.dest.label,
            waitDuration: const Duration(milliseconds: 600),
            child: widget.expanded
                ? Row(children: [
                    Icon(
                      widget.active ? widget.dest.activeIcon : widget.dest.icon,
                      size: 20,
                      color: widget.active
                          ? activeColor
                          : isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.dest.label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight:
                              widget.active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                          color: widget.active
                              ? activeColor
                              : isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    if (widget.dest.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: DesignTokens.error,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(widget.dest.badge!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                      ),
                  ])
                : Center(
                    child: Icon(
                      widget.active ? widget.dest.activeIcon : widget.dest.icon,
                      size: 22,
                      color: widget.active
                          ? activeColor
                          : isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  final bool expanded;
  final String location;

  const _SidebarFooter({required this.expanded, required this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSettings = location.startsWith('/settings');

    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: isDark
                    ? DesignTokens.darkBorder
                    : DesignTokens.lightBorder)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        children: [
          // ⌘K command palette
          if (expanded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: InkWell(
                onTap: () => CommandPalette.show(context),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isDark ? DesignTokens.darkCard : DesignTokens.lightBg,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(
                        color: isDark
                            ? DesignTokens.darkBorder
                            : DesignTokens.lightBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal_rounded,
                          size: 14, color: DesignTokens.brand),
                      const SizedBox(width: 8),
                      Text('Commands',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B))),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: DesignTokens.brand.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('⌘K',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.brand)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Settings
          _SidebarItem(
            dest: _destinations.last,
            expanded: expanded,
            active: isSettings,
          ),
        ],
      ),
    );
  }
}

// ─── Tablet Shell ─────────────────────────────────────────────────────────────

class _TabletShell extends StatelessWidget {
  final Widget child;
  final String location;

  const _TabletShell({required this.child, required this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show only primary 5 destinations on rail
    final primary = _destinations.take(6).toList();
    int selected = 0;
    for (int i = 0; i < primary.length; i++) {
      final p = primary[i].path;
      if (p == '/' && location == '/') {
        selected = i;
        break;
      }
      if (p != '/' && location.startsWith(p)) {
        selected = i;
        break;
      }
    }

    return Row(
      children: [
        NavigationRail(
          selectedIndex: selected,
          onDestinationSelected: (i) {
            HapticFeedback.selectionClick();
            GoRouter.of(context).go(primary[i].path);
          },
          backgroundColor:
              isDark ? DesignTokens.darkSurface : DesignTokens.lightSurface,
          indicatorColor: DesignTokens.brand.withOpacity(isDark ? 0.15 : 0.08),
          selectedIconTheme:
              const IconThemeData(color: DesignTokens.brand, size: 22),
          unselectedIconTheme: IconThemeData(
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            size: 22,
          ),
          leading: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: InkWell(
              onTap: () => CommandPalette.show(context),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [DesignTokens.brand, DesignTokens.accent],
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.brand.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.memory_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ),
          destinations: primary
              .map((d) => NavigationRailDestination(
                    icon: Tooltip(
                      message: d.label,
                      child: Icon(d.icon),
                    ),
                    selectedIcon: Icon(d.activeIcon),
                    label: Text(d.label,
                        style:
                            const TextStyle(fontFamily: 'Inter', fontSize: 11)),
                  ))
              .toList(),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: ClipRect(child: child)),
      ],
    );
  }
}

// ─── Mobile Shell ─────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final String location;

  const _MobileShell(
      {required this.child,
      required this.currentIndex,
      required this.location});

  @override
  Widget build(BuildContext context) {
    // Show 5 primary destinations in mobile bottom nav
    final primary = _destinations.take(5).toList();
    int selected = 0;
    for (int i = 0; i < primary.length; i++) {
      final p = primary[i].path;
      if (p == '/' && location == '/') {
        selected = i;
        break;
      }
      if (p != '/' && location.startsWith(p)) {
        selected = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => CommandPalette.show(context),
        tooltip: 'Commands (⌘K)',
        backgroundColor: DesignTokens.brand,
        child:
            const Icon(Icons.terminal_rounded, color: Colors.white, size: 18),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) {
          HapticFeedback.selectionClick();
          GoRouter.of(context).go(primary[i].path);
        },
        indicatorColor: DesignTokens.brand.withOpacity(0.12),
        destinations: primary
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.activeIcon, color: DesignTokens.brand),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}
