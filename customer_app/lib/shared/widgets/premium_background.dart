import 'package:flutter/material.dart';
import 'package:customer_app/core/theme/app_colors.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Stack(
      children: [
        // Base linear gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [
                        const Color(0xFFF8FFFD),
                        const Color(0xFFEEF9FF),
                        Colors.white,
                      ]
                    : [
                        AppColors.darkSurface,
                        AppColors.slate950,
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Radial highlights using CustomPaint to exactly match CSS styling
        Positioned.fill(
          child: CustomPaint(
            painter: _GradientPainter(isLight: isLight),
          ),
        ),

        // Content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GradientPainter extends CustomPainter {
  final bool isLight;

  _GradientPainter({required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Top left radial gradient (Emerald)
    final emeraldCenter = Offset(0, 0);
    final emeraldRadius = size.width * 0.6;
    final emeraldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isLight
              ? AppColors.emerald500.withOpacity(0.12)
              : AppColors.emerald500.withOpacity(0.06),
          Colors.transparent,
        ],
        center: Alignment.topLeft,
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: emeraldCenter, radius: emeraldRadius));

    canvas.drawCircle(emeraldCenter, emeraldRadius, emeraldPaint);

    // 2. Top right/center radial gradient (Blue)
    final blueCenter = Offset(size.width * 0.85, size.height * 0.15);
    final blueRadius = size.width * 0.5;
    final bluePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          isLight
              ? AppColors.blue600.withOpacity(0.10)
              : AppColors.blue600.withOpacity(0.04),
          Colors.transparent,
        ],
        center: const Alignment(0.7, -0.7),
        radius: 1.0,
      ).createShader(Rect.fromCircle(center: blueCenter, radius: blueRadius));

    canvas.drawCircle(blueCenter, blueRadius, bluePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
