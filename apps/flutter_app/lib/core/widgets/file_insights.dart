import 'package:flutter/material.dart';
import 'package:memoryos/core/domain/entities.dart';
import 'package:memoryos/core/theme/app_theme.dart';

/// File Insights Card — AI-powered summary panel for file detail pages.
/// Shows AI summary, suggested tags, related files indicator, and OCR text.
/// Adapts to available data (hides sections when no AI model is loaded).
class FileInsightsCard extends StatelessWidget {
  final FileEntry file;
  final String? aiSummary;
  final List<String> suggestedTags;
  final int relatedFileCount;
  final bool isAiAvailable;
  final VoidCallback? onGenerateSummary;
  final ValueChanged<String>? onApplyTag;
  final VoidCallback? onViewRelated;

  const FileInsightsCard({
    super.key,
    required this.file,
    this.aiSummary,
    this.suggestedTags = const [],
    this.relatedFileCount = 0,
    this.isAiAvailable = false,
    this.onGenerateSummary,
    this.onApplyTag,
    this.onViewRelated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI Insights',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                if (!isAiAvailable)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                    ),
                    child: const Text(
                      'AI Offline',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Summary section
          if (aiSummary != null && aiSummary!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Summary'),
                  const SizedBox(height: 6),
                  Text(
                    aiSummary!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.5,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            )
          else if (isAiAvailable && onGenerateSummary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: OutlinedButton.icon(
                onPressed: onGenerateSummary,
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text('Generate AI Summary'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.brand,
                  side: BorderSide(
                    color: DesignTokens.brand.withOpacity(0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                ),
              ),
            ),

          // Suggested tags
          if (suggestedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Suggested Tags'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestedTags
                        .map((tag) => _TagChip(
                              tag: tag,
                              onTap: () => onApplyTag?.call(tag),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

          // OCR text preview
          if (file.ocrText != null && file.ocrText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: 'Extracted Text (OCR)'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.03)
                          : const Color(0xFFF8FAFC),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Text(
                      file.ocrText!.length > 200
                          ? '${file.ocrText!.substring(0, 200)}...'
                          : file.ocrText!,
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono, monospace',
                        fontSize: 11,
                        height: 1.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Related files
          if (relatedFileCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: InkWell(
                onTap: onViewRelated,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: DesignTokens.brand.withOpacity(isDark ? 0.08 : 0.05),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded,
                          size: 16, color: DesignTokens.brand),
                      const SizedBox(width: 8),
                      Text(
                        '$relatedFileCount related files found',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.brand,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: DesignTokens.brand),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onTap;

  const _TagChip({required this.tag, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: DesignTokens.brand.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
          border: Border.all(
            color: DesignTokens.brand.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 12, color: DesignTokens.brand),
            const SizedBox(width: 4),
            Text(
              tag,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: DesignTokens.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
