import 'package:contador_truco/main.dart';
import 'package:contador_truco/models/truco_game.dart';
import 'package:contador_truco/state/game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder inPanel(Team team, Finder finder) => find.descendant(
  of: find.byKey(ValueKey('panel-${team.name}')),
  matching: finder,
);

/// Toca una opción del menú desplegable (el texto solo no recibe el toque).
Future<void> tapMenuItem(WidgetTester tester, String label) async {
  await tester.tap(
    find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((widget) => widget is PopupMenuItem),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> pumpApp(
  WidgetTester tester,
  GameController controller, {
  Size size = const Size(412, 915),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(TrucoApp(controller: controller));
  await tester.pumpAndSettle();
}

String scoreOf(WidgetTester tester, Team team) => tester
    .widget<Text>(inPanel(team, find.byKey(const ValueKey('score'))))
    .data!;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('muestra los dos equipos en 0', (tester) async {
    await pumpApp(tester, GameController());

    expect(find.text('Nosotros'), findsOneWidget);
    expect(find.text('Ellos'), findsOneWidget);
    expect(find.text('Partida a 30 puntos'), findsOneWidget);
    expect(scoreOf(tester, Team.first), '0');
    expect(scoreOf(tester, Team.second), '0');
    expect(find.text('MALAS'), findsNWidgets(2));
    expect(find.text('BUENAS'), findsNWidgets(2));
  });

  testWidgets('los botones suman y restan puntos a cada equipo', (
    tester,
  ) async {
    await pumpApp(tester, GameController());

    await tester.tap(inPanel(Team.first, find.byKey(const ValueKey('add1'))));
    await tester.tap(inPanel(Team.first, find.byKey(const ValueKey('add3'))));
    await tester.tap(inPanel(Team.second, find.byKey(const ValueKey('add2'))));
    await tester.tap(inPanel(Team.second, find.byKey(const ValueKey('add4'))));
    await tester.pumpAndSettle();

    expect(scoreOf(tester, Team.first), '4');
    expect(scoreOf(tester, Team.second), '6');

    await tester.tap(inPanel(Team.first, find.byKey(const ValueKey('remove'))));
    await tester.pumpAndSettle();
    expect(scoreOf(tester, Team.first), '3');
  });

  testWidgets('el botón de restar está apagado en 0', (tester) async {
    await pumpApp(tester, GameController());

    final remove = tester.widget<OutlinedButton>(
      inPanel(Team.first, find.byKey(const ValueKey('remove'))),
    );
    expect(remove.onPressed, isNull);
  });

  testWidgets('al llegar al objetivo aparece el ganador y se puede '
      'empezar otra partida', (tester) async {
    final controller = GameController(
      game: const TrucoGame().addPoints(Team.first, 28),
    );
    await pumpApp(tester, controller);

    await tester.tap(inPanel(Team.first, find.byKey(const ValueKey('add3'))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('¡Ganó Nosotros!'), findsOneWidget);
    expect(find.text('Resultado final: 30 a 0'), findsOneWidget);

    await tester.tap(find.text('Nueva partida'));
    await tester.pumpAndSettle();

    expect(find.text('¡Ganó Nosotros!'), findsNothing);
    expect(scoreOf(tester, Team.first), '0');
    expect(find.text('1 partida ganada'), findsOneWidget);
    expect(controller.game.winsOf(Team.first), 1);
  });

  testWidgets('"Corregir" cierra el cartel, frena la suma y deja restar', (
    tester,
  ) async {
    final controller = GameController(
      game: const TrucoGame().addPoints(Team.second, 29),
    );
    await pumpApp(tester, controller);

    await tester.tap(inPanel(Team.second, find.byKey(const ValueKey('add1'))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.text('¡Ganó Ellos!'), findsOneWidget);

    await tester.tap(find.text('Corregir'));
    await tester.pumpAndSettle();
    expect(find.text('¡Ganó Ellos!'), findsNothing);

    final add = tester.widget<ButtonStyleButton>(
      find.descendant(
        of: inPanel(Team.first, find.byKey(const ValueKey('add1'))),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(add.onPressed, isNull, reason: 'no se suma con partida terminada');

    await tester.tap(
      inPanel(Team.second, find.byKey(const ValueKey('remove'))),
    );
    await tester.pumpAndSettle();
    expect(scoreOf(tester, Team.second), '29');
    expect(controller.game.winner, isNull);
    expect(controller.game.winsOf(Team.second), 0);
  });

  testWidgets('se puede cambiar el nombre de un equipo', (tester) async {
    final controller = GameController();
    await pumpApp(tester, controller);

    await tester.tap(inPanel(Team.first, find.byKey(const ValueKey('rename'))));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('rename-field')),
      'Los Pibes',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Los Pibes'), findsOneWidget);
    expect(controller.game.nameOf(Team.first), 'Los Pibes');
  });

  testWidgets('cambiar a 15 puntos sin marcador no pide confirmación', (
    tester,
  ) async {
    final controller = GameController();
    await pumpApp(tester, controller);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tapMenuItem(tester, 'Jugar a 15 puntos');

    expect(find.text('Partida a 15 puntos'), findsOneWidget);
    expect(find.text('MALAS'), findsNothing);
    expect(controller.game.targetScore, 15);
  });

  testWidgets('cambiar el objetivo con puntos pide confirmación', (
    tester,
  ) async {
    final controller = GameController(
      game: const TrucoGame().addPoints(Team.first, 5),
    );
    await pumpApp(tester, controller);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tapMenuItem(tester, 'Jugar a 15 puntos');

    expect(find.text('¿Jugar a 15 puntos?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(controller.game.targetScore, 30);
    expect(controller.game.scoreOf(Team.first), 5);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tapMenuItem(tester, 'Jugar a 15 puntos');
    await tester.tap(find.text('Cambiar'));
    await tester.pumpAndSettle();
    expect(controller.game.targetScore, 15);
    expect(controller.game.scoreOf(Team.first), 0);
  });

  testWidgets('nueva partida a medias pide confirmación', (tester) async {
    final controller = GameController(
      game: const TrucoGame().addPoints(Team.first, 9),
    );
    await pumpApp(tester, controller);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tapMenuItem(tester, 'Nueva partida');
    expect(find.text('¿Nueva partida?'), findsOneWidget);

    await tester.tap(find.text('Empezar de nuevo'));
    await tester.pumpAndSettle();
    expect(controller.game.scores, [0, 0]);
    expect(controller.game.wins, [0, 0]);
  });

  testWidgets('borrar partidas ganadas', (tester) async {
    final controller = GameController(
      game: const TrucoGame().addPoints(Team.first, 30).startNewGame(),
    );
    await pumpApp(tester, controller);
    expect(find.text('1 partida ganada'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('menu')));
    await tester.pumpAndSettle();
    await tapMenuItem(tester, 'Borrar partidas ganadas');
    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(controller.game.wins, [0, 0]);
    expect(find.text('0 partidas ganadas'), findsNWidgets(2));
  });

  group('persistencia', () {
    test('cada cambio se guarda y se recupera al volver a abrir', () async {
      final prefs = await SharedPreferences.getInstance();
      final controller = GameController(prefs: prefs)
        ..rename(Team.first, 'Los Pibes')
        ..addPoints(Team.first, 3)
        ..addPoints(Team.second, 2);

      final reopened = await GameController.load();
      expect(reopened.game.scores, [3, 2]);
      expect(reopened.game.nameOf(Team.first), 'Los Pibes');
      expect(reopened.game.encode(), controller.game.encode());
    });

    test('sin nada guardado arranca en 0', () async {
      final controller = await GameController.load();
      expect(controller.game.scores, [0, 0]);
    });
  });

  group('no se desborda en ninguna pantalla', () {
    const sizes = <String, Size>{
      'celular chico vertical': Size(320, 568),
      'celular típico vertical': Size(360, 640),
      'celular grande vertical': Size(412, 915),
      'celular horizontal': Size(800, 360),
      'celular chico horizontal': Size(568, 320),
      'tablet vertical': Size(800, 1280),
    };

    for (final MapEntry(key: label, value: size) in sizes.entries) {
      for (final target in TrucoGame.allowedTargets) {
        testWidgets('$label, a $target', (tester) async {
          final game = const TrucoGame()
              .changeTarget(target)
              .rename(Team.first, 'Nombre muy largo!!')
              .addPoints(Team.first, target - 1)
              .addPoints(Team.second, 8);
          await pumpApp(tester, GameController(game: game), size: size);

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
