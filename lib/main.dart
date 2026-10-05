import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/providers/settings_provider.dart';
import 'core/providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: ".env");

  // Initialize singleton services
  final db = DatabaseService();
  await db.database;

  runApp(const ProviderScope(child: MindScribeApp()));
}

class MindScribeApp extends ConsumerStatefulWidget {
  const MindScribeApp({super.key});

  @override
  ConsumerState<MindScribeApp> createState() => _MindScribeAppState();
}

class _MindScribeAppState extends ConsumerState<MindScribeApp> {
  @override
  void initState() {
    super.initState();

    // Load persisted settings (API keys, onboarding status) into the provider state.
    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'MindScribe',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 245, 92, 92),
          brightness: Brightness.light,
          primary: const Color(0xff4b0082),
          secondary: const Color.fromARGB(255, 245, 92, 92),
          surface: Color(0xffffffff),
          error: const Color(0xFFEF4444),
        ),
        scaffoldBackgroundColor: const Color(0xfff6f6f4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xffccccff),
          brightness: Brightness.dark,
          primary: const Color(0xffccccff),
          secondary: const Color.fromARGB(255, 245, 92, 92),
          surface: const Color(0XFF121212),
          error: const Color(0xFFF87171),
        ),
        scaffoldBackgroundColor: const Color(0xff141414), // Deep Charcoal
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
