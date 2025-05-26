import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that displays an animated glowing effect in the corners of its child container.
/// Inspired by iOS 18 Siri and Gemini visualizations.
class GlowCornersEffect extends StatefulWidget {
  final Widget child;
  final bool active;
  final double glowSize;
  final double borderRadius;
  final Duration duration;

  const GlowCornersEffect({
    Key? key,
    required this.child,
    required this.active,
    this.glowSize = 64,
    this.borderRadius = 32,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<GlowCornersEffect> createState() => _GlowCornersEffectState();
}

class _GlowCornersEffectState extends State<GlowCornersEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Glow corners only if active
        if (widget.active)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _GlowCornersPainter(
                    progress: _controller.value,
                    glowSize: widget.glowSize,
                    borderRadius: widget.borderRadius,
                  ),
                );
              },
            ),
          ),
        // Main content
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: widget.child,
        ),
      ],
    );
  }
}

class _GlowCornersPainter extends CustomPainter {
  final double progress;
  final double glowSize;
  final double borderRadius;

  _GlowCornersPainter({
    required this.progress,
    required this.glowSize,
    required this.borderRadius,
  });

  final List<List<Color>> colorSets = const [
    [Color(0xFF00FFE7), Color(0xFF5E5CFF), Color(0xFFFF39B7)], // Cyan, blue, pink
    [Color(0xFFFFF500), Color(0xFF00FF85), Color(0xFF00FFE7)], // Yellow, green, cyan
    [Color(0xFFFF39B7), Color(0xFF5E5CFF), Color(0xFFFFF500)], // Pink, blue, yellow
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress;
    final List<Color> colors = colorSets[(progress * colorSets.length).floor() % colorSets.length];
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    // Animate colors for each corner
    for (int i = 0; i < 4; i++) {
      final Offset center = _cornerCenter(i, size, borderRadius);
      final double angle = t * 2 * pi + i * pi / 2;
      final Color color = Color.lerp(colors[i % colors.length], colors[(i + 1) % colors.length], (sin(angle) + 1) / 2)!;
      glowPaint.color = color.withOpacity(0.7);
      canvas.drawCircle(center, glowSize, glowPaint);
    }
  }

  Offset _cornerCenter(int corner, Size size, double r) {
    switch (corner) {
      case 0: return Offset(r, r); // Top-left
      case 1: return Offset(size.width - r, r); // Top-right
      case 2: return Offset(size.width - r, size.height - r); // Bottom-right
      case 3: return Offset(r, size.height - r); // Bottom-left
      default: return Offset.zero;
    }
  }

  @override
  bool shouldRepaint(covariant _GlowCornersPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.glowSize != glowSize ||
      oldDelegate.borderRadius != borderRadius;
}
