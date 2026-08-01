import 'dart:io';

void main() {
  print('--- TechBes Branding Setup Utility ---');
  final sourcePath = 'C:\\Users\\Viswaas-E\\.gemini\\antigravity-ide\\brain\\035171da-79e8-4e91-82c9-32f5857f77a7\\media__1785338459115.png';
  final sourceFile = File(sourcePath);

  if (!sourceFile.existsSync()) {
    print('Error: Source branding logo not found at: $sourcePath');
    return;
  }

  // Define destination paths
  final assetLogo = File('assets/logos/logo.png');
  final androidDrawableLogo = File('android/app/src/main/res/drawable/launch_image.png');

  try {
    // Ensure parent directories exist
    assetLogo.parent.createSync(recursive: true);
    androidDrawableLogo.parent.createSync(recursive: true);

    // Copy to Flutter assets
    sourceFile.copySync(assetLogo.path);
    print('Copied to Flutter assets: ${assetLogo.path}');

    // Copy to Android drawable
    sourceFile.copySync(androidDrawableLogo.path);
    print('Copied to Android drawable: ${androidDrawableLogo.path}');

    print('\nSetup completed successfully! Please run the following commands to generate the icons:');
    print('  flutter pub get');
    print('  flutter pub run flutter_launcher_icons');
  } catch (e) {
    print('Error copying branding assets: $e');
  }
}
