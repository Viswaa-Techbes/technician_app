import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/techbes_logo.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      backgroundColor: AppTheme.darkBackgroundColor, // slate 900
      body: Stack(
        children: [
          // Ambient background gradient matching the web app radial styling
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [
                    Color(0x222563EB), // Blue glow
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.bottomLeft,
                  radius: 1.5,
                  colors: [
                    Color(0x0C10B981), // Green glow
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TechBesLogo(
                  size: 64.0,
                  fontSize: 32.0,
                  isDarkBackground: true,
                ),
                SizedBox(height: 16),
                Text(
                  "India's Trusted IT Service Marketplace",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 48),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor), // Techbes Orange spinner
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
