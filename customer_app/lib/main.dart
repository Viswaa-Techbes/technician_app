import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/notification_service.dart';

void copyBrandingAssets() {
  try {
    final sourcePath = 'C:\\Users\\Viswaas-E\\.gemini\\antigravity-ide\\brain\\035171da-79e8-4e91-82c9-32f5857f77a7\\media__1785338459115.png';
    final sourceFile = File(sourcePath);
    if (sourceFile.existsSync()) {
      final assetDir = Directory('assets/logos');
      if (!assetDir.existsSync()) {
        assetDir.createSync(recursive: true);
      }
      sourceFile.copySync('assets/logos/logo.png');

      final mipmapDirs = [
        'android/app/src/main/res/mipmap-mdpi',
        'android/app/src/main/res/mipmap-hdpi',
        'android/app/src/main/res/mipmap-xhdpi',
        'android/app/src/main/res/mipmap-xxhdpi',
        'android/app/src/main/res/mipmap-xxxhdpi',
      ];
      for (final dir in mipmapDirs) {
        final d = Directory(dir);
        if (d.existsSync()) {
          sourceFile.copySync('$dir/ic_launcher.png');
        }
      }
    }
  } catch (_) {}
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  copyBrandingAssets();

  runApp(
    const ProviderScope(
      child: CustomerApp(),
    ),
  );

  Future.microtask(() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('FCM background initialization failed: $e');
    }
  });
}

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Techbes Service CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
