import 'package:flutter/material.dart';
import 'package:memoryos/core/theme/app_theme.dart';

// ─── Skeleton Loader ─────────────────────────────────────────────────────────

/// Animated shimmer skeleton for loading states.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.radius = DesignTokens.radiusSm,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? DesignTokens.darkCard : const Color(0xFFE2E8F0);
    final highlightColor =
        isDark ? DesignTokens.darkOverlay : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(widget.width == double.infinity
                  ? _animation.value - 2
                  : _animation.value),
              end: Alignment(widget.width == double.infinity
                  ? _animation.value
                  : _animation.value + 2),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton card for file list items.
class FileCardSkeleton extends StatelessWidget {
  const FileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.space8),
      padding: const EdgeInsets.all(DesignTokens.space12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? DesignTokens.darkBorder
              : DesignTokens.lightBorder,
        ),
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: DesignTokens.radiusMd),
          const SizedBox(width: DesignTokens.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 120, height: 12),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const SkeletonBox(width: 52, height: 20, radius: DesignTokens.radiusXs),
                    const SizedBox(width: 6),
                    const SkeletonBox(width: 52, height: 20, radius: DesignTokens.radiusXs),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton grid card for media thumbnails.
class MediaCardSkeleton extends StatelessWidget {
  const MediaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: const SkeletonBox(height: double.infinity),
    );
  }
}

// ─── Empty States ─────────────────────────────────────────────────────────────

/// Beautiful empty state widget with icon, title, subtitle, and optional CTA.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveColor = iconColor ?? colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: DesignTokens.durationSlow,
              curve: DesignTokens.curveSpring,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: effectiveColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: effectiveColor),
              ),
            ),
            const SizedBox(height: DesignTokens.space20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: DesignTokens.space24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Glass Surface ────────────────────────────────────────────────────────────

/// Premium glass/blur surface for overlays and floating panels.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 16,
    this.opacity = 0.1,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(DesignTokens.radiusLg);

    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(opacity),
          borderRadius: effectiveBorderRadius,
          border: Border.all(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}

// ─── File Type Icons ──────────────────────────────────────────────────────────

/// Returns appropriate icon and color for a given file extension.
class FileTypeDisplay {
  static const _extMap = <String, (IconData, Color)>{
    'jpg': (Icons.image_rounded, Color(0xFF6366F1)),
    'jpeg': (Icons.image_rounded, Color(0xFF6366F1)),
    'png': (Icons.image_rounded, Color(0xFF6366F1)),
    'gif': (Icons.gif_box_rounded, Color(0xFF8B5CF6)),
    'webp': (Icons.image_rounded, Color(0xFF6366F1)),
    'heic': (Icons.image_rounded, Color(0xFF6366F1)),
    'pdf': (Icons.picture_as_pdf_rounded, Color(0xFFEF4444)),
    'docx': (Icons.description_rounded, Color(0xFF3B82F6)),
    'doc': (Icons.description_rounded, Color(0xFF3B82F6)),
    'xlsx': (Icons.table_chart_rounded, Color(0xFF10B981)),
    'xls': (Icons.table_chart_rounded, Color(0xFF10B981)),
    'csv': (Icons.table_rows_rounded, Color(0xFF10B981)),
    'pptx': (Icons.slideshow_rounded, Color(0xFFFF7C00)),
    'mp4': (Icons.video_file_rounded, Color(0xFF8B5CF6)),
    'mkv': (Icons.video_file_rounded, Color(0xFF8B5CF6)),
    'mov': (Icons.video_file_rounded, Color(0xFF8B5CF6)),
    'mp3': (Icons.audio_file_rounded, Color(0xFF10B981)),
    'wav': (Icons.audio_file_rounded, Color(0xFF10B981)),
    'flac': (Icons.audio_file_rounded, Color(0xFF10B981)),
    'zip': (Icons.folder_zip_rounded, Color(0xFFF59E0B)),
    'tar': (Icons.folder_zip_rounded, Color(0xFFF59E0B)),
    '7z': (Icons.folder_zip_rounded, Color(0xFFF59E0B)),
    'md': (Icons.article_rounded, Color(0xFF64748B)),
    'txt': (Icons.text_snippet_rounded, Color(0xFF64748B)),
    'html': (Icons.code_rounded, Color(0xFFFF7C00)),
    'json': (Icons.data_object_rounded, Color(0xFF06B6D4)),
    'dart': (Icons.code_rounded, Color(0xFF3B82F6)),
    'rs': (Icons.terminal_rounded, Color(0xFFEF4444)),
    'py': (Icons.code_rounded, Color(0xFF10B981)),
    'js': (Icons.javascript_rounded, Color(0xFFF59E0B)),
    'ts': (Icons.code_rounded, Color(0xFF3B82F6)),
  };

  static IconData icon(String extension) =>
      _extMap[extension.toLowerCase()]?.$1 ?? Icons.insert_drive_file_rounded;

  static Color color(String extension) =>
      _extMap[extension.toLowerCase()]?.$2 ?? const Color(0xFF94A3B8);

  static Widget iconWidget(String extension, {double size = 24}) {
    return Icon(icon(extension), color: color(extension), size: size);
  }

  static Widget iconBox(String extension, {double boxSize = 44}) {
    final clr = color(extension);
    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: clr.withOpacity(0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Icon(icon(extension), color: clr, size: boxSize * 0.45),
    );
  }
}

// ─── Premium Card Shell ────────────────────────────────────────────────────────

/// A tappable card that provides hover/press feedback.
class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? border;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.backgroundColor,
    this.borderRadius,
    this.border,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBg = widget.backgroundColor ??
        (isDark ? DesignTokens.darkCard : DesignTokens.lightCard);
    final effectiveBorder = widget.border ??
        Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder);
    final effectiveRadius =
        widget.borderRadius ?? BorderRadius.circular(DesignTokens.radiusLg);

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        onLongPress: widget.onLongPress,
        child: Container(
          padding: widget.padding ?? const EdgeInsets.all(DesignTokens.space12),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: effectiveRadius,
            border: effectiveBorder,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Gradient Badge ───────────────────────────────────────────────────────────

class GradientBadge extends StatelessWidget {
  final String label;
  final List<Color>? colors;

  const GradientBadge({super.key, required this.label, this.colors});

  @override
  Widget build(BuildContext context) {
    final effectiveColors = colors ??
        [DesignTokens.brand, DesignTokens.accent];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: effectiveColors),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space16, vertical: DesignTokens.space8),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (trailing != null) trailing!,
          if (action != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: Text(action!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  )),
            ),
        ],
      ),
    );
  }
}
