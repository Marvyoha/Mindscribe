import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/journal_provider.dart';
import '../core/providers/settings_provider.dart';
import '../core/providers/theme_provider.dart';
import 'home_screen.dart';

/// Screen for editing API keys, switching themes, and viewing app info.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _apiUrlController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey ?? '');
    _apiUrlController = TextEditingController(text: settings.apiBaseUrl ?? '');
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(settingsProvider.notifier);
    await notifier.saveApiKey(_apiKeyController.text.trim());
    await notifier.saveApiUrl(_apiUrlController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          content: Text(
            'Settings saved successfully.',
            style: GoogleFonts.spaceGrotesk(color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final theme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.check),
            tooltip: 'Save changes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'AI Configuration', accent: accent),
          const SizedBox(height: 12),
          TextField(
            controller: _apiUrlController,
            obscureText: true,

            decoration: InputDecoration(
              labelText: 'OpenAI Base URL',
              hintText: 'https://api.openai.com/v1',
              prefixIcon: const Icon(Icons.link),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'OpenAI API Key',
              hintText: 'sk-...',
              prefixIcon: const Icon(Icons.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Defaults to the key provided in .env if left blank.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Appearance', accent: accent),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Theme Mode',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _themeLabel(theme),
              style: GoogleFonts.spaceGrotesk(fontSize: 13),
            ),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest, size: 18),
                ),
              ],
              selected: {theme},
              onSelectionChanged: (set) {
                ref.read(themeProvider.notifier).setThemeMode(set.first);
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: accent.withValues(alpha: 0.16),
                selectedForegroundColor: accent,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Danger Zone', accent: Colors.red),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              'Clear All Data',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              'Wipe all journals and settings from this device.',
              style: GoogleFonts.spaceGrotesk(fontSize: 13),
            ),
            onTap: () => _confirmClearAll(context, ref),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'MindScribe v1.0.0',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System Default',
  };

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Wipe Everything?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently delete all your journal entries and saved API keys.',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(settingsProvider.notifier).clearAllData();
              await ref.read(journalProvider.notifier).loadEntries();
              ref.read(themeProvider.notifier).setThemeMode(ThemeMode.system);
              if (context.mounted) {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Wipe Data', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.accent});
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: accent,
      ),
    );
  }
}
