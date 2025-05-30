// lib/domain/models/game_state.dart
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'piece.dart';

enum GameStatus { playing, won, lost }

class GameState extends Equatable {
  static const gridSize = 9;

  final List<List<Piece>> board;
  final int movesLeft;
  final int selectedColor;
  final GameStatus status;

  final int undosLeft;
  final int bombsLeft;

  /// Território antes da jogada atual (para contorno na UI)
  final Set<Point<int>> lastTerritory;

  /// Data/hora em que a partida começou
  final DateTime startTime;

  /// Pontuação final (0 enquanto não vencer)
  final int score;

  const GameState({
    required this.board,
    required this.movesLeft,
    required this.selectedColor,
    required this.status,
    required this.undosLeft,
    required this.bombsLeft,
    required this.startTime,
    this.lastTerritory = const {},
    this.score = 0,
  });

  factory GameState.initial() {
    final rng = Random();
    final b = List.generate(
      gridSize,
      (_) => List.generate(gridSize, (_) => Piece.random(rng)),
    );
    return GameState(
      board: b,
      movesLeft: 24,
      selectedColor: b[0][0].colorIndex,
      status: GameStatus.playing,
      undosLeft: 3,
      bombsLeft: 1,
      startTime: DateTime.now(),
      lastTerritory: const {},
    );
  }

  GameState copyWith({
    List<List<Piece>>? board,
    int? movesLeft,
    int? selectedColor,
    GameStatus? status,
    int? undosLeft,
    int? bombsLeft,
    Set<Point<int>>? lastTerritory,
    DateTime? startTime,
    int? score,
  }) =>
      GameState(
        board: board ?? this.board,
        movesLeft: movesLeft ?? this.movesLeft,
        selectedColor: selectedColor ?? this.selectedColor,
        status: status ?? this.status,
        undosLeft: undosLeft ?? this.undosLeft,
        bombsLeft: bombsLeft ?? this.bombsLeft,
        lastTerritory: lastTerritory ?? this.lastTerritory,
        startTime: startTime ?? this.startTime,
        score: score ?? this.score,
      );

  @override
  List<Object?> get props => [
        board,
        movesLeft,
        selectedColor,
        status,
        undosLeft,
        bombsLeft,
        lastTerritory,
        startTime,
        score,
      ];
}
