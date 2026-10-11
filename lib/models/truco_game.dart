import 'dart:convert';

/// Los dos equipos que juegan una partida.
enum Team {
  first,
  second;

  Team get other => this == first ? second : first;
}

/// Estado inmutable de una partida de truco: puntajes, nombres y partidas
/// ganadas de cada equipo. Todas las operaciones devuelven un estado nuevo
/// (o `this` si no cambia nada).
class TrucoGame {
  const TrucoGame({
    this.targetScore = defaultTarget,
    this.scores = const [0, 0],
    this.names = defaultNames,
    this.wins = const [0, 0],
  });

  static const int defaultTarget = 30;

  /// Se puede jugar a 15 (una vuelta) o a 30 (malas y buenas).
  static const List<int> allowedTargets = [15, 30];

  static const List<String> defaultNames = ['Nosotros', 'Ellos'];

  static const int maxNameLength = 16;

  final int targetScore;
  final List<int> scores;
  final List<String> names;
  final List<int> wins;

  int scoreOf(Team team) => scores[team.index];
  String nameOf(Team team) => names[team.index];
  int winsOf(Team team) => wins[team.index];

  /// Equipo que llegó al puntaje objetivo, o `null` si la partida sigue.
  Team? get winner {
    for (final team in Team.values) {
      if (scoreOf(team) >= targetScore) return team;
    }
    return null;
  }

  bool get isFinished => winner != null;

  bool get hasPoints => scores.any((score) => score > 0);

  /// Suma [points] al equipo. El puntaje nunca pasa del objetivo y, una vez
  /// terminada la partida, no se pueden sumar más puntos.
  TrucoGame addPoints(Team team, int points) {
    assert(points > 0, 'points debe ser positivo');
    if (isFinished) return this;
    final next = (scoreOf(team) + points).clamp(0, targetScore);
    return _copyWith(scores: _replaced(scores, team, next));
  }

  /// Resta un punto (para corregir errores). También funciona con la
  /// partida terminada, así se puede corregir el último punto.
  TrucoGame removePoint(Team team) {
    final current = scoreOf(team);
    if (current == 0) return this;
    return _copyWith(scores: _replaced(scores, team, current - 1));
  }

  /// Arranca otra partida. Si había un ganador, se le suma la victoria.
  TrucoGame startNewGame() {
    final currentWinner = winner;
    return _copyWith(
      scores: const [0, 0],
      wins: currentWinner == null
          ? wins
          : _replaced(wins, currentWinner, winsOf(currentWinner) + 1),
    );
  }

  /// Cambia el objetivo. Reinicia el marcador porque los puntos de una
  /// partida a 30 no tienen sentido en una a 15.
  TrucoGame changeTarget(int target) {
    assert(allowedTargets.contains(target), 'objetivo no permitido: $target');
    if (target == targetScore) return this;
    return _copyWith(targetScore: target, scores: const [0, 0]);
  }

  TrucoGame resetWins() {
    if (wins.every((count) => count == 0)) return this;
    return _copyWith(wins: const [0, 0]);
  }

  /// Renombra un equipo. Un nombre vacío vuelve al nombre por defecto.
  TrucoGame rename(Team team, String name) {
    var clean = name.trim();
    if (clean.length > maxNameLength) {
      clean = clean.substring(0, maxNameLength).trimRight();
    }
    if (clean.isEmpty) clean = defaultNames[team.index];
    if (clean == nameOf(team)) return this;
    return _copyWith(names: _replaced(names, team, clean));
  }

  Map<String, Object?> toJson() => {
    'targetScore': targetScore,
    'scores': scores,
    'names': names,
    'wins': wins,
  };

  String encode() => jsonEncode(toJson());

  /// Lee un estado guardado. Si el contenido está dañado o no tiene sentido
  /// devuelve una partida nueva en vez de fallar.
  factory TrucoGame.decode(String? source) {
    if (source == null) return const TrucoGame();
    try {
      final json = jsonDecode(source);
      if (json is! Map<String, dynamic>) return const TrucoGame();

      final target = json['targetScore'];
      final targetScore = allowedTargets.contains(target)
          ? target as int
          : defaultTarget;

      final scores = _readInts(json['scores']);
      final wins = _readInts(json['wins']);
      final names = json['names'];
      if (scores == null || wins == null) return const TrucoGame();
      if (names is! List ||
          names.length != 2 ||
          names.any((n) => n is! String)) {
        return const TrucoGame();
      }

      return const TrucoGame()
          ._copyWith(
            targetScore: targetScore,
            scores: [for (final s in scores) s.clamp(0, targetScore)],
            wins: [for (final w in wins) w < 0 ? 0 : w],
          )
          .rename(Team.first, names[0] as String)
          .rename(Team.second, names[1] as String);
    } on FormatException {
      return const TrucoGame();
    }
  }

  static List<int>? _readInts(Object? value) {
    if (value is! List || value.length != 2 || value.any((v) => v is! int)) {
      return null;
    }
    return List<int>.from(value);
  }

  static List<T> _replaced<T>(List<T> list, Team team, T value) {
    final copy = List<T>.of(list);
    copy[team.index] = value;
    return List<T>.unmodifiable(copy);
  }

  TrucoGame _copyWith({
    int? targetScore,
    List<int>? scores,
    List<String>? names,
    List<int>? wins,
  }) {
    return TrucoGame(
      targetScore: targetScore ?? this.targetScore,
      scores: scores ?? this.scores,
      names: names ?? this.names,
      wins: wins ?? this.wins,
    );
  }
}
