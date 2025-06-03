import 'dart:math';
import '../../../presentation/widgets/prism_game_widgets/hex_board.dart';

/// Seis direções principais para grade hexagonal (orientação pointy‑top)
/// usando coordenadas axiais (q, r).
const List<Point<int>> kHexDirs = [
  Point(1, 0),   // E
  Point(0, 1),   // SE
  Point(-1, 1),  // SW
  Point(-1, 0),  // W
  Point(0, -1),  // NW
  Point(1, -1),  // NE
];

/// Padrões de propagação.
enum PiecePattern {
  arrowE,
  arrowSE,
  arrowSW,
  cross,
  ring,
  diagX,
  dot,
}

extension PiecePatternX on PiecePattern {
  /// Offsets do padrão relativo à peça (sem incluir 0,0).
  List<Point<int>> get offsets {
    switch (this) {
      case PiecePattern.arrowE:
        return [kHexDirs[0]];
      case PiecePattern.arrowSE:
        return [kHexDirs[1]];
      case PiecePattern.arrowSW:
        return [kHexDirs[2]];
      case PiecePattern.cross:
        return [kHexDirs[0], kHexDirs[3], kHexDirs[1], kHexDirs[4]];
      case PiecePattern.ring:
        return List.unmodifiable(kHexDirs);
      case PiecePattern.diagX:
        return [kHexDirs[5], kHexDirs[2], kHexDirs[1], kHexDirs[4]];
      case PiecePattern.dot:
        return const [];
    }
  }

  /// Caminho do ícone correspondente nos assets.
  String get iconAsset {
    switch (this) {
      case PiecePattern.arrowE:
        return 'assets/images/icons/icon_arrow_right.png';
      case PiecePattern.arrowSE:
        return 'assets/images/icons/icon_arrow_diag_right.png';
      case PiecePattern.arrowSW:
        return 'assets/images/icons/icon_arrow_diag_left.png';
      case PiecePattern.cross:
        return 'assets/images/icons/icon_cross.png';
      case PiecePattern.ring:
        return 'assets/images/icons/icon_ring.png';
      case PiecePattern.diagX:
        return 'assets/images/icons/icon_x_diag.png';
      case PiecePattern.dot:
        return 'assets/images/icons/icon_dot.png';
    }
  }
}

/// Representa uma casa do tabuleiro.
class Piece {
  int colorIndex; // índice na kBoardPalette
  final PiecePattern pattern;

  Piece({required this.colorIndex, required this.pattern});

  /// Gera peça aleatória.
  factory Piece.random(Random rng) => Piece(
        colorIndex: rng.nextInt(kBoardPalette.length),
        pattern: PiecePattern.values[rng.nextInt(PiecePattern.values.length)],
      );

  Piece copyWith({int? colorIndex, PiecePattern? pattern}) => Piece(
        colorIndex: colorIndex ?? this.colorIndex,
        pattern: pattern ?? this.pattern,
      );
}
