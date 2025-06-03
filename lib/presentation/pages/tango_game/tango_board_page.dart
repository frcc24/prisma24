// tango_board_page.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'tango_board_controller.dart';

class TangoBoardPage extends StatelessWidget {
  TangoBoardPage({Key? key}) : super(key: key);

  // Obtém o controller já registrado (ou registre antes de navegar para esta página)
  final TangoBoardController controller = Get.find<TangoBoardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tango Game Board'),
        centerTitle: true,
        backgroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reinicializa o tabuleiro
              controller.initBoard(
                controller.sizeN.value,
                controller.initialMatrix,
                controller.solutionMatrix,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              // Usa Obx para ouvir as reativas dentro do controller
              child: Obx(() {
                // 1) Ler o valor reativo sizeN
                final n = controller.sizeN.value;
                if (n <= 0) {
                  // Caso ainda não tenha sido inicializado
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (controller.isLoading.value) {
                  // Se estiver carregando, mostra indicador de progresso
                  //faz nada
                }

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: n * n,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: n,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ n;
                    final col = index % n;

                    // 2) Lê o estado atual da célula (tirando do RxList<RxList<int>>)
                    final cellState = controller.currentMatrix[row][col];
                    final isPreFilled = controller.initialMatrix[row][col] != 0;


return GestureDetector(
                      onTap: () => controller.cycleTile(row, col),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          // Gira em torno do eixo Y (flip horizontal)
                          final rotateAnim = Tween(begin: math.pi, end: 0.0)
                              .animate(animation);
                          return AnimatedBuilder(
                            animation: rotateAnim,
                            child: child,
                            builder: (context, widgetChild) {
                              // Quando o ângulo excede pi/2, inverta a face
                              final isUnder = (rotateAnim.value > math.pi / 2);
                              final transformValue = Matrix4.identity()
                                ..setEntry(3, 2, 0.002) // perspectiva
                                ..rotateY(rotateAnim.value);
                              return Transform(
                                transform: transformValue,
                                alignment: Alignment.center,
                                child: isUnder
                                    ? const SizedBox.shrink()
                                    : widgetChild,
                              );
                            },
                          );
                        },
                        layoutBuilder: (widget, list) => Stack(
                          children: [widget!, ...list],
                        ),
                        // A “key” faz o AnimatedSwitcher entender quando trocar de filho
                        child: _buildTileContent(
                          row: row,
                          col: col,
                          cellState: cellState,
                          isPreFilled: isPreFilled,
                          key: ValueKey<int>(cellState * 100 + row * n + col),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

 /// Constrói o conteúdo “estático” de cada tile, sem animações.
  Widget _buildTileContent({
    required int row,
    required int col,
    required int cellState,
    required bool isPreFilled,
    required Key key,
  }) {
    return Container(
      key: key,
      // Fundo com gradiente minimalista e cantos levemente arredondados
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF141414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ícone de acordo com o estado
          if (cellState == 1)
            Center(
              child: Image.asset(
                'assets/images/icons/icon_moon.png',
                width: 28,
                height: 28,
                color: Colors.amberAccent,
                colorBlendMode: BlendMode.srcIn,
              ),
            )
          else if (cellState == 2)
            Center(
              child: Image.asset(
                'assets/images/icons/icon_triangle_dot.png',
                width: 28,
                height: 28,
                color: Colors.cyanAccent,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),

          // Se for pré-preenchido, sombra extra
          if (isPreFilled)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.black.withOpacity(0.25),
              ),
            ),
        ],
      ),
    );
  }


  
}

