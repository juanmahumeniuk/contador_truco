import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/scoreboard_screen.dart';
import 'state/game_controller.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await GameController.load();
  runApp(TrucoApp(controller: controller));
}

class TrucoApp extends StatelessWidget {
  const TrucoApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador de Truco',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: ScoreboardScreen(controller: controller),
    );
  }
}
