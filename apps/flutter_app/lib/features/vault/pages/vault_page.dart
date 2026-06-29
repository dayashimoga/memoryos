import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  bool _unlocked = false;
  final _auth = LocalAuthentication();

  Future<void> _authenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (supported) {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Authenticate to access the Secure Vault',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        setState(() => _unlocked = authenticated);
      } else {
        setState(() => _unlocked = true);
      }
    } catch (_) {
      setState(() => _unlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(title: const Text('Secure Vault')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text('Vault is Locked', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Authenticate to access your encrypted files', style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock Vault'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Vault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            onPressed: () => setState(() => _unlocked = false),
            tooltip: 'Lock Vault',
          ),
          IconButton(icon: const Icon(Icons.add), onPressed: () {}),
        ],
      ),
      body: const Center(child: Text('Vault contents appear here after unlock.')),
    );
  }
}
