import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          _SectionHeader('Indexing'),
          _SettingsTile(icon: Icons.folder_open, title: 'Watch Directories', subtitle: 'Add folders to monitor'),
          _SettingsTile(icon: Icons.text_fields, title: 'OCR Engine', subtitle: 'Tesseract (default)'),
          _SectionHeader('AI'),
          _SettingsTile(icon: Icons.memory, title: 'AI Models', subtitle: 'Download and manage models'),
          _SettingsTile(icon: Icons.tune, title: 'Inference Settings', subtitle: 'Temperature, threads, context'),
          _SectionHeader('Privacy & Security'),
          _SettingsTile(icon: Icons.lock, title: 'Secure Vault', subtitle: 'Configure encryption'),
          _SettingsTile(icon: Icons.fingerprint, title: 'Biometric Auth', subtitle: 'Enable biometric unlock'),
          _SectionHeader('Appearance'),
          _SettingsTile(icon: Icons.palette, title: 'Theme', subtitle: 'System default'),
          _SettingsTile(icon: Icons.language, title: 'Language', subtitle: 'English'),
          _SectionHeader('About'),
          _SettingsTile(icon: Icons.info_outline, title: 'Version', subtitle: '1.0.0'),
          _SettingsTile(icon: Icons.description_outlined, title: 'License', subtitle: 'Apache 2.0'),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SettingsTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () {},
    );
  }
}
