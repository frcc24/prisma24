// lib/presentation/providers/game_provider.dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/prism_game_models/game_state.dart';
import '../../../domain/models/prism_game_models/piece.dart';

/// Provider global do jogo
final gameProvider =
    StateNotifierProvider<GameController, GameState>((ref) => GameController());

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState.initial());
  int _baseTiles = 1; // começa com a peça inicial
  int _movesUsed = 0; // incrementa a cada jogada válida

  /* ──────────────── Estados internos ──────────────── */
  final List<GameState> _history = [];
  bool _awaitingBombTarget = false;
  bool get isAwaitingBomb => _awaitingBombTarget;
// getters públicos
int get baseTiles => _baseTiles;
int get movesUsed => _movesUsed;

  /* ─────────────── Jogada normal ─────────────── */
  void playTurn(int newColor) {
    if (state.status != GameStatus.playing || _awaitingBombTarget) return;
    if (state.movesLeft == 0 || newColor == state.selectedColor) return;

    // território antes da jogada (para UI)
    final oldTerritory = _discoverTerritory(state.board, state.selectedColor);

    _pushHistory();

    // clone do tabuleiro
    final board = _cloneBoard(state.board);

    // pinta território existente
    _paintTerritory(board, state.selectedColor, newColor);

    // aplica padrões sem cascata infinita
    _applyPropagation(board, newColor);

    // checa vitória
    final firstColor = board[0][0].colorIndex;
    final won =
        board.every((row) => row.every((p) => p.colorIndex == firstColor));

    final movesLeft = state.movesLeft - 1;
    final lost = !won && movesLeft == 0;


// ➜ calcula quantos novos tiles entraram neste turno
final oldCount = _territorySize(state.board, state.selectedColor);
final newCount = _territorySize(board, newColor);
_baseTiles += (newCount - oldCount); // acumula
_movesUsed += 1;

    // calcula pontuação se venceu
    // ignore: no_leading_underscores_for_local_identifiers
    int _calcScore() {
      final seconds = DateTime.now().difference(state.startTime).inSeconds;
      final timeBonus = max(0, 600 - seconds); // 10 min → 0 bônus
      final blocks = board.length * board.first.length; // 81 em 9×9
      return movesLeft * 100 + timeBonus + blocks;
    }

    state = state.copyWith(
      board: board,
      movesLeft: movesLeft,
      selectedColor: newColor,
      status: won
          ? GameStatus.won
          : lost
              ? GameStatus.lost
              : GameStatus.playing,
      lastTerritory: oldTerritory,
      score: won ? _calcScore() : 0,
    );
  }


// utilitário local (mesma lógica do GamePage)
int _territorySize(List<List<Piece>> b, int colorIdx) {
  final visited = <Point<int>>{};
  final queue = <Point<int>>[const Point(0, 0)];
  while (queue.isNotEmpty) {
    final p = queue.removeLast();
    if (!visited.add(p)) continue;
    for (final d in kHexDirs) {
      final n = Point(p.x + d.x, p.y + d.y);
      if (n.x >= 0 && n.y >= 0 && n.x < b.first.length && n.y < b.length &&
          b[n.y][n.x].colorIndex == colorIdx && !visited.contains(n)) {
        queue.add(n);
      }
    }
  }
  return visited.length;
}

  /* ─────────────── Power-up Undo ─────────────── */
  void useUndo() {
    if (state.undosLeft == 0 || _history.isEmpty) return;
    final prev = _history.removeLast();
    state = prev.copyWith(
      undosLeft: state.undosLeft - 1,
      status: GameStatus.playing,
    );
  }

  /* ─────────────── Power-up Bomba ─────────────── */
  void toggleBombMode() {
    // cancela se já estava aguardando
    if (_awaitingBombTarget) {
      _awaitingBombTarget = false;
      state = state.copyWith(); // força rebuild
      return;
    }
    if (state.bombsLeft == 0 || state.status != GameStatus.playing) return;
    _awaitingBombTarget = true;
    state = state.copyWith(); // rebuild p/ UI
  }

  /// Chamado quando usuário toca num hex com bomba ativa
  void tapCell(int row, int col) {
    if (!_awaitingBombTarget) return;
    _pushHistory();

    final board = _cloneBoard(state.board);
    board[row][col] =
        board[row][col].copyWith(colorIndex: state.selectedColor);

    // absorve imediatamente (sem cascata)
    _applyPropagation(board, state.selectedColor);

    _awaitingBombTarget = false;
    state = state.copyWith(
      board: board,
      bombsLeft: state.bombsLeft - 1,
    );
  }

  /* ─────────────── Reset completo ─────────────── */
  void reset() {
    _history.clear();
    _awaitingBombTarget = false;
    _baseTiles = 1;
    _movesUsed = 0;

    state = GameState.initial();
  }

  /* ─────────────── Helpers internos ─────────────── */
  void _pushHistory() {
    _history.add(state.copyWith(board: _cloneBoard(state.board)));
    if (_history.length > 24) _history.removeAt(0);
  }

  /// Descobre território conectado a (0,0) na cor `color`.
  Set<Point<int>> _discoverTerritory(
      List<List<Piece>> b, int colorIndex) {
    final set = <Point<int>>{};
    final q = <Point<int>>[const Point(0, 0)];
    while (q.isNotEmpty) {
      final p = q.removeLast();
      if (!set.add(p)) continue;
      for (final d in kHexDirs) {
        final n = Point(p.x + d.x, p.y + d.y);
        if (_inBounds(n) &&
            !set.contains(n) &&
            b[n.y][n.x].colorIndex == colorIndex) {
          q.add(n);
        }
      }
    }
    return set;
  }

  void _paintTerritory(
      List<List<Piece>> board, int fromColor, int toColor) {
    final terr = _discoverTerritory(board, fromColor);
    for (final p in terr) {
      board[p.y][p.x] = board[p.y][p.x].copyWith(colorIndex: toColor);
    }
  }

  void _applyPropagation(List<List<Piece>> board, int newColor) {
    final territory = _discoverTerritory(board, newColor);
    final queue = List<Point<int>>.from(territory);
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      final piece = board[p.y][p.x];
      for (final off in piece.pattern.offsets) {
        final n = Point(p.x + off.x, p.y + off.y);
        if (_inBounds(n) &&
            !territory.contains(n) &&
            board[n.y][n.x].colorIndex == newColor) {
          territory.add(n);
          board[n.y][n.x] =
              board[n.y][n.x].copyWith(colorIndex: newColor);
          // sem cascata adicional — remove comentário se quiser
          // queue.add(n);
        }
      }
    }
  }

  bool _inBounds(Point<int> p) =>
      p.x >= 0 &&
      p.y >= 0 &&
      p.x < GameState.gridSize &&
      p.y < GameState.gridSize;

  List<List<Piece>> _cloneBoard(List<List<Piece>> src) =>
      [for (final row in src) [for (final piece in row) piece.copyWith()]];

}