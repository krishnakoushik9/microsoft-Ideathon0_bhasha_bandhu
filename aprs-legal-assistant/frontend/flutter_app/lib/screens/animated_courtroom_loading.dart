import 'package:flutter/material.dart';
import 'dart:ui';

/// Modern, minimal AR Courtroom loading overlay with blur and glassmorphism
class AnimatedCourtroomLoading extends StatelessWidget {
  const AnimatedCourtroomLoading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Blur the background
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),
        ),
        // Glassmorphic, floating loader card
        Center(
          child: Container(
            width: size.width < 500 ? size.width * 0.8 : 340,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.19),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_top_rounded, size: 48, color: Colors.amber.shade200),
                SizedBox(height: 22),
                Text(
                  'Summoning Courtroom AI...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.96),
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.7,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 28),
                LinearProgressIndicator(
                  backgroundColor: Colors.white24,
                  color: Colors.amberAccent.shade200,
                  minHeight: 7,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
