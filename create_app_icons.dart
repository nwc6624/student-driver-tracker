import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() async {
  print('Creating app icons for Student Driver Tracker...');
  
  // Create the base icon (you'll need to replace this with your actual icon)
  // For now, we'll create a placeholder southwestern-themed icon
  final icon = createSouthwesternIcon();
  
  // Define all required icon sizes for Android
  final iconSizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  
  // Create icons for each resolution
  for (final entry in iconSizes.entries) {
    final directory = 'android/app/src/main/res/${entry.key}';
    final size = entry.value;
    
    // Create directory if it doesn't exist
    await Directory(directory).create(recursive: true);
    
    // Resize and save icon
    final resizedIcon = img.copyResize(icon, width: size, height: size);
    final file = File('$directory/ic_launcher.png');
    await file.writeAsBytes(img.encodePng(resizedIcon));
    
    print('Created ${entry.key}/ic_launcher.png (${size}x${size})');
  }
  
  // Create adaptive icon files for modern Android
  await createAdaptiveIcons();
  
  print('App icons created successfully!');
  print('\nNext steps:');
  print('1. Replace the placeholder icons with your actual southwestern-themed icon');
  print('2. Generate a keystore for app signing');
  print('3. Update key.properties with your keystore details');
  print('4. Build release APK: flutter build appbundle --release');
}

img.Image createSouthwesternIcon() {
  // Create a 512x512 base icon (highest resolution)
  final icon = img.Image(width: 512, height: 512);
  
  // Fill with southwestern background color
  img.fill(icon, color: img.ColorRgb8(245, 245, 220)); // Beige
  
  // Create a circular background
  final center = 256;
  final radius = 200;
  
  // Draw circular background with southwestern gradient
  for (int y = 0; y < 512; y++) {
    for (int x = 0; x < 512; x++) {
      final distance = math.sqrt((x - center) * (x - center) + (y - center) * (y - center));
      if (distance <= radius) {
        final ratio = distance / radius;
        final r = (210 + ratio * 45).round(); // Orange to brown gradient
        final g = (105 + ratio * 69).round();
        final b = (30 + ratio * 19).round();
        icon.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }
  }
  
  // Draw a simple car icon in the center
  drawCarIcon(icon, center, center, 120);
  
  return icon;
}

void drawCarIcon(img.Image image, int centerX, int centerY, int size) {
  final halfSize = size ~/ 2;
  
  // Car body (rectangle)
  final carColor = img.ColorRgb8(255, 255, 255);
  final carTop = centerY - halfSize ~/ 2;
  final carBottom = centerY + halfSize ~/ 2;
  final carLeft = centerX - halfSize;
  final carRight = centerX + halfSize;
  
  // Fill car body
  for (int y = carTop; y <= carBottom; y++) {
    for (int x = carLeft; x <= carRight; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, carColor);
      }
    }
  }
  
  // Car windows (smaller rectangles)
  final windowColor = img.ColorRgb8(135, 206, 235); // Sky blue
  final windowSize = halfSize ~/ 3;
  
  // Front window
  final frontWindowLeft = centerX - windowSize;
  final frontWindowRight = centerX - windowSize ~/ 2;
  final frontWindowTop = carTop + 5;
  final frontWindowBottom = carTop + windowSize;
  
  for (int y = frontWindowTop; y <= frontWindowBottom; y++) {
    for (int x = frontWindowLeft; x <= frontWindowRight; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, windowColor);
      }
    }
  }
  
  // Back window
  final backWindowLeft = centerX + windowSize ~/ 2;
  final backWindowRight = centerX + windowSize;
  final backWindowTop = carTop + 5;
  final backWindowBottom = carTop + windowSize;
  
  for (int y = backWindowTop; y <= backWindowBottom; y++) {
    for (int x = backWindowLeft; x <= backWindowRight; x++) {
      if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
        image.setPixel(x, y, windowColor);
      }
    }
  }
}

Future<void> createAdaptiveIcons() async {
  // Create adaptive icon background
  final background = img.Image(width: 108, height: 108);
  img.fill(background, color: img.ColorRgb8(245, 245, 220)); // Beige
  
  // Create adaptive icon foreground (car icon)
  final foreground = img.Image(width: 108, height: 108);
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0)); // Transparent
  
  final carIcon = createSouthwesternIcon();
  final resizedCar = img.copyResize(carIcon, width: 72, height: 72);
  
  // Center the car icon in the foreground
  final offset = (108 - 72) ~/ 2;
  img.compositeImage(foreground, resizedCar, dstX: offset, dstY: offset);
  
  // Save adaptive icons
  final mipmapDir = 'android/app/src/main/res/mipmap-anydpi-v26';
  await Directory(mipmapDir).create(recursive: true);
  
  await File('$mipmapDir/ic_launcher_background.png').writeAsBytes(img.encodePng(background));
  await File('$mipmapDir/ic_launcher_foreground.png').writeAsBytes(img.encodePng(foreground));
  
  print('Created adaptive icons in $mipmapDir/');
} 