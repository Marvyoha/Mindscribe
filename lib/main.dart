import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/settings_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/utils/themes.dart';
import 'screens/splash_screen.dart';
import 'core/services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

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

    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'MindScribe',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: Themes.light(),
      darkTheme: Themes.dark(),
      home: const SplashScreen(),
    );
  }
}
