import 'package:flutter/material.dart';
import 'app_theme.dart';

class TechBesLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDarkBackground;
  final double fontSize;

  const TechBesLogo({
    super.key,
    this.size = 36.0,
    this.showText = true,
    this.isDarkBackground = false,
    this.fontSize = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logos/logo.png',
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(size * 0.3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: size * 0.4,
                    offset: Offset(0, size * 0.1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.home_repair_service,
                size: size * 0.55,
                color: Colors.white,
              ),
            ),
            if (showText) ...[
              SizedBox(width: size * 0.28),
              Text(
                'Techbes',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: isDarkBackground ? Colors.white : AppTheme.textPrimaryColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
