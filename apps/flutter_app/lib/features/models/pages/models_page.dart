import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// AI Models management page — download and activate local models.
class ModelsPage extends StatefulWidget {
  const ModelsPage({super.key});

  @override
  State<ModelsPage> createState() => _ModelsPageState();
}

class _ModelsPageState extends State<ModelsPage> {
  final Set<String> _downloading = {};
  String? _activeModelId;

  static const _models = [
    _ModelInfo(
      id: 'gemma2-2b',
      name: 'Gemma 2 2B Instruct',
      provider: 'Google',
      quantization: 'Q4_K_M',
      sizeGB: 1.6,
      contextLength: 8192,
      description: 'Excellent quality for its size. Great for summarization, Q&A, and chat.',
      badge: 'Recommended',
      badgeColor: Color(0xFF10B981),
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF6366F1),
    ),
    _ModelInfo(
      id: 'phi35-mini',
      name: 'Phi 3.5 Mini Instruct',
      provider: 'Microsoft',
      quantization: 'Q4_K_M',
      sizeGB: 2.2,
      contextLength: 128000,
      description: 'Long context window (128K). Best for analyzing long documents.',
      badge: 'Long Context',
      badgeColor: Color(0xFF3B82F6),
      icon: Icons.memory_rounded,
      color: Color(0xFF3B82F6),
    ),
    _ModelInfo(
      id: 'qwen25-1.5b',
      name: 'Qwen 2.5 1.5B Instruct',
      provider: 'Alibaba',
      quantization: 'Q4_K_M',
      sizeGB: 0.9,
      contextLength: 32768,
      description: 'Smallest and fastest. Ideal for quick categorization and tagging.',
      badge: 'Fastest',
      badgeColor: Color(0xFFF59E0B),
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
    _ModelInfo(
      id: 'llama32-3b',
      name: 'Llama 3.2 3B Instruct',
      provider: 'Meta',
      quantization: 'Q4_K_M',
      sizeGB: 2.0,
      contextLength: 131072,
      description: 'Balanced performance. Strong at reasoning and code explanation.',
      badge: null,
      badgeColor: Color(0xFF8B5CF6),
      icon: Icons.hub_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Models')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(),
        children: [
          // Privacy banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: DesignTokens.brand.withOpacity(0.06),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              border: Border.all(color: DesignTokens.brand.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded,
                    color: DesignTokens.brand, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '100% Local AI',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: DesignTokens.brand),
                      ),
                      Text(
                        'All models run entirely on your device. No data is sent to any server.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: DesignTokens.brand.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Text('Available Models',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),

          ..._models.asMap().entries.map(
                (e) => _ModelCard(
                  model: e.value,
                  isActive: _activeModelId == e.value.id,
                  isDownloading: _downloading.contains(e.value.id),
                  onDownload: () {
                    setState(() => _downloading.add(e.value.id));
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() {
                          _downloading.remove(e.value.id);
                          _activeModelId = e.value.id;
                        });
                      }
                    });
                  },
                  onActivate: () =>
                      setState(() => _activeModelId = e.value.id),
                )
                    .animate()
                    .fadeIn(delay: (e.key * 60).ms, duration: 250.ms)
                    .slideY(begin: 0.04, end: 0),
              ),
        ],
      ),
    );
  }
}

class _ModelInfo {
  final String id;
  final String name;
  final String provider;
  final String quantization;
  final double sizeGB;
  final int contextLength;
  final String description;
  final String? badge;
  final Color badgeColor;
  final IconData icon;
  final Color color;

  const _ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    required this.quantization,
    required this.sizeGB,
    required this.contextLength,
    required this.description,
    required this.badge,
    required this.badgeColor,
    required this.icon,
    required this.color,
  });

  String get formattedSize => '${sizeGB.toStringAsFixed(1)} GB';
  String get formattedContext {
    if (contextLength >= 1000) return '${(contextLength / 1000).toStringAsFixed(0)}K ctx';
    return '$contextLength ctx';
  }
}

class _ModelCard extends StatelessWidget {
  final _ModelInfo model;
  final bool isActive;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onActivate;

  const _ModelCard({
    required this.model,
    required this.isActive,
    required this.isDownloading,
    required this.onDownload,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInstalled = isActive; // simplified: active = installed

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        border: isActive
            ? Border.all(color: DesignTokens.brand, width: 2)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: model.color.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(model.icon, color: model.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              model.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (model.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: model.badgeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.radiusFull),
                              ),
                              child: Text(
                                model.badge!,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: model.badgeColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        model.provider,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              model.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(label: model.formattedSize, icon: Icons.storage_rounded),
                const SizedBox(width: 6),
                _InfoChip(label: model.quantization, icon: Icons.compress_rounded),
                const SizedBox(width: 6),
                _InfoChip(label: model.formattedContext, icon: Icons.wrap_text_rounded),
                const Spacer(),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.success.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusFull),
                      border: Border.all(
                          color: DesignTokens.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 12, color: DesignTokens.success),
                        const SizedBox(width: 4),
                        Text(
                          'Active',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.success,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isDownloading)
                  SizedBox(
                    width: 80,
                    child: LinearProgressIndicator(
                      color: DesignTokens.brand,
                      backgroundColor: DesignTokens.brand.withOpacity(0.1),
                    ),
                  )
                else
                  FilledButton.tonal(
                    onPressed: onDownload,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Download',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkOverlay : DesignTokens.lightBg,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
            color: isDark ? DesignTokens.darkBorder : DesignTokens.lightBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
