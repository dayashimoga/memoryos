import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Adaptive shell with sidebar (desktop) and bottom nav (mobile).
class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({super.key, required this.child});

  static const _navItems = [
    _NavItem(icon: Icons.home_outlined, label: 'Home', path: '/'),
    _NavItem(icon: Icons.search_outlined, label: 'Search', path: '/search'),
    _NavItem(icon: Icons.timeline_outlined, label: 'Timeline', path: '/timeline'),
    _NavItem(icon: Icons.folder_outlined, label: 'Collections', path: '/collections'),
    _NavItem(icon: Icons.chat_bubble_outline, label: 'AI Chat', path: '/chat'),
    _NavItem(icon: Icons.school_outlined, label: 'Learning', path: '/learning'),
    _NavItem(icon: Icons.lock_outline, label: 'Vault', path: '/vault'),
    _NavItem(icon: Icons.settings_outlined, label: 'Settings', path: '/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;
        final location = GoRouterState.of(context).matchedLocation;
        final selectedIndex = _selectedIndex(location);

        if (isWide) {
          return _WideLayout(
            child: child,
            navItems: _navItems,
            selectedIndex: selectedIndex,
          );
        } else {
          return _NarrowLayout(
            child: child,
            navItems: _navItems,
            selectedIndex: selectedIndex,
          );
        }
      },
    );
  }

  int _selectedIndex(String location) {
    for (int i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].path) &&
          (_navItems[i].path != '/' || location == '/')) {
        return i;
      }
      if (_navItems[i].path == '/' && location == '/') return i;
    }
    return 0;
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}

class _WideLayout extends StatelessWidget {
  final Widget child;
  final List<_NavItem> navItems;
  final int selectedIndex;

  const _WideLayout({
    required this.child,
    required this.navItems,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(navItems[i].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.memory, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MemoryOS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            destinations: navItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget child;
  final List<_NavItem> navItems;
  final int selectedIndex;

  const _NarrowLayout({
    required this.child,
    required this.navItems,
    required this.selectedIndex,
  });

  // Show only first 5 items in bottom nav for mobile
  static const _mobileItems = 5;

  @override
  Widget build(BuildContext context) {
    final mobileNavItems = navItems.take(_mobileItems).toList();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, _mobileItems - 1),
        onDestinationSelected: (i) => context.go(mobileNavItems[i].path),
        destinations: mobileNavItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}
