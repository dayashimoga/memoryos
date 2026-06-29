import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';
import 'package:memoryos/features/settings/bloc/settings_bloc.dart';

/// Settings page — full application configuration.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Profile card ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: _ProfileCard(),
          ),

          // ── Indexing ────────────────────────────────────
          const _SectionHeader('Indexing'),
          _SettingsTile(
            icon: Icons.folder_open_rounded,
            iconColor: DesignTokens.brand,
            title: 'Watch Directories',
            subtitle: 'No directories added',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.text_fields_rounded,
            iconColor: DesignTokens.tertiary,
            title: 'OCR Engine',
            subtitle: 'Tesseract (auto-detect language)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.schedule_rounded,
            iconColor: DesignTokens.accent,
            title: 'Index Schedule',
            subtitle: 'Manual only',
            onTap: () {},
          ),

          // ── AI ──────────────────────────────────────────
          const _SectionHeader('AI & Intelligence'),
          _SettingsTile(
            icon: Icons.memory_rounded,
            iconColor: DesignTokens.brand,
            title: 'AI Models',
            subtitle: 'No model active — tap to download',
            onTap: () => context.go('/models'),
            trailing: GradientBadge(label: 'Setup'),
          ),
          _SettingsTile(
            icon: Icons.tune_rounded,
            iconColor: DesignTokens.accent,
            title: 'Inference Settings',
            subtitle: 'CPU threads: auto · Temperature: 0.7',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.auto_awesome_rounded,
            iconColor: DesignTokens.tertiary,
            title: 'Auto-Categorization',
            subtitle: 'Enabled',
            onTap: () {},
          ),

          // ── Appearance ──────────────────────────────────
          const _SectionHeader('Appearance'),
          _ThemeSetting(),
          _SettingsTile(
            icon: Icons.text_increase_rounded,
            iconColor: const Color(0xFF64748B),
            title: 'Text Size',
            subtitle: 'Normal',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF64748B),
            title: 'Language',
            subtitle: 'English',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            iconColor: const Color(0xFF64748B),
            title: 'Thumbnail Quality',
            subtitle: 'High',
            onTap: () {},
          ),

          // ── Privacy & Security ──────────────────────────
          const _SectionHeader('Privacy & Security'),
          _SettingsTile(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFF64748B),
            title: 'Secure Vault',
            subtitle: 'AES-256-GCM encryption',
            onTap: () => context.go('/vault'),
          ),
          _SettingsTile(
            icon: Icons.fingerprint_rounded,
            iconColor: DesignTokens.success,
            title: 'Biometric Authentication',
            subtitle: 'Enabled',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: DesignTokens.error,
            title: 'Delete All Data',
            subtitle: 'Permanently remove all indexed data',
            onTap: () => _showDeleteDialog(context),
          ),

          // ── About ───────────────────────────────────────
          const _SectionHeader('About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF64748B),
            title: 'Version',
            subtitle: '1.1.0 (build 2)',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            iconColor: const Color(0xFF64748B),
            title: 'Open Source Licenses',
            subtitle: 'Apache 2.0',
            onTap: () {},
          ),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            iconColor: const Color(0xFF64748B),
            title: 'Report a Bug',
            subtitle: 'GitHub Issues',
            onTap: () {},
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        content: const Text(
          'This will permanently delete all indexed metadata, tags, collections, and vault data.\n\nYour original files will NOT be deleted.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: DesignTokens.error),
            child: const Text('Delete All'),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [DesignTokens.darkCard, DesignTokens.darkOverlay]
              : [DesignTokens.lightCard, DesignTokens.lightBg],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
          color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [DesignTokens.brand, DesignTokens.accent],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.memory_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MemoryOS',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Local · Private · Offline-first',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('v1.1.0',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: DesignTokens.brand,
                  )),
              Text('Apache 2.0',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Theme Setting ────────────────────────────────────────────────────────────

class _ThemeSetting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: const Icon(Icons.palette_rounded,
                color: Color(0xFF64748B), size: 18),
          ),
          title: const Text('Theme',
              style:
                  TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          subtitle: Text(_themeLabel(state.themeMode),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
          trailing: SegmentedButton<ThemeMode>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 14)),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 14)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 14)),
            ],
            selected: {state.themeMode},
            onSelectionChanged: (s) => context
                .read<SettingsBloc>()
                .add(SettingsThemeChanged(s.first)),
          ),
        );
      },
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 1.0,
          color: DesignTokens.brand,
        ),
      ),
    );
  }
}

// ─── Settings Tile ────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
      title: Text(title,
          style: const TextStyle(
              fontFamily: 'Inter', fontWeight: FontWeight.w500, fontSize: 14)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
