import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/ai_provider.dart';

/// A premium, animated toggle button for switching between Hugging Face and Gemini AI.
class AIProviderToggle extends StatefulWidget {
  final AIProvider provider;
  final ValueChanged<AIProvider> onChanged;

  const AIProviderToggle({
    super.key,
    required this.provider,
    required this.onChanged,
  });

  @override
  State<AIProviderToggle> createState() => _AIProviderToggleState();
}

class _AIProviderToggleState extends State<AIProviderToggle> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHuggingFace = widget.provider == AIProvider.huggingFace;
    final gradientColors = isHuggingFace
        ? [Colors.deepPurple, Colors.purpleAccent, Colors.blueAccent]
        : [Colors.teal, Colors.cyanAccent, Colors.greenAccent];
    final glowColor = isHuggingFace ? Colors.deepPurpleAccent : Colors.tealAccent;
    
    // Logo widget with proper theming
    Widget _buildLogo() {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isHuggingFace ? Colors.deepPurple : Colors.teal,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isHuggingFace ? Icons.hub : Icons.bubble_chart,
            color: Colors.white,
            size: 16,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => widget.onChanged(isHuggingFace ? AIProvider.gemini : AIProvider.huggingFace),
      child: AnimatedScale(
        duration: 180.ms,
        scale: _pressed ? 0.96 : 1.0,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white.withOpacity(0.11),
            boxShadow: [
              BoxShadow(
                color: glowColor.withOpacity(0.22),
                blurRadius: 24,
                spreadRadius: 1.5,
                offset: const Offset(0, 0),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              width: 2.5,
              style: BorderStyle.solid,
              color: glowColor.withOpacity(0.27),
            ),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            backgroundBlendMode: BlendMode.screen,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated glowing border sweep
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            width: 4.5,
                            style: BorderStyle.solid,
                            color: glowColor.withOpacity(0.14),
                          ),
                          gradient: SweepGradient(
                            colors: [
                              ...gradientColors,
                              gradientColors.first
                            ],
                            stops: [0.0, 0.45, 0.8, 1.0],
                            transform: GradientRotation(_glowController.value * 6.283),
                          ),
                        ),
                      ).animate().shimmer(
                        duration: 1600.ms,
                        angle: 0.8,
                        color: glowColor.withOpacity(0.13),
                      ),
                    );
                  },
                ),
              ),
              // Content row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: 420.ms,
                    transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                    child: Icon(
                      isHuggingFace ? Icons.hub : Icons.bubble_chart,
                      key: ValueKey(isHuggingFace),
                      color: Colors.white,
                      size: 24,
                      shadows: [
                        Shadow(
                          color: glowColor.withOpacity(0.8),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSwitcher(
                    duration: 420.ms,
                    transitionBuilder: (child, anim) => SlideTransition(
                      position: Tween<Offset>(
                        begin: Offset(isHuggingFace ? -0.45 : 0.45, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Text(
                      isHuggingFace ? 'HuggingFace' : 'Gemini',
                      key: ValueKey(isHuggingFace),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 0.1,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Animate(
                    effects: [
                      ShimmerEffect(
                        duration: 1300.ms,
                        color: glowColor.withOpacity(0.45),
                        angle: 0.7,
                      ),
                      ScaleEffect(
                        duration: 500.ms,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.18, 1.18),
                        curve: Curves.easeInOut,
                        delay: 200.ms,
                      ),
                    ],
                    child: Icon(Icons.flash_on, color: Colors.white.withOpacity(0.75), size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
