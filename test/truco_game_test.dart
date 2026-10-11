import 'package:contador_truco/models/truco_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('puntos', () {
    test('arranca 0 a 0, a 30 puntos y sin victorias', () {
      const game = TrucoGame();
      expect(game.targetScore, 30);
      expect(game.scores, [0, 0]);
      expect(game.wins, [0, 0]);
      expect(game.winner, isNull);
      expect(game.hasPoints, isFalse);
    });

    test('suma puntos solo al equipo indicado', () {
      final game = const TrucoGame()
          .addPoints(Team.first, 2)
          .addPoints(Team.second, 3)
          .addPoints(Team.first, 1);
      expect(game.scoreOf(Team.first), 3);
      expect(game.scoreOf(Team.second), 3);
      expect(game.hasPoints, isTrue);
    });

    test('el puntaje no pasa del objetivo y se declara ganador', () {
      final game = const TrucoGame()
          .addPoints(Team.first, 28)
          .addPoints(Team.first, 4);
      expect(game.scoreOf(Team.first), 30);
      expect(game.winner, Team.first);
      expect(game.isFinished, isTrue);
    });

    test('con la partida terminada no se puede sumar más', () {
      final finished = const TrucoGame().addPoints(Team.first, 30);
      expect(identical(finished.addPoints(Team.second, 1), finished), isTrue);
      expect(finished.scoreOf(Team.second), 0);
    });

    test('con objetivo 15 gana quien llega a 15', () {
      final game = const TrucoGame()
          .changeTarget(15)
          .addPoints(Team.second, 15);
      expect(game.winner, Team.second);
    });

    test('restar un punto no baja de cero', () {
      const game = TrucoGame();
      expect(identical(game.removePoint(Team.first), game), isTrue);
      final back = game.addPoints(Team.first, 1).removePoint(Team.first);
      expect(back.scoreOf(Team.first), 0);
    });

    test('restar un punto al ganador reabre la partida', () {
      final finished = const TrucoGame().addPoints(Team.first, 30);
      final reopened = finished.removePoint(Team.first);
      expect(reopened.scoreOf(Team.first), 29);
      expect(reopened.winner, isNull);
    });
  });

  group('partidas', () {
    test('nueva partida suma la victoria al ganador y limpia el marcador', () {
      final next = const TrucoGame()
          .addPoints(Team.first, 10)
          .addPoints(Team.second, 30)
          .startNewGame();
      expect(next.scores, [0, 0]);
      expect(next.winsOf(Team.second), 1);
      expect(next.winsOf(Team.first), 0);
    });

    test('nueva partida sin ganador no suma victorias', () {
      final next = const TrucoGame().addPoints(Team.first, 10).startNewGame();
      expect(next.scores, [0, 0]);
      expect(next.wins, [0, 0]);
    });

    test('las victorias se acumulan y se pueden borrar', () {
      var game = const TrucoGame();
      for (var i = 0; i < 3; i++) {
        game = game.addPoints(Team.first, 30).startNewGame();
      }
      expect(game.winsOf(Team.first), 3);
      expect(game.resetWins().wins, [0, 0]);
    });

    test('cambiar el objetivo reinicia el marcador pero no las victorias', () {
      final game = const TrucoGame()
          .addPoints(Team.first, 30)
          .startNewGame()
          .addPoints(Team.second, 7);
      final changed = game.changeTarget(15);
      expect(changed.targetScore, 15);
      expect(changed.scores, [0, 0]);
      expect(changed.winsOf(Team.first), 1);
      expect(identical(changed.changeTarget(15), changed), isTrue);
    });
  });

  group('nombres', () {
    test('se recortan los espacios', () {
      final game = const TrucoGame().rename(Team.first, '  Los Pibes  ');
      expect(game.nameOf(Team.first), 'Los Pibes');
    });

    test('un nombre vacío vuelve al nombre por defecto', () {
      final game = const TrucoGame()
          .rename(Team.second, 'Otros')
          .rename(Team.second, '   ');
      expect(game.nameOf(Team.second), 'Ellos');
    });

    test('un nombre demasiado largo se corta', () {
      final game = const TrucoGame().rename(Team.first, 'A' * 40);
      expect(game.nameOf(Team.first).length, TrucoGame.maxNameLength);
    });
  });

  group('guardado', () {
    test('ida y vuelta conserva todo el estado', () {
      final game = const TrucoGame()
          .rename(Team.first, 'Los Pibes')
          .addPoints(Team.first, 30)
          .startNewGame()
          .changeTarget(15)
          .addPoints(Team.second, 6);
      final restored = TrucoGame.decode(game.encode());
      expect(restored.targetScore, 15);
      expect(restored.scores, [0, 6]);
      expect(restored.wins, [1, 0]);
      expect(restored.names, ['Los Pibes', 'Ellos']);
    });

    test('sin datos guardados arranca una partida nueva', () {
      expect(TrucoGame.decode(null).scores, [0, 0]);
    });

    test('datos dañados no rompen la app', () {
      for (final garbage in [
        '',
        'no es json',
        '[]',
        '{}',
        '{"scores": "x"}',
        '{"targetScore": 30, "scores": [1], "wins": [0, 0], "names": ["a", "b"]}',
        '{"targetScore": 30, "scores": [1, 2], "wins": [0, 0], "names": [1, 2]}',
      ]) {
        final game = TrucoGame.decode(garbage);
        expect(game.scores, [0, 0], reason: 'entrada: $garbage');
        expect(game.names, TrucoGame.defaultNames, reason: 'entrada: $garbage');
      }
    });

    test('puntajes fuera de rango u objetivo inválido se corrigen', () {
      final game = TrucoGame.decode(
        '{"targetScore": 99, "scores": [500, -4], "wins": [-1, 2],'
        ' "names": ["", "Ellos"]}',
      );
      expect(game.targetScore, 30);
      expect(game.scores, [30, 0]);
      expect(game.wins, [0, 2]);
      expect(game.nameOf(Team.first), 'Nosotros');
    });
  });
}
