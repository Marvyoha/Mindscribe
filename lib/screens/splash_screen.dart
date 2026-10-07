import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/settings_provider.dart';
import '../core/providers/theme_provider.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

/// First screen shown on app launch.
/// Routes to [OnboardingScreen] or [HomeScreen] based on persisted
/// onboarding status.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final settings = ref.watch(settingsProvider);

    // Resolve the destination as soon as settings load.
    if (!settings.isLoading) {
      final target = settings.hasCompletedOnboarding
          ? const HomeScreen()
          : const OnboardingScreen();
      // Use a post-frame callback to avoid navigating during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!context.mounted) return;
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (_, _, _) => target,
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 800),
            ),
          );
        });
      });
    }

    final brightness = _resolveBrightness(context, themeMode);
    final isDark = brightness == Brightness.dark;
    final logo = isDark
        ? 'assets/Logo_splashscreen_dark.png'
        : 'assets/Logo_splashscreen_light.png';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Center(
          child: _FadeLogo(asset: logo, isDark: isDark),
        ),
      ),
    );
  }

  static Brightness _resolveBrightness(BuildContext context, ThemeMode mode) {
    if (mode == ThemeMode.light) return Brightness.light;
    if (mode == ThemeMode.dark) return Brightness.dark;
    return MediaQuery.of(context).platformBrightness;
  }
}

/// A simple fade-in wrapper around an asset image, used by the splash screen.
class _FadeLogo extends StatefulWidget {
  const _FadeLogo({required this.asset, required this.isDark});

  final String asset;
  final bool isDark;

  @override
  State<_FadeLogo> createState() => _FadeLogoState();
}

class _FadeLogoState extends State<_FadeLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackColor = Theme.of(context).colorScheme.secondary;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
      child: Image.asset(
        widget.asset,
        width: 220,
        height: 220,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            Icon(Icons.edit_note, size: 64, color: fallbackColor),
      ),
    );
  }
}
