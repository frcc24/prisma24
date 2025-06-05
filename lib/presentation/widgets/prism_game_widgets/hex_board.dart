// lib/presentation/widgets/hex_board.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../domain/models/prism_game_models/piece.dart';

/// Cores do jogo
const List<Color> kBoardPalette = [
  Colors.red,
  Colors.orange,
  Color.fromARGB(255, 116, 108, 41),
  Colors.green,
  Colors.blue,
  Color.fromARGB(255, 38, 48, 103),
  Color.fromARGB(255, 103, 26, 116),
];

class HexBoard extends StatefulWidget {
  /// Tabuleiro de peças
  final List<List<Piece>> board;
  /// Território que pertencia ao jogador **antes** da jogada atual
  final Set<Point<int>> oldTerritory;
  /// Callback para toques (usado pela bomba)
  final void Function(int row, int col)? onCellTap;
  /// Mostra ou oculta ícones
  final bool showIcons;

  const HexBoard({
    super.key,
    required this.board,
    this.oldTerritory= const {},
    this.onCellTap,
    this.showIcons = true,
  });

  @override
  State<HexBoard> createState() => _HexBoardState();
}

class _HexBoardState extends State<HexBoard> {
  /// Peças que acabaram de mudar de cor (flash)
  final Set<Point<int>> _flash = {};
  List<List<Piece>>? _prev;

  @override
  void didUpdateWidget(covariant HexBoard old) {
    super.didUpdateWidget(old);
    if (_prev != widget.board) {
      _markFlash(old.board, widget.board);
      _prev = widget.board;
    }
  }

  void _markFlash(List<List<Piece>> oldB, List<List<Piece>> newB) {
    _flash.clear();
    for (int r = 0; r < newB.length; r++) {
      for (int c = 0; c < newB[r].length; c++) {
        if (oldB[r][c].colorIndex != newB[r][c].colorIndex) {
          _flash.add(Point(r, c));
        }
      }
    }
    if (_flash.isNotEmpty) {
      setState(() {});
      Timer(const Duration(milliseconds: 200), () {
        _flash.clear();
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(builder: (context, constraints) {
        final rows = widget.board.length;
        final cols = widget.board.first.length;
        const sqrt3 = 1.7320508075688772;

        // raio que cabe em largura e altura
        final rW = constraints.maxWidth / (cols * 1.5 + 0.5);
        final rH = constraints.maxHeight / (rows * sqrt3 + 0.5);
        final radius = min(rW, rH);

        final boardW = (cols * 1.5 + 0.5) * radius;
        final boardH = (rows * sqrt3 + 0.5) * radius;

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.onCellTap == null
                  ? null
                  : (d) => _handleHit(d.localPosition, radius),
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(boardW, boardH),
                    painter: _HexPainter(
                      board: widget.board,
                      radius: radius,
                      flash: _flash,
                      oldTerritory: widget.oldTerritory,
                    ),
                  ),
                  if (widget.showIcons)
                    ...[
                      for (int r = 0; r < rows; r++)
                        for (int c = 0; c < cols; c++)
                          Positioned(
                            left: _hexCenter(c, r, radius).dx - radius * 0.35,
                            top: _hexCenter(c, r, radius).dy - radius * 0.35,
                            width: radius * 0.7,
                            height: radius * 0.7,
                            child: Image.asset(
                              widget.board[r][c].pattern.iconAsset,
                              fit: BoxFit.contain,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                    ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  void _handleHit(Offset pos, double radius) {
    if (widget.onCellTap == null) return;
    final rows = widget.board.length;
    final cols = widget.board.first.length;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (_hexPath(_hexCenter(c, r, radius), radius).contains(pos)) {
          widget.onCellTap!(r, c);
          return;
        }
      }
    }
  }
}

/*──────────────────── Painter básico ───────────────────*/
class _HexPainter extends CustomPainter {
  final List<List<Piece>> board;
  final double radius;
  final Set<Point<int>> flash;
  final Set<Point<int>> oldTerritory;

  _HexPainter({
    required this.board,
    required this.radius,
    required this.flash,
    required this.oldTerritory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = board.length;
    final cols = board.first.length;

    final stroke = Paint()
      ..color = Colors.grey.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint();
    final borderOld = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final center = _hexCenter(c, r, radius);
        final path = _hexPath(center, radius);
        final piece = board[r][c];

        // cor de fundo
        fill.color = kBoardPalette[piece.colorIndex];
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);

        // contorno do território anterior
        if (oldTerritory.contains(Point(c, r))) {
          canvas.drawPath(path, borderOld);
        }

        // flash de peças recém-conquistadas
        if (flash.contains(Point(r, c))) {
          canvas.drawPath(
              path,
              Paint()
                ..color = Colors.white.withValues(alpha: 0.6)
                ..style = PaintingStyle.fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HexPainter old) =>
      old.board != board ||
      old.flash != flash ||
      old.oldTerritory != oldTerritory;
}

/*──────────── Helpers geométricos ───────────*/
Offset _hexCenter(int col, int row, double r) {
  final dx = r * (1.5 * col + 1);
  final dy =
      r * (1.7320508075688772 * row + (col.isOdd ? 0.86602540378 : 0) + 1);
  return Offset(dx, dy);
}

Path _hexPath(Offset center, double r) {
  final p = Path();
  for (int i = 0; i < 6; i++) {
    final ang = pi / 3 * i - pi / 6;
    final dx = center.dx + r * cos(ang);
    final dy = center.dy + r * sin(ang);
    if (i == 0) {
      p.moveTo(dx, dy);
    } else {
      p.lineTo(dx, dy);
    }
  }
  return p..close();
}
