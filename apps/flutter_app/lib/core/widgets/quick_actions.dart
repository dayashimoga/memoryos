import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoryos/core/theme/app_theme.dart';

/// Context-aware quick actions FAB with expandable radial menu.
/// Provides one-tap access to common operations: Import, Scan, Capture, Search.
/// Adapts to platform: shows camera/scan on mobile, import/paste on desktop.
class QuickActionsButton extends StatefulWidget {
  final VoidCallback? onImportFile;
  final VoidCallback? onScanDocument;
  final VoidCallback? onCaptureScreen;
  final VoidCallback? onQuickSearch;
  final VoidCallback? onCreateCollection;
  final VoidCallback? onBackupNow;

  const QuickActionsButton({
    super.key,
    this.onImportFile,
    this.onScanDocument,
    this.onCaptureScreen,
    this.onQuickSearch,
    this.onCreateCollection,
    this.onBackupNow,
  });

  @override
  State<QuickActionsButton> createState() => _QuickActionsButtonState();
}

class _QuickActionsButtonState extends State<QuickActionsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  List<_QuickAction> get _actions {
    final isMobile = _isMobilePlatform;
    return [
      _QuickAction(
        icon: Icons.file_upload_outlined,
        label: 'Import File',
        color: const Color(0xFF3B82F6),
        onTap: widget.onImportFile,
      ),
      if (isMobile)
        _QuickAction(
          icon: Icons.document_scanner_outlined,
          label: 'Scan Document',
          color: const Color(0xFF10B981),
          onTap: widget.onScanDocument,
        ),
      if (isMobile)
        _QuickAction(
          icon: Icons.camera_alt_outlined,
          label: 'Capture Screen',
          color: const Color(0xFF8B5CF6),
          onTap: widget.onCaptureScreen,
        ),
      if (!isMobile)
        _QuickAction(
          icon: Icons.content_paste_rounded,
          label: 'Paste from Clipboard',
          color: const Color(0xFF10B981),
          onTap: widget.onCaptureScreen,
        ),
      _QuickAction(
        icon: Icons.search_rounded,
        label: 'Quick Search',
        color: const Color(0xFFF59E0B),
        onTap: widget.onQuickSearch,
      ),
      _QuickAction(
        icon: Icons.create_new_folder_outlined,
        label: 'New Collection',
        color: const Color(0xFFEC4899),
        onTap: widget.onCreateCollection,
      ),
      _QuickAction(
        icon: Icons.backup_outlined,
        label: 'Backup Now',
        color: const Color(0xFF6366F1),
        onTap: widget.onBackupNow,
      ),
    ];
  }

  bool get _isMobilePlatform {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = _actions;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expandable action items
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(actions.length, (index) {
                final action = actions[index];
                final delay = index / actions.length;
                final animation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
                );

                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _QuickActionChip(
                        action: action,
                        onTap: () {
                          _toggle();
                          action.onTap?.call();
                        },
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),

        // Main FAB
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: DesignTokens.brand,
          elevation: _isOpen ? 12 : 6,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 280),
            child: Icon(
              _isOpen ? Icons.close_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class _QuickActionChip extends StatelessWidget {
  final _QuickAction action;
  final VoidCallback? onTap;

  const _QuickActionChip({required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? DesignTokens.darkCard
                : Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            border: Border.all(
              color: isDark
                  ? DesignTokens.darkBorder
                  : DesignTokens.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: action.color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(action.icon, size: 16, color: action.color),
              ),
              const SizedBox(width: 10),
              Text(
                action.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
