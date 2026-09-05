import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
