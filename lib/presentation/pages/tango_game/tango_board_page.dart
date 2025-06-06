// tango_board_page.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/life_manager.dart';
import '../../../core/sfx.dart';
import 'tango_board_controller.dart';

class TangoBoardPage extends GetView<TangoBoardController> {
  const TangoBoardPage({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('exit_stage_q'.tr),
        content: Text('lose_life_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('exit'.tr),
          ),
        ],
      ),
    );
    if (res == true) {
      controller.stopTimer();
      LifeManager().loseLife();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit(context) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('tango_puzzle'.tr),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              controller.resetBoard();
              Sfx().tap();
            },
            tooltip: 'restart'.tr,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(controller.backgroundPath),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            SizedBox(height: 16),
            Obx( () {
               final remaining = controller.hints.where((h) => h.hidden).length;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.lightbulb, color: Colors.white),
                      
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800],
                        foregroundColor: Colors.white,
                      ),
                      onPressed: remaining > 0
                          ? () {
                              controller.revealHint();
                              Sfx().tap();
                            }
                          : null, // desabilita se não há mais dicas
                    ),
                    const SizedBox(width: 8),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor:
                            remaining > 0 ? Colors.blueAccent : Colors.grey[800],
                        child: Text(
                          '$remaining',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                );
            }),

            Obx(() {
              final secs = controller.elapsedSeconds.value;
              final m = (secs ~/ 60).toString().padLeft(2, '0');
              final s = (secs % 60).toString().padLeft(2, '0');
              final sc = controller.score.value;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'time_score'
                      .trParams({'elapsed': '$m:$s', 'score': '$sc'}),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Obx(() {
                    final n = controller.sizeN.value;
                    if (n <= 0) {
                      return const Center(child: CircularProgressIndicator());
                }

                if(controller.isLoading.value) {
                 
                }

                // Espaçamento entre tiles
                const double spacing = 4.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Cálculo do tamanho de cada tile (largura = altura)
                    final double totalSpacing = (n - 1) * spacing;
                    final double tileSize =
                        (constraints.maxWidth - totalSpacing) / n;

                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(controller.backgroundPath),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                        // 1) Grid de tiles
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: n * n,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: n,
                            childAspectRatio: 1,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                          ),
                          itemBuilder: (context, index) {
                            final row = index ~/ n;
                            final col = index % n;

                            final cellState =
                                controller.currentMatrix[row][col];
                            final isPreFilled =
                                controller.initialMatrix[row][col] != 0;

                            return GestureDetector(
                              onTap: () => controller.cycleTile(row, col),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  final rotateAnim = Tween(begin: math.pi, end: 0.0)
                                      .animate(animation);
                                  return AnimatedBuilder(
                                    animation: rotateAnim,
                                    child: child,
                                    builder: (context, widgetChild) {
                                      final isUnder = rotateAnim.value > math.pi / 2;
                                      final transform = Matrix4.identity()
                                        ..setEntry(3, 2, 0.002)
                                        ..rotateY(rotateAnim.value);
                                      return Transform(
                                        transform: transform,
                                        alignment: Alignment.center,
                                        child: isUnder
                                            ? const SizedBox.shrink()
                                            : widgetChild,
                                      );
                                    },
                                  );
                                },
                                layoutBuilder: (widget, list) =>
                                    Stack(children: [widget!, ...list]),
                                switchInCurve: Curves.easeInOut,
                                switchOutCurve: Curves.easeInOut,
                                child: _buildTileContent(
                                  key: ValueKey<int>(cellState * 1000 + row * n + col),
                                  cellState: cellState,
                                  isPreFilled: isPreFilled,
                                ),
                              ),
                            );
                          },
                        ),

                        // 2) Overlay de dicas (hints) — cada dica revelada vira um Positioned
                        ...controller.hints.where((h) => !h.hidden).map((h) {
                          // Calcula posição em pixels do canto superior esquerdo do tile (row, col)
                          final double xTile = h.col * (tileSize + spacing);
                          final double yTile = h.row * (tileSize + spacing);

                          // Se há dica horizontal: posicionar entre (row,col) e (row,col+1)
                          if (h.isHorizontal) {
                            // Posição central entre os dois tiles:
                            // x_hint = xTile + tileSize + (spacing / 2)
                            // y_hint = yTile + (tileSize / 2)
                            final double xHint = xTile + tileSize + spacing / 2;
                            final double yHint = yTile + tileSize / 2;
                            return Positioned(
                              left: xHint - 12, // 12 = raio do circle (24/2)
                              top: yHint - 12,
                              child: _buildHintIcon(h),
                            );
                          } else {
                            // Dica vertical (entre (row,col) e (row+1,col))
                            // x_hint = xTile + tileSize / 2
                            // y_hint = yTile + tileSize + (spacing / 2)
                            final double xHint = xTile + tileSize / 2;
                            final double yHint = yTile + tileSize + spacing / 2;
                            return Positioned(
                              left: xHint - 12,
                              top: yHint - 12,
                              child: _buildHintIcon(h),
                            );
                          }
                        }),
                      ],
                    ),
                  );
                },
              );
                }),
              ),
            ),
          ),
        ],
      ),
    ),
      ),
      ),
    );
  }

  /// Retorna o widget de dica (círculo contendo "=" ou raio),
  /// com tamanho fixo de 24×24 px.
  Widget _buildHintIcon(Hint hint) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: hint.isEqual ? Colors.greenAccent.withAlpha(40) : Colors.redAccent.withAlpha(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: hint.isEqual
            ? Icon(
                Icons.check_circle, // símbolo de "igual"
                color: Colors.white,
                size: 9,
              )
            : const Icon(
                Icons.flash_on, // símbolo de "diferente"
                color: Colors.white,
                size: 9,
              ),
      ),
    );
  }

  /// Constrói o conteúdo “front” de cada tile (sem animação de dica),
  /// apenas com gradiente e ícones principais (lua/triângulo/preenchido).
  Widget _buildTileContent({
    required Key key,
    required int cellState,
    required bool isPreFilled,
  }) {
    return Container(
      key: key,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ícone principal de estado do tile
          if (cellState == 1)
            Center(
              child: Image.asset(
                'assets/images/icons/icon_moon.png',
                width: 42,
                height: 42,
                color: Colors.amberAccent,
                colorBlendMode: BlendMode.srcIn,
              ),
            )
          else if (cellState == 2)
            Center(
              child: Image.asset(
                'assets/images/icons/icon_triangle_dot.png',
                width: 42,
                height: 42,
                color: Colors.cyanAccent,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),

          // Overlay para células pré-preenchidas
          if (isPreFilled)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ),
        ],
      ),
    );
  }
}
