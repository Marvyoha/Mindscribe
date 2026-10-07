import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Top header shown on the home screen.
///
/// Renders the theme-aware logo alongside a theme toggle and a settings
/// shortcut. The logo asset switches between light/dark variants based on the
/// current [Brightness] so branding stays consistent across themes.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.onThemeToggle,
    required this.onSettings,
    this.title,
  });

  final VoidCallback onThemeToggle;
  final VoidCallback onSettings;
  final String? title;

  static const _lightLogo = 'assets/Logo_light.png';
  static const _darkLogo = 'assets/Logo_dark.png';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final logoAsset = isDark ? _darkLogo : _lightLogo;
    final color = Theme.of(context).colorScheme.secondary;

    return AppBar(
      toolbarHeight: 72,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Image.asset(
          logoAsset,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(Icons.edit_note, color: color),
        ),
      ),
      title: title == null
          ? null
          : Text(
              title!,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
      actions: [
        // IconButton(
        //   onPressed: onThemeToggle,
        //   icon: Icon(
        //     isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        //     color: color,
        //   ),
        //   tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
        // ),
        IconButton(
          onPressed: onSettings,
          icon: Icon(Icons.settings_outlined, color: color),
          tooltip: 'Settings',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);
}
