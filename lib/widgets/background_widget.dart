import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/background_provider.dart';
import '../providers/theme_provider.dart';

class BackgroundWidget extends ConsumerWidget {
  final Widget child;
  final bool showOverlay;

  const BackgroundWidget({
    super.key,
    required this.child,
    this.showOverlay = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backgroundPath = ref.watch(backgroundProvider);
    final themeMode = ref.watch(themeProvider);
    final backgroundNotifier = ref.read(backgroundProvider.notifier);
    
    if (backgroundPath == null) {
      // Use fallback color when no background image is available
      final fallbackColor = backgroundNotifier.getFallbackColor(themeMode);
      return Container(
        decoration: BoxDecoration(
          color: fallbackColor,
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundPath),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // Silently handle image loading errors
            debugPrint('Background image failed to load: $backgroundPath');
          },
        ),
      ),
      child: showOverlay
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white.withOpacity(0.10)
                    : Colors.black.withOpacity(0.10),
              ),
              child: child,
            )
          : child,
    );
  }
} 