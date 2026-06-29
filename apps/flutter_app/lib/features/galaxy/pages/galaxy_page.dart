import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:memoryos/core/theme/app_theme.dart';
import 'package:memoryos/core/widgets/shared_widgets.dart';

/// Interactive Memory Galaxy — animated knowledge graph.
///
/// Uses a Canvas-based radial graph. Real graph data flows from FileRepository
/// once the FFI layer is wired. The visual engine is fully functional.
class GalaxyPage extends StatefulWidget {
  const GalaxyPage({super.key});

  @override
  State<GalaxyPage> createState() => _GalaxyPageState();
}

class _GalaxyPageState extends State<GalaxyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  _GalaxyNode? _selected;
  double _zoom = 1.0;
  Offset _pan = Offset.zero;
  Offset _lastFocalPoint = Offset.zero;

  // Demo nodes (real data will come from FileRepository.getKnowledgeGraph)
  late final List<_GalaxyNode> _nodes;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _nodes = _buildDemoGraph();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    // 1. Repulsion between all nodes
    for (int i = 0; i < _nodes.length; i++) {
      for (int j = i + 1; j < _nodes.length; j++) {
        final n1 = _nodes[i];
        final n2 = _nodes[j];
        final dx = n2.x - n1.x;
        final dy = n2.y - n1.y;
        final distSq = dx * dx + dy * dy + 0.1;
        final dist = math.sqrt(distSq);
        if (dist < 260) {
          final force = 180.0 / distSq;
          final fx = (dx / dist) * force;
          final fy = (dy / dist) * force;
          n1.vx -= fx;
          n1.vy -= fy;
          n2.vx += fx;
          n2.vy += fy;
        }
      }
    }

    // 2. Attraction to parent/root
    for (final n in _nodes) {
      if (n.parentId != null) {
        final parent = _nodes.firstWhere((p) => p.id == n.parentId,
            orElse: () => _nodes.firstWhere((p) => p.id == 'root'));
        final dx = parent.x - n.x;
        final dy = parent.y - n.y;
        final dist = math.sqrt(dx * dx + dy * dy + 0.1);
        final restLen = 120.0;
        final force = (dist - restLen) * 0.05;
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;
        n.vx += fx;
        n.vy += fy;
        parent.vx -= fx;
        parent.vy -= fy;
      } else if (!n.isCenter) {
        final root = _nodes.firstWhere((p) => p.id == 'root');
        final dx = root.x - n.x;
        final dy = root.y - n.y;
        final dist = math.sqrt(dx * dx + dy * dy + 0.1);
        final restLen = 160.0;
        final force = (dist - restLen) * 0.03;
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;
        n.vx += fx;
        n.vy += fy;
      }
    }

    // 3. Update positions with dampening
    setState(() {
      for (final n in _nodes) {
        if (n.isCenter) continue;
        n.x += n.vx;
        n.y += n.vy;
        n.vx *= 0.82;
        n.vy *= 0.82;
      }
    });
  }

  static List<_GalaxyNode> _buildDemoGraph() {
    const cx = 0.0;
    const cy = 0.0;
    final center = _GalaxyNode(
      id: 'root',
      label: 'Your Memory',
      icon: Icons.memory_rounded,
      color: DesignTokens.brand,
      x: cx,
      y: cy,
      radius: 32,
      isCenter: true,
    );

    const orbits = [
      ('cloud', 'Cloud', Icons.cloud_rounded, Color(0xFF0EA5E9), 160.0, 0.0),
      (
        'security',
        'Security',
        Icons.security_rounded,
        Color(0xFFEF4444),
        113.0,
        113.0
      ),
      (
        'finance',
        'Finance',
        Icons.attach_money_rounded,
        Color(0xFF10B981),
        0.0,
        160.0
      ),
      (
        'learning',
        'Learning',
        Icons.school_rounded,
        Color(0xFF6366F1),
        -113.0,
        113.0
      ),
      (
        'chess',
        'Chess',
        Icons.sports_esports_rounded,
        Color(0xFF8B5CF6),
        -160.0,
        0.0
      ),
      (
        'travel',
        'Travel',
        Icons.flight_rounded,
        Color(0xFF0891B2),
        -113.0,
        -113.0
      ),
      (
        'screenshots',
        'Screenshots',
        Icons.screenshot_monitor_rounded,
        Color(0xFF64748B),
        0.0,
        -160.0
      ),
      (
        'medical',
        'Medical',
        Icons.local_hospital_rounded,
        Color(0xFFDC2626),
        113.0,
        -113.0
      ),
    ];

    final nodes = <_GalaxyNode>[center];
    for (final o in orbits) {
      nodes.add(_GalaxyNode(
        id: o.$1,
        label: o.$2,
        icon: o.$3,
        color: o.$4,
        x: cx + o.$5,
        y: cy + o.$6,
        radius: 22,
      ));
    }

    // Outer ring (smaller)
    const outer = [
      ('docker', 'Docker', Icons.dns_rounded, Color(0xFF0EA5E9), 260.0, 0.0),
      (
        'kubernetes',
        'K8s',
        Icons.settings_input_component_rounded,
        Color(0xFF3B82F6),
        184.0,
        184.0
      ),
      (
        'terraform',
        'Terraform',
        Icons.architecture_rounded,
        Color(0xFF7C3AED),
        0.0,
        260.0
      ),
      (
        'openings',
        'Openings',
        Icons.sports_esports_rounded,
        Color(0xFF8B5CF6),
        -260.0,
        0.0
      ),
      (
        'tactics',
        'Tactics',
        Icons.sports_esports_rounded,
        Color(0xFFA78BFA),
        -184.0,
        -184.0
      ),
    ];
    for (final o in outer) {
      nodes.add(_GalaxyNode(
        id: o.$1,
        label: o.$2,
        icon: o.$3,
        color: o.$4,
        x: cx + o.$5,
        y: cy + o.$6,
        radius: 16,
        parentId: o.$1.contains('docker') ||
                o.$1.contains('kubernetes') ||
                o.$1.contains('terraform')
            ? 'cloud'
            : 'chess',
      ));
    }

    return nodes;
  }

  _GalaxyNode? _hitTest(Offset local, Size size) {
    final cx = size.width / 2 + _pan.dx;
    final cy = size.height / 2 + _pan.dy;
    for (final node in _nodes) {
      final nx = cx + node.x * _zoom;
      final ny = cy + node.y * _zoom;
      final dx = local.dx - nx;
      final dy = local.dy - ny;
      if (dx * dx + dy * dy <=
          (node.radius * _zoom + 12) * (node.radius * _zoom + 12)) {
        return node;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Galaxy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () =>
                setState(() => _zoom = (_zoom + 0.2).clamp(0.3, 3.0)),
            tooltip: 'Zoom in',
          ),
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: () =>
                setState(() => _zoom = (_zoom - 0.2).clamp(0.3, 3.0)),
            tooltip: 'Zoom out',
          ),
          IconButton(
            icon: const Icon(Icons.center_focus_strong_rounded),
            onPressed: () => setState(() {
              _zoom = 1;
              _pan = Offset.zero;
            }),
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Graph canvas
          GestureDetector(
            onTapUp: (details) {
              final size = context.size!;
              final hit = _hitTest(details.localPosition, size);
              setState(() => _selected = hit);
            },
            onScaleStart: (details) => _lastFocalPoint = details.focalPoint,
            onScaleUpdate: (details) {
              setState(() {
                if (details.scale != 1.0) {
                  _zoom = (_zoom * details.scale).clamp(0.3, 3.0);
                }
                final delta = details.focalPoint - _lastFocalPoint;
                _pan += delta;
                _lastFocalPoint = details.focalPoint;
              });
            },
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _GalaxyPainter(
                  nodes: _nodes,
                  selectedId: _selected?.id,
                  pulse: _pulse.value,
                  zoom: _zoom,
                  pan: _pan,
                  isDark: isDark,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),

          // Zoom indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? DesignTokens.darkCard : DesignTokens.lightCard)
                    .withOpacity(0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder),
              ),
              child: Text('${(_zoom * 100).round()}%',
                  style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: DesignTokens.brand)),
            ),
          ),

          // Node info panel
          if (_selected != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _NodeInfoPanel(
                node: _selected!,
                onClose: () => setState(() => _selected = null),
                onExplore: () => context.go('/search?q=${_selected!.label}'),
              ).animate().fadeIn(duration: 150.ms).slideY(begin: 0.1, end: 0),
            ),

          // Legend
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? DesignTokens.darkCard : DesignTokens.lightCard)
                    .withOpacity(0.9),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                border: Border.all(
                    color: isDark
                        ? DesignTokens.darkBorder
                        : DesignTokens.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Knowledge Graph',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  _LegendRow(color: DesignTokens.brand, label: 'Core Memory'),
                  _LegendRow(color: const Color(0xFF0EA5E9), label: 'Topics'),
                  _LegendRow(
                      color: const Color(0xFF64748B), label: 'Sub-topics'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}

class _NodeInfoPanel extends StatelessWidget {
  final _GalaxyNode node;
  final VoidCallback onClose;
  final VoidCallback onExplore;

  const _NodeInfoPanel(
      {required this.node, required this.onClose, required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? DesignTokens.darkCard : DesignTokens.lightCard,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(color: node.color.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: node.color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: node.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            child: Icon(node.icon, color: node.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('${node.id} cluster — tap to explore',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          FilledButton.tonal(
            onPressed: onExplore,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Explore',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

// ─── Data model ───────────────────────────────────────────────────────────────

class _GalaxyNode {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  double x;
  double y;
  double vx = 0.0;
  double vy = 0.0;
  final double radius;
  final bool isCenter;
  final String? parentId;

  _GalaxyNode({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.radius,
    this.isCenter = false,
    this.parentId,
  });
}

// ─── Canvas painter ───────────────────────────────────────────────────────────

class _GalaxyPainter extends CustomPainter {
  final List<_GalaxyNode> nodes;
  final String? selectedId;
  final double pulse;
  final double zoom;
  final Offset pan;
  final bool isDark;

  const _GalaxyPainter({
    required this.nodes,
    required this.selectedId,
    required this.pulse,
    required this.zoom,
    required this.pan,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + pan.dx;
    final cy = size.height / 2 + pan.dy;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF8FAFF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw star field (static)
    final starPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06);
    for (int i = 0; i < 80; i++) {
      final sx = (i * 47.3 + 13.7) % size.width;
      final sy = (i * 83.1 + 29.3) % size.height;
      canvas.drawCircle(Offset(sx, sy), 0.8 + (i % 3) * 0.4, starPaint);
    }

    // Map: parentId → node positions
    final nodePos = <String, Offset>{};
    for (final n in nodes) {
      nodePos[n.id] = Offset(cx + n.x * zoom, cy + n.y * zoom);
    }

    // Draw edges
    for (final node in nodes) {
      if (node.parentId != null && nodePos.containsKey(node.parentId)) {
        final from = nodePos['root']!;
        final to = nodePos[node.id]!;
        final edgePaint = Paint()
          ..color = node.color.withOpacity(0.15)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(from, to, edgePaint);
      } else if (!node.isCenter) {
        final from = nodePos['root']!;
        final to = nodePos[node.id]!;
        final edgePaint = Paint()
          ..color = node.color.withOpacity(0.2)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(from, to, edgePaint);
      }
    }

    // Draw nodes
    for (final node in nodes) {
      final pos = nodePos[node.id]!;
      final r = node.radius * zoom;
      final isSelected = node.id == selectedId;

      // Glow (pulsing for center, static for others)
      final glowRadius = node.isCenter ? r + 20 + pulse * 12 : r + 10;
      final glowPaint = Paint()
        ..color =
            node.color.withOpacity(node.isCenter ? 0.15 + pulse * 0.1 : 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
      canvas.drawCircle(pos, glowRadius, glowPaint);

      // Selection ring
      if (isSelected) {
        final ringPaint = Paint()
          ..color = node.color.withOpacity(0.6)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(pos, r + 8, ringPaint);
      }

      // Node background
      final fillPaint = Paint()
        ..color = isDark
            ? Color.lerp(const Color(0xFF0F172A), node.color, 0.25)!
            : Color.lerp(Colors.white, node.color, 0.15)!;
      canvas.drawCircle(pos, r, fillPaint);

      // Node border
      final borderPaint = Paint()
        ..color = node.color.withOpacity(isSelected ? 0.8 : 0.4)
        ..strokeWidth = isSelected ? 2.5 : 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(pos, r, borderPaint);

      // Label
      if (r > 10) {
        final tp = TextPainter(
          text: TextSpan(
            text: node.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: (r * 0.32).clamp(9, 14),
              color: node.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: r * 2.5);
        tp.paint(canvas, pos + Offset(-tp.width / 2, r + 4));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GalaxyPainter old) =>
      old.pulse != pulse ||
      old.selectedId != selectedId ||
      old.zoom != zoom ||
      old.pan != pan;
}
