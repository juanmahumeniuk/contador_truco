import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/truco_game.dart';

/// Mantiene la partida en curso y la guarda en el teléfono después de cada
/// cambio, así no se pierde el marcador si se cierra la app.
class GameController extends ChangeNotifier {
  GameController({this._game = const TrucoGame(), this._prefs});

  static const String storageKey = 'truco_game_v1';

  /// Carga la última partida guardada. Si el almacenamiento falla, se juega
  /// igual, solo que sin guardar.
  static Future<GameController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return GameController(
        game: TrucoGame.decode(prefs.getString(storageKey)),
        prefs: prefs,
      );
    } catch (error) {
      debugPrint('No se pudo leer la partida guardada: $error');
      return GameController();
    }
  }

  final SharedPreferences? _prefs;
  TrucoGame _game;

  TrucoGame get game => _game;

  void addPoints(Team team, int points) =>
      _update(_game.addPoints(team, points));

  void removePoint(Team team) => _update(_game.removePoint(team));

  void startNewGame() => _update(_game.startNewGame());

  void changeTarget(int target) => _update(_game.changeTarget(target));

  void resetWins() => _update(_game.resetWins());

  void rename(Team team, String name) => _update(_game.rename(team, name));

  void _update(TrucoGame next) {
    if (identical(next, _game)) return;
    _game = next;
    notifyListeners();
    final prefs = _prefs;
    if (prefs != null) {
      unawaited(
        prefs.setString(storageKey, next.encode()).catchError((Object error) {
          debugPrint('No se pudo guardar la partida: $error');
          return false;
        }),
      );
    }
  }
}
