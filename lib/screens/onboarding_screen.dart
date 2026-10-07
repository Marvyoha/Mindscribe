import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers/settings_provider.dart';
import 'home_screen.dart';

/// Onboarding flow: introduces MindScribe's AI reflection capabilities and
/// optionally configures a custom OpenAI endpoint / API key.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _apiUrlController = TextEditingController();

  int _currentPage = 0;
  bool _showApiKeyConfig = false;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      icon: Icons.auto_awesome_rounded,
      title: 'AI-Powered Journaling',
      subtitle: 'Write freely. MindScribe extracts key takeaways, emotional sentiment, and thoughtful reflection prompts tailored to you.',
    ),
    _OnboardingPage(
      icon: Icons.psychology_alt_rounded,
      title: 'Deep Self-Discovery',
      subtitle: 'Understand your thought patterns and emotional landscape over time with automated reflection summaries.',
    ),
    _OnboardingPage(
      icon: Icons.lock_outline_rounded,
      title: 'Private & Local-First',
      subtitle: 'Your journals live securely on your device in SQLite. Your API keys are stored in the platform keychain.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    _apiUrlController.dispose();
    super.dispose();
  }

  void _finishOnboarding() async {
    final settings = ref.read(settingsProvider.notifier);

    // Save custom key/URL if provided.
    final key = _apiKeyController.text.trim();
    if (key.isNotEmpty) await settings.saveApiKey(key);

    final url = _apiUrlController.text.trim();
    if (url.isNotEmpty) await settings.saveApiUrl(url);

    await settings.completeOnboarding();

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final text = Theme.of(context).colorScheme.secondary;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _PageContent(
                  page: _pages[i],
                  accent: accent,
                  textColor: text,
                  mutedColor: muted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? accent
                          : accent.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_showApiKeyConfig)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    TextField(
                      controller: _apiUrlController,
                      decoration: InputDecoration(
                        labelText: 'OpenAI Base URL (optional)',
                        hintText: 'https://api.openai.com/v1',
                        prefixIcon: const Icon(Icons.link),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'OpenAI API Key (optional)',
                        hintText: 'sk-...',
                        prefixIcon: const Icon(Icons.key),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              )
            else
              TextButton.icon(
                onPressed: () => setState(() => _showApiKeyConfig = true),
                icon: Icon(Icons.settings_outlined, color: accent, size: 18),
                label: Text(
                  'Configure OpenAI Key',
                  style: GoogleFonts.spaceGrotesk(
                    color: accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finishOnboarding();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.page,
    required this.accent,
    required this.textColor,
    required this.mutedColor,
  });

  final _OnboardingPage page;
  final Color accent;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 48, color: accent),
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              height: 1.5,
              color: mutedColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
