import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Elegant, multi-layered shimmer overlay for AI model switching.
class AnimatedModelSwitchShimmer extends StatefulWidget {
  const AnimatedModelSwitchShimmer({Key? key}) : super(key: key);

  @override
  State<AnimatedModelSwitchShimmer> createState() => _AnimatedModelSwitchShimmerState();
}

class _AnimatedModelSwitchShimmerState extends State<AnimatedModelSwitchShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutCubic.transform(_controller.value);
        return Stack(
          children: [
            // Soft color pulse background
            Opacity(
              opacity: 0.13 * (1.0 - t),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.14),
                      Colors.transparent,
                    ],
                    center: Alignment(0, -0.2),
                    radius: 0.9,
                  ),
                ),
              ),
            ),
            // Blurred highlight sweep
            Positioned.fill(
              child: CustomPaint(
                painter: _SweepHighlightPainter(progress: t),
              ),
            ),
            // Top-to-bottom shimmer sweep
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.22 * (1.0 - t)),
                        Colors.white.withOpacity(0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, t.clamp(0.0, 1.0), 1.0],
                    ),
                  ),
                ).animate().fade(
                  duration: 1200.ms,
                  begin: 1.0,
                  end: 0.0,
                  curve: Curves.easeIn,
                ).scale(
                  duration: 1200.ms,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.025, 1.025),
                  curve: Curves.easeInOut,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SweepHighlightPainter extends CustomPainter {
  final double progress;
  _SweepHighlightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.22 * (1.0 - progress)),
          Colors.white.withOpacity(0.0)
        ],
        begin: Alignment(-1.0, -1.0 + 2 * progress),
        end: Alignment(1.0, -1.0 + 2 * progress),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 32);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_SweepHighlightPainter oldDelegate) => oldDelegate.progress != progress;
}
