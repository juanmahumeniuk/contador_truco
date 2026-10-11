import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Puntaje dibujado con fósforos, como se anota en la mesa: cada cuadrado son
/// 5 puntos (cuatro lados y la diagonal). En una partida a 30 hay dos filas de
/// tres cuadrados: "malas" (1 a 15) y "buenas" (16 a 30).
class MatchstickCounter extends StatelessWidget {
  const MatchstickCounter({
    super.key,
    required this.score,
    required this.targetScore,
  });

  final int score;
  final int targetScore;

  static const int _squaresPerRow = 3;
  static const double _labelHeight = 18;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final labels = targetScore > 15 ? const ['MALAS', 'BUENAS'] : const [''];

    // Anima el avance de los fósforos cuando cambia el puntaje.
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: score.toDouble()),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final rows = labels.length;
            final labelsHeight =
                labels.where((l) => l.isNotEmpty).length * _labelHeight;
            final byWidth =
                (constraints.maxWidth - _gap * (_squaresPerRow - 1)) /
                _squaresPerRow;
            final byHeight =
                (constraints.maxHeight - labelsHeight - _gap * (rows - 1)) /
                rows;
            final side = math.max(0.0, math.min(byWidth, byHeight));

            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < rows; row++) ...[
                    if (row > 0) const SizedBox(height: _gap),
                    if (labels[row].isNotEmpty)
                      SizedBox(
                        height: _labelHeight,
                        child: Text(
                          labels[row],
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white54,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var col = 0; col < _squaresPerRow; col++) ...[
                          if (col > 0) const SizedBox(width: _gap),
                          SizedBox.square(
                            dimension: side,
                            child: CustomPaint(
                              painter: _SquarePainter(
                                progress: progress,
                                firstPoint: (row * _squaresPerRow + col) * 5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Dibuja un cuadrado de 5 fósforos. [firstPoint] es el puntaje (0-based) del
/// primer fósforo del cuadrado y [progress] el puntaje actual, que puede ser
/// fraccionario mientras dura la animación.
class _SquarePainter extends CustomPainter {
  _SquarePainter({required this.progress, required this.firstPoint});

  final double progress;
  final int firstPoint;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width;
    final inset = side * 0.14;
    final topLeft = Offset(inset, inset);
    final topRight = Offset(side - inset, inset);
    final bottomRight = Offset(side - inset, side - inset);
    final bottomLeft = Offset(inset, side - inset);

    // Orden en que se van apoyando los fósforos.
    final matches = <(Offset, Offset)>[
      (topLeft, topRight),
      (topRight, bottomRight),
      (bottomRight, bottomLeft),
      (bottomLeft, topLeft),
      (bottomLeft, topRight),
    ];

    final thickness = side * 0.085;
    final ghostPaint = Paint()
      ..color = TrucoColors.ghost
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final woodPaint = Paint()
      ..color = TrucoColors.wood
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final headPaint = Paint()..color = TrucoColors.matchHead;

    // Huecos tenues para ver cuánto falta.
    for (final (from, to) in matches) {
      canvas.drawLine(from, to, ghostPaint);
    }

    final placed = <(Offset, double)>[];
    for (var i = 0; i < matches.length; i++) {
      final fraction = (progress - (firstPoint + i)).clamp(0.0, 1.0);
      if (fraction <= 0) continue;
      final (from, to) = matches[i];
      canvas.drawLine(from, Offset.lerp(from, to, fraction)!, woodPaint);
      placed.add((from, fraction));
    }

    // Las cabezas van arriba de todo para que se vean en las esquinas.
    for (final (head, fraction) in placed) {
      canvas.drawCircle(head, thickness * 0.85 * fraction, headPaint);
    }
  }

  @override
  bool shouldRepaint(_SquarePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.firstPoint != firstPoint;
}
