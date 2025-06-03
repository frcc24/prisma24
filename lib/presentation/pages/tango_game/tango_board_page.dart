// tango_board_page.dart

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
                  return const Center(child: CircularProgressIndicator());
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Imagem base do tile (sempre desenhada)
                          Image.asset(
                            'assets/images/tiles/tile_square_base.png',
                            fit: BoxFit.cover, 
                            color: Colors.white.withOpacity(0.1),
                            colorBlendMode: BlendMode.modulate,                         
                          ),

                          // Se estiver marcado com “1” (lua), mostra ícone da lua
                          if (cellState == 1)
                            Center(
                              child: Image.asset(
                                'assets/images/icons/icon_moon.png',
                                width: 24,
                                height: 24,
                                color: Colors.red,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            )
                          // Se estiver marcado com “2” (triângulo), mostra triângulo
                          else if (cellState == 2)
                            Center(
                              child: Image.asset(
                                'assets/images/icons/icon_triangle_dot.png',
                                width: 24,
                                height: 24,
                                color: Colors.blue,
                                colorBlendMode: BlendMode.srcIn,
                              ),
                            ),

                          // Se for pré-preenchido (initialMatrix != 0), aplica um overlay semitransparente
                          if (isPreFilled)
                            Container(
                              color: Colors.black.withOpacity(0.2),
                            ),
                        ],
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
}
