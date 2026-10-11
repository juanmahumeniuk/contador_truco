import 'package:flutter/material.dart';

import '../theme.dart';
import 'matchstick_counter.dart';

/// Tarjeta de un equipo: nombre, partidas ganadas, puntaje, fósforos y los
/// botones para sumar o corregir puntos.
class TeamPanel extends StatelessWidget {
  const TeamPanel({
    super.key,
    required this.name,
    required this.score,
    required this.targetScore,
    required this.wins,
    required this.isWinner,
    required this.canAdd,
    required this.onAdd,
    required this.onRemove,
    required this.onRename,
  });

  final String name;
  final int score;
  final int targetScore;
  final int wins;
  final bool isWinner;

  /// `false` cuando la partida terminó y ya no se puede sumar.
  final bool canAdd;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: TrucoColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner ? TrucoColors.gold : Colors.white12,
          width: isWinner ? 2.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _Header(
            name: name,
            score: score,
            targetScore: targetScore,
            wins: wins,
            isWinner: isWinner,
            onRename: onRename,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: MatchstickCounter(score: score, targetScore: targetScore),
          ),
          const SizedBox(height: 8),
          _PointButtons(
            teamName: name,
            canAdd: canAdd,
            canRemove: score > 0,
            onAdd: onAdd,
            onRemove: onRemove,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.score,
    required this.targetScore,
    required this.wins,
    required this.isWinner,
    required this.onRename,
  });

  final String name;
  final int score;
  final int targetScore;
  final int wins;
  final bool isWinner;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _nameAndWins(textTheme)),
            const SizedBox(width: 8),
            // El puntaje nunca ocupa más del 45% para dejar lugar al nombre.
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.45,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _scoreText(textTheme),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _nameAndWins(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          key: const ValueKey('rename'),
          borderRadius: BorderRadius.circular(8),
          onTap: onRename,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit, size: 16, color: Colors.white54),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              size: 16,
              color: wins > 0 || isWinner ? TrucoColors.gold : Colors.white38,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                wins == 1 ? '1 partida ganada' : '$wins partidas ganadas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _scoreText(TextTheme textTheme) {
    return Semantics(
      label: '$score de $targetScore puntos',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$score',
            key: const ValueKey('score'),
            style: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isWinner ? TrucoColors.gold : Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            '/$targetScore',
            style: textTheme.titleMedium?.copyWith(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class _PointButtons extends StatelessWidget {
  const _PointButtons({
    required this.teamName,
    required this.canAdd,
    required this.canRemove,
    required this.onAdd,
    required this.onRemove,
  });

  static const List<int> _increments = [1, 2, 3, 4];

  final String teamName;
  final bool canAdd;
  final bool canRemove;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const compact = EdgeInsets.zero;

    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Tooltip(
              message: 'Quitar un punto a $teamName',
              child: OutlinedButton(
                key: const ValueKey('remove'),
                onPressed: canRemove ? onRemove : null,
                style: OutlinedButton.styleFrom(
                  padding: compact,
                  minimumSize: Size.zero,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('−1', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
          for (final points in _increments) ...[
            const SizedBox(width: 6),
            Expanded(
              flex: points == 1 ? 3 : 2,
              child: Tooltip(
                message:
                    'Sumar $points ${points == 1 ? 'punto' : 'puntos'} a '
                    '$teamName',
                child: _AddButton(
                  key: ValueKey('add$points'),
                  points: points,
                  highlighted: points == 1,
                  onPressed: canAdd ? () => onAdd(points) : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    super.key,
    required this.points,
    required this.highlighted,
    required this.onPressed,
  });

  final int points;
  final bool highlighted;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ButtonStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
      minimumSize: const WidgetStatePropertyAll(Size.zero),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '+$points',
        style: TextStyle(
          fontSize: highlighted ? 22 : 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    return highlighted
        ? FilledButton(onPressed: onPressed, style: style, child: label)
        : FilledButton.tonal(
            onPressed: onPressed,
            style: style.copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? Colors.white10
                    : Colors.white24,
              ),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? Colors.white38
                    : Colors.white,
              ),
            ),
            child: label,
          );
  }
}
