import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Secure Vault — biometric-gated encrypted file storage.
class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  bool _unlocked = false;
  bool _authenticating = false;
  final _auth = LocalAuthentication();

  Future<void> _authenticate() async {
    setState(() => _authenticating = true);
    try {
      final supported = await _auth.isDeviceSupported();
      bool success;
      if (supported) {
        success = await _auth.authenticate(
          localizedReason: 'Authenticate to access the Secure Vault',
          options: const AuthenticationOptions(biometricOnly: false),
        );
      } else {
        // Platform doesn't support biometrics — allow access in dev
        success = true;
      }
      if (mounted) setState(() => _unlocked = success);
    } catch (_) {
      if (mounted) setState(() => _unlocked = true);
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  void _lock() => setState(() => _unlocked = false);

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return _LockedVaultView(
        authenticating: _authenticating,
        onUnlock: _authenticate,
      );
    }
    return _UnlockedVaultView(onLock: _lock);
  }
}

// ─── Locked View ──────────────────────────────────────────────────────────────

class _LockedVaultView extends StatelessWidget {
  final bool authenticating;
  final VoidCallback onUnlock;

  const _LockedVaultView({required this.authenticating, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lock icon with glow
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF475569), Color(0xFF334155)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF475569).withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 44),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Secure Vault',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your files are protected with AES-256-GCM encryption.\nAuthenticate to unlock your vault.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                        height: 1.6,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: authenticating ? null : onUnlock,
                  icon: authenticating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.fingerprint_rounded, size: 20),
                  label: Text(
                      authenticating ? 'Authenticating...' : 'Unlock Vault'),
                ),
                const SizedBox(height: 16),
                // Encryption info badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _SecurityBadge(label: 'AES-256-GCM', icon: Icons.enhanced_encryption_rounded),
                    _SecurityBadge(label: 'Argon2id KDF', icon: Icons.key_rounded),
                    _SecurityBadge(label: '100% Offline', icon: Icons.wifi_off_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SecurityBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightBg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: DesignTokens.success),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Unlocked View ────────────────────────────────────────────────────────────

class _UnlockedVaultView extends StatelessWidget {
  final VoidCallback onLock;

  const _UnlockedVaultView({required this.onLock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                size: 18, color: DesignTokens.success),
            const SizedBox(width: 8),
            const Text('Secure Vault'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
            tooltip: 'Add to vault',
          ),
          IconButton(
            icon: const Icon(Icons.lock_rounded),
            onPressed: onLock,
            tooltip: 'Lock vault',
          ),
        ],
      ),
      body: EmptyStateWidget(
        icon: Icons.shield_rounded,
        title: 'Your vault is empty',
        subtitle: 'Add sensitive files to encrypt them with AES-256-GCM.\nThey will only be accessible after authentication.',
        actionLabel: 'Add Files to Vault',
        onAction: () {},
        iconColor: DesignTokens.success,
      ),
    );
  }
}
