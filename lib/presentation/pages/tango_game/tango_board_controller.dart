import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TangBoardController extends GetxController {
  /// Dimensão do tabuleiro (NxN)
  int sizeN = 0;

  /// Matriz inicial (0=vazio, 1=moon, 2=triangle) enviada ao chamar initBoard
  late List<List<int>> initialMatrix;

  /// Matriz solução final (1=moon, 2=triangle)
  late List<List<int>> solutionMatrix;

  /// Matriz atual que o usuário vai preenchendo
  late List<List<int>> currentMatrix;

@override
  void onInit() {

    initBoard(
      4,
  [
    [1, 0, 2, 2],
    [1, 0, 1, 2],
    [2, 0, 2, 1],
    [2, 0, 1, 1],
  ],
  [
    [1, 1, 2, 2],
    [1, 2, 1, 2],
    [2, 1, 2, 1],
    [2, 2, 1, 1],
  ],
    );

    super.onInit();
  }



  void initBoard(
    int n,
    List<List<int>> initial,
    List<List<int>> solution,
  ) {
    sizeN = n;
    initialMatrix = initial;
    solutionMatrix = solution;

    // Cria uma cópia profunda de initialMatrix em currentMatrix
    currentMatrix = List.generate(
      sizeN,
      (i) => List<int>.from(initialMatrix[i]),
    );

    update(); // notifica GetBuilder/Obx para reconstruir UI
  }

  /// Retorna true se currentMatrix == solutionMatrix
  bool _checkCompletion() {
    for (int i = 0; i < sizeN; i++) {
      for (int j = 0; j < sizeN; j++) {
        if (currentMatrix[i][j] != solutionMatrix[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// Cicla o estado de uma célula do tabuleiro:
  /// 0 -> 1 (moon) -> 2 (triangle) -> 0
  void cycleTile(int row, int col) {
    // Se veio pré-preenchido, bloqueia alteração
    if (initialMatrix[row][col] != 0) return;

    currentMatrix[row][col] = (currentMatrix[row][col] + 1) % 3;
    update();

    if (_checkCompletion()) {
      // Se completou, exibe alerta via Get.dialog
      Get.dialog(
        AlertDialog(
          title: const Text('Parabéns!'),
          content: const Text('Você completou o puzzle!'),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // fecha o diálogo
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
