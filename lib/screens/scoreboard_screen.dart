import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/truco_game.dart';
import '../state/game_controller.dart';
import '../theme.dart';
import '../widgets/team_panel.dart';

enum _MenuAction { newGame, target15, target30, resetWins, about }

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  GameController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final game = _controller.game;
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contador de Truco',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  'Partida a ${game.targetScore} puntos',
                  key: const ValueKey('target-label'),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<_MenuAction>(
                key: const ValueKey('menu'),
                tooltip: 'Menú',
                onSelected: _onMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _MenuAction.newGame,
                    child: ListTile(
                      leading: Icon(Icons.refresh),
                      title: Text('Nueva partida'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  CheckedPopupMenuItem(
                    value: _MenuAction.target15,
                    checked: game.targetScore == 15,
                    child: const Text('Jugar a 15 puntos'),
                  ),
                  CheckedPopupMenuItem(
                    value: _MenuAction.target30,
                    checked: game.targetScore == 30,
                    child: const Text('Jugar a 30 puntos'),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _MenuAction.resetWins,
                    child: ListTile(
                      leading: Icon(Icons.emoji_events_outlined),
                      title: Text('Borrar partidas ganadas'),
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _MenuAction.about,
                    child: ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Acerca de'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final panels = [
                    for (final team in Team.values)
                      Expanded(child: _buildPanel(game, team)),
                  ];
                  return orientation == Orientation.portrait
                      ? Column(
                          children: [
                            panels[0],
                            const SizedBox(height: 12),
                            panels[1],
                          ],
                        )
                      : Row(
                          children: [
                            panels[0],
                            const SizedBox(width: 12),
                            panels[1],
                          ],
                        );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanel(TrucoGame game, Team team) {
    return KeyedSubtree(
      key: ValueKey('panel-${team.name}'),
      child: TeamPanel(
        name: game.nameOf(team),
        score: game.scoreOf(team),
        targetScore: game.targetScore,
        wins: game.winsOf(team),
        isWinner: game.winner == team,
        canAdd: !game.isFinished,
        onAdd: (points) => _addPoints(team, points),
        onRemove: () {
          HapticFeedback.selectionClick();
          _controller.removePoint(team);
        },
        onRename: () => _renameTeam(team),
      ),
    );
  }

  void _addPoints(Team team, int points) {
    final hadWinner = _controller.game.isFinished;
    _controller.addPoints(team, points);
    if (!hadWinner && _controller.game.isFinished) {
      HapticFeedback.heavyImpact();
      // Deja ver cómo se apoya el último fósforo antes de mostrar el cartel.
      Timer(const Duration(milliseconds: 450), () {
        if (mounted) unawaited(_showWinnerDialog());
      });
    } else {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _showWinnerDialog() async {
    final game = _controller.game;
    final winner = game.winner;
    if (winner == null) return;

    final startNew = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emoji_events, color: TrucoColors.gold, size: 48),
        title: Text(
          '¡Ganó ${game.nameOf(winner)}!',
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Resultado final: ${game.scoreOf(winner)} a '
          '${game.scoreOf(winner.other)}',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Corregir'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Nueva partida'),
          ),
        ],
      ),
    );

    if (startNew == true && mounted) _controller.startNewGame();
  }

  Future<void> _renameTeam(Team team) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (context) =>
          _RenameDialog(initialName: _controller.game.nameOf(team)),
    );
    if (newName != null) _controller.rename(team, newName);
  }

  Future<void> _onMenuAction(_MenuAction action) async {
    final game = _controller.game;
    switch (action) {
      case _MenuAction.newGame:
        // Una partida terminada solo se cierra; una a medias pide confirmar.
        if (game.isFinished || !game.hasPoints) {
          _controller.startNewGame();
        } else if (await _confirm(
          title: '¿Nueva partida?',
          message:
              'Se borra el marcador actual y nadie suma una partida ganada.',
          confirmLabel: 'Empezar de nuevo',
        )) {
          _controller.startNewGame();
        }
      case _MenuAction.target15:
      case _MenuAction.target30:
        final target = action == _MenuAction.target15 ? 15 : 30;
        if (target == game.targetScore) return;
        if (!game.hasPoints ||
            await _confirm(
              title: '¿Jugar a $target puntos?',
              message: 'Cambiar el objetivo reinicia el marcador actual.',
              confirmLabel: 'Cambiar',
            )) {
          _controller.changeTarget(target);
        }
      case _MenuAction.about:
        _showAbout();
      case _MenuAction.resetWins:
        if (await _confirm(
          title: '¿Borrar partidas ganadas?',
          message: 'Los dos equipos vuelven a 0 partidas ganadas.',
          confirmLabel: 'Borrar',
        )) {
          _controller.resetWins();
        }
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Contador de Truco',
      applicationLegalese:
          'Código abierto, sin anuncios y sin monetización.\n'
          'Libre para todos, para siempre.',
      children: const [
        SizedBox(height: 16),
        SelectableText(
          'Código fuente:\ngithub.com/juanmahumeniuk/contador_truco',
        ),
      ],
    );
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.initialName,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _textController.text);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nombre del equipo'),
      content: TextField(
        key: const ValueKey('rename-field'),
        controller: _textController,
        autofocus: true,
        maxLength: TrucoGame.maxNameLength,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Guardar')),
      ],
    );
  }
}
