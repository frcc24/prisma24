import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'tango_board_controller.dart';

class TangoBoardPage extends GetView<TangBoardController> {
  TangoBoardPage({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Center(
            // Obedece a proporção NxN
            child: AspectRatio(
              aspectRatio: 1,
              child: GetBuilder<TangBoardController>(
                builder: (_) {
                  // Se sizeN não estiver inicializado, mostra um loader básico
                  if (controller.sizeN <= 0) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.sizeN * controller.sizeN,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: controller.sizeN,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      final row = index ~/ controller.sizeN;
                      final col = index % controller.sizeN;
                      final cellState = controller.currentMatrix[row][col];
                      final isPreFilled =
                          controller.initialMatrix[row][col] != 0;

                      return GestureDetector(
                        onTap: () => controller.cycleTile(row, col),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Imagem base do tile
                            // Image.asset(
                            //   'assets/images/tiles/tile_square_base.png',
                            //   fit: BoxFit.cover,
                            // ),
                            // Se cellState == 1, mostra lua
                            if (cellState == 1)
                              Center(
                                child: Image.asset(
                                  'assets/images/icons/icon_moon.png',
                                  width: 24,
                                  height: 24,
                                ),
                              )
                            // Se cellState == 2, mostra triângulo
                            else if (cellState == 2)
                              Center(
                                child: Image.asset(
                                  'assets/images/icons/icon_triangle_dot.png',
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            // Se for pré-preenchido, aplica leve sombreado
                            if (isPreFilled)
                              Container(
                                color: Colors.black.withOpacity(0.2),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
