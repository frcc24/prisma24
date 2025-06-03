// tango_board_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TangoBoardController extends GetxController {
  /// Dimensão do tabuleiro (NxN)
  final RxInt sizeN = 0.obs;

  final isLoading = false.obs;

  /// Matriz inicial (0=vazio, 1=moon, 2=triangle) enviada ao chamar initBoard
  late List<List<int>> initialMatrix;

  /// Matriz solução final (1=moon, 2=triangle)
  late List<List<int>> solutionMatrix;

  /// Matriz atual que o usuário vai preenchendo
  /// Cada elemento de currentMatrix é uma List<int> simples, mas o "container" é reativo (RxList).
  final RxList<List<int>> currentMatrix = <List<int>>[].obs;

  @override
  void onInit() {
    super.onInit();

    // Se quiser testar sem parâmetros externos, pode inicializar aqui:
    // initBoard(
    //   4,
    //   [
    //     [1, 0, 2, 0],
    //     [1, 0, 1, 0],
    //     [2, 0, 0, 1],
    //     [2, 0, 0, 1],
    //   ],
    //   [
    //     [1, 1, 2, 2],
    //     [1, 2, 1, 2],
    //     [2, 1, 2, 1],
    //     [2, 2, 1, 1],
    //   ],
    // );

    initBoard(6, 
      // Puzzle 4
  [
    [1, 2, 1, 1, 2, 2],
    [2, 1, 0, 2, 1, 2],
    [1, 1, 2, 1, 2, 1],
    [1, 2, 1, 0, 1, 2],
    [2, 1, 2, 1, 0, 1],
    [2, 2, 1, 2, 1, 0],
  ],
    // Puzzle 4
  [
    [1, 2, 1, 1, 2, 2],
    [2, 1, 2, 2, 1, 2],
    [1, 1, 2, 1, 2, 1],
    [1, 2, 1, 2, 1, 2],
    [2, 1, 2, 1, 2, 1],
    [2, 2, 1, 2, 1, 1],
  ], 
    
    );
  }

  /// Inicializa o tabuleiro com:
  /// - n: tamanho NxN
  /// - initial: matriz pré-preenchida (0 = vazio, 1 = moon, 2 = triangle)
  /// - solution: matriz solução completa (1 ou 2 em todas as posições)
  void initBoard(int n, List<List<int>> initial, List<List<int>> solution) {
    // 1) Define o tamanho
    sizeN.value = n;

    // 2) Armazena as matrizes recebidas
    initialMatrix = initial;
    solutionMatrix = solution;

    // 3) Cria currentMatrix como cópia profunda de initialMatrix, mas cada linha é uma List<int> normal.
    currentMatrix.clear();
    for (var row in initialMatrix) {
      currentMatrix.add(List<int>.from(row));
    }
    // Agora currentMatrix é um RxList<List<int>> contendo linhas mutáveis.

    // Não precisa chamar update(), pois usamos Obx() para ouvir currentMatrix e sizeN automaticamente.
  }

  /// Verifica se a state atual bate com a matrix solução
  bool _checkCompletion() {
    for (int i = 0; i < sizeN.value; i++) {
      for (int j = 0; j < sizeN.value; j++) {
        if (currentMatrix[i][j] != solutionMatrix[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  /// Cicla o estado de uma célula: 0 -> 1 -> 2 -> 0
  void cycleTile(int row, int col) {
    isLoading.value = true;
    // 1) Se veio pré-preenchido, bloqueia alteração
    if (initialMatrix[row][col] != 0) return;

    isLoading.value = false;

    // 2) Calcula novo valor (0,1,2)
    int novoValor = (currentMatrix[row][col] + 1) % 3;

    // 3) Atribui diretamente na lista interna
    currentMatrix[row][col] = novoValor;

    // 4) Para que Obx saiba que a matriz inteira mudou, chamamos refresh() no RxList
    currentMatrix.refresh();

    // 5) Se terminado, exibe o diálogo
    if (_checkCompletion()) {
      Get.dialog(
        AlertDialog(
          title: const Text('Parabéns!'),
          content: const Text('Você completou o puzzle!'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }
}
