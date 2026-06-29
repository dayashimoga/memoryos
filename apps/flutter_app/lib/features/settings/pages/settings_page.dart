import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/blocs/app_blocs.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

/// Settings page — wired to SettingsBloc, StorageBloc, AiBloc.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Profile card
          _ProfileCard().animate().fadeIn(duration: 250.ms),

          _Section('Appearance', [
            _ThemeSetting(),
          ]),

          _Section('AI & Models', [
            _AiStatusTile(),
            _NavTile(
              icon: Icons.memory_rounded,
              label: 'Manage AI Models',
              subtitle: 'Download, update or remove models',
              onTap: () => context.go('/models'),
            ),
          ]),

          _Section('Storage & Library', [
            _StorageStatsTile(),
            _NavTile(
              icon: Icons.storage_rounded,
              label: 'Storage Optimizer',
              subtitle: 'Find duplicates and free up space',
              onTap: () => context.go('/duplicates'),
            ),
            _NavTile(
              icon: Icons.folder_rounded,
              label: 'Collections',
              subtitle: 'Manage smart and manual collections',
              onTap: () => context.go('/collections'),
            ),
          ]),

          _Section('Privacy & Security', [
            _NavTile(
              icon: Icons.lock_rounded,
              label: 'Secure Vault',
              subtitle: 'AES-256 encrypted file storage',
              onTap: () => context.go('/vault'),
              badge: 'AES-256',
            ),
            _SwitchTile(
              icon: Icons.analytics_outlined,
              label: 'Crash reporting',
              subtitle: 'Anonymous crash reports (local only)',
              value: false,
              onChanged: (_) {},
            ),
          ]),

          _Section('About', [
            _InfoTile(
                icon: Icons.info_rounded, label: 'Version', value: 'v1.2.0'),
            _InfoTile(
                icon: Icons.memory_rounded,
                label: 'Engine',
                value: 'Rust core-engine'),
            _NavTile(
              icon: Icons.article_rounded,
              label: 'Acknowledgements',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  DesignTokens.brand.withOpacity(0.18),
                  DesignTokens.accent.withOpacity(0.1)
                ]
              : [
                  DesignTokens.brand.withOpacity(0.07),
                  DesignTokens.accent.withOpacity(0.04)
                ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
            color: DesignTokens.brand.withOpacity(isDark ? 0.2 : 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [DesignTokens.brand, DesignTokens.accent]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: DesignTokens.brand.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MemoryOS User',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text('All data stored locally · 100% private',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: const Color(0xFF64748B))),
              ],
            ),
          ),
          GradientBadge(label: 'Offline'),
        ],
      ),
    );
  }
}

// ─── Section ──────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

// ─── Theme Setting ────────────────────────────────────────────────────────────

class _ThemeSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(
                color: isDark
                    ? DesignTokens.darkBorder
                    : DesignTokens.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: DesignTokens.brand.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                    child: const Icon(Icons.palette_rounded,
                        color: DesignTokens.brand, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text('Choose light, dark, or system',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SegmentedButton<ThemeMode>(
                selected: {state.themeMode},
                onSelectionChanged: (modes) {
                  HapticFeedback.selectionClick();
                  context
                      .read<SettingsBloc>()
                      .add(SettingsThemeChanged(modes.first));
                },
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode_rounded, size: 16),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto_rounded, size: 16),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode_rounded, size: 16),
                    label: Text('Dark'),
                  ),
                ],
                style: ButtonStyle(
                  textStyle: const MaterialStatePropertyAll(
                    TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── AI Status Tile ───────────────────────────────────────────────────────────

class _AiStatusTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        return _InfoTile(
          icon: state.modelLoaded
              ? Icons.check_circle_rounded
              : Icons.error_outline_rounded,
          label: 'AI Model',
          value: state.modelLoaded ? 'Model active' : 'No model loaded',
          iconColor:
              state.modelLoaded ? DesignTokens.success : DesignTokens.warning,
        );
      },
    );
  }
}

// ─── Storage Stats Tile ───────────────────────────────────────────────────────

class _StorageStatsTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return _InfoTile(
          icon: Icons.inventory_2_rounded,
          label: 'Indexed Files',
          value:
              '${state.stats.totalFiles} files · ${state.stats.formattedTotal}',
        );
      },
    );
  }
}

// ─── Reusable tile widgets ────────────────────────────────────────────────────

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final String? badge;

  const _NavTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DesignTokens.brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Icon(icon, color: DesignTokens.brand, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12))
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DesignTokens.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.success)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: DesignTokens.brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Icon(icon, color: DesignTokens.brand, size: 18),
        ),
        title: Text(label,
            style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(subtitle,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
        value: value,
        onChanged: (v) {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
        activeColor: DesignTokens.brand,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg)),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ?? DesignTokens.brand;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
