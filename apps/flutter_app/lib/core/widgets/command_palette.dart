import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';

/// Universal Command Palette (⌘K / Ctrl+K).
///
/// Accessible from any screen. Supports navigation, file operations,
/// AI actions, and settings shortcuts.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key});

  /// Show the command palette as a modal overlay.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => const CommandPalette(),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  String _query = '';
  int _selectedIndex = 0;

  static const _allCommands = [
    _Command('Go to Home', Icons.home_rounded, '/'),
    _Command('Search Files', Icons.search_rounded, '/search'),
    _Command('AI Assistant', Icons.auto_awesome_rounded, '/chat'),
    _Command('Timeline', Icons.auto_awesome_mosaic_rounded, '/timeline'),
    _Command('Collections', Icons.folder_rounded, '/collections'),
    _Command('Memory Galaxy', Icons.hub_rounded, '/galaxy'),
    _Command('Smart Inbox', Icons.inbox_rounded, '/inbox'),
    _Command('Storage Optimizer', Icons.storage_rounded, '/duplicates'),
    _Command('Learning Mode', Icons.school_rounded, '/learning'),
    _Command('Secure Vault', Icons.lock_rounded, '/vault'),
    _Command('AI Models', Icons.memory_rounded, '/models'),
    _Command('Settings', Icons.settings_rounded, '/settings'),
    _Command('Import Files', Icons.add_rounded, null, category: 'Action'),
    _Command('Dark Mode', Icons.dark_mode_rounded, null, category: 'Action'),
    _Command('Light Mode', Icons.light_mode_rounded, null, category: 'Action'),
  ];

  List<_Command> get _filtered {
    if (_query.isEmpty) return _allCommands;
    final q = _query.toLowerCase();
    return _allCommands
        .where((c) => c.label.toLowerCase().contains(q))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text;
        _selectedIndex = 0;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _execute(_Command command) {
    Navigator.pop(context);
    if (command.path != null) {
      context.go(command.path!);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      final filtered = _filtered;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % filtered.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _selectedIndex =
            (_selectedIndex - 1 + filtered.length) % filtered.length);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter && filtered.isNotEmpty) {
        _execute(filtered[_selectedIndex]);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filtered;

    return Focus(
      onKeyEvent: _handleKey,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 480),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              border: Border.all(
                color:
                    isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
                  blurRadius: 48,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isDark
                            ? DesignTokens.darkBorder
                            : DesignTokens.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded,
                          color: DesignTokens.brand, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Type a command or search...',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? DesignTokens.darkCard
                              : DesignTokens.lightBg,
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        child: const Text('ESC',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B))),
                      ),
                    ],
                  ),
                ),

                // Results
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No commands found',
                        style: TextStyle(
                            fontFamily: 'Inter', color: Color(0xFF64748B))),
                  )
                else
                  Flexible(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final cmd = filtered[i];
                        final selected = i == _selectedIndex;
                        return _CommandRow(
                          command: cmd,
                          selected: selected,
                          onTap: () => _execute(cmd),
                        );
                      },
                    ),
                  ),

                // Footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? DesignTokens.darkBorder
                            : DesignTokens.lightBorder,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      _KeyHint(icon: Icons.keyboard_arrow_up_rounded),
                      _KeyHint(icon: Icons.keyboard_arrow_down_rounded),
                      Text('Navigate',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: const Color(0xFF64748B))),
                      const SizedBox(width: 16),
                      _KeyHint(label: '↵'),
                      Text('Open',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: const Color(0xFF64748B))),
                      const Spacer(),
                      Text('${filtered.length} commands',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 150.ms).scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 150.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  final _Command command;
  final bool selected;
  final VoidCallback onTap;

  const _CommandRow(
      {required this.command, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.brand.withOpacity(isDark ? 0.15 : 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: selected
              ? Border.all(color: DesignTokens.brand.withOpacity(0.2))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              command.icon,
              size: 18,
              color: selected ? DesignTokens.brand : const Color(0xFF64748B),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                command.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                  color: selected
                      ? DesignTokens.brand
                      : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF1E293B)),
                ),
              ),
            ),
            if (command.category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  command.category!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KeyHint extends StatelessWidget {
  final IconData? icon;
  final String? label;

  const _KeyHint({this.icon, this.label})
      : assert(icon != null || label != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF94A3B8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: icon != null
          ? Icon(icon, size: 12, color: const Color(0xFF64748B))
          : Text(label!,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 10, color: Color(0xFF64748B))),
    );
  }
}

class _Command {
  final String label;
  final IconData icon;
  final String? path;
  final String? category;

  const _Command(this.label, this.icon, this.path, {this.category});
}
