import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'config/play_mode.dart';
import 'ui/welcome_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Permitir ambas; luego se bloquea al modo elegido (Parado / Acostado).
  await PlayModePrefs.unlockAllOrientations();
  final saved = await PlayModePrefs.load();
  await PlayModePrefs.applyOrientation(saved);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const NavesArcadeApp());
}

class NavesArcadeApp extends StatelessWidget {
  const NavesArcadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Naves Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0A0E27),
        ),
        scaffoldBackgroundColor: const Color(0xFF050816),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
