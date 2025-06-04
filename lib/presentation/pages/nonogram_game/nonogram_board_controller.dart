import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controller for the Nonogram puzzle board.
///
/// Example JSON to load a puzzle:
/// ```json
/// {
///   "game": "nonogram",
///   "difficulty": "facil",
///   "board": {
///     "size": 5,
///     "solution": [
///       [1,0,1,1,0],
///       [0,1,1,0,1],
///       [1,1,1,0,0],
///       [0,0,1,1,1],
///       [1,0,0,1,0]
///     ]
///   }
/// }
/// ```
class NonogramBoardController extends GetxController {
  final RxInt size = 0.obs;
  RxBool isLoading = false.obs;
  late List<List<int>> solutionMatrix;
  final RxList<List<int>> currentMatrix = <List<int>>[].obs;

  List<int> rowCounts = [];
  List<int> colCounts = [];

  @override
  void onInit() {
    super.onInit();
    // Exemplo simples usado quando nenhum JSON é passado
    loadFromJson({
      'board': {
        'size': 5,
        'solution': [
          [1, 0, 1, 1, 0],
          [0, 1, 1, 0, 1],
          [1, 1, 1, 0, 0],
          [1, 1, 1, 1, 1],
          [1, 0, 1, 1, 0]
        ]
      }
    });
  }

  void loadFromJson(Map<String, dynamic> data) {
    final board = data['board'] as Map<String, dynamic>;
    size.value = board['size'] as int;
    solutionMatrix = [
      for (final row in board['solution'] as List)
        List<int>.from(row as List)
    ];
    currentMatrix.assignAll(
      List.generate(size.value, (_) => List.filled(size.value, 0)),
    );
    rowCounts = [
      for (final row in solutionMatrix)
        row.where((e) => e == 1).length
    ];
    colCounts = List.generate(
      size.value,
      (c) => solutionMatrix.fold(0, (p, r) => p + (r[c] == 1 ? 1 : 0)),
    );
  }

  void toggleTile(int row, int col) {
    isLoading.value = true;
    final newVal = currentMatrix[row][col] == 1 ? 0 : 1;
    currentMatrix[row][col] = newVal;
    currentMatrix.refresh();
    if (_checkCompletion()) {
      Get.dialog(
        AlertDialog(
          title: const Text('Parabéns!'),
          content: const Text('Você completou o puzzle!'),
          actions: [
            TextButton(onPressed: Get.back, child: const Text('OK')),
          ],
        ),
        barrierDismissible: false,
      );
    }
    isLoading.value = false;
  }

  bool _checkCompletion() {
    for (int i = 0; i < size.value; i++) {
      for (int j = 0; j < size.value; j++) {
        if (currentMatrix[i][j] != solutionMatrix[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  void resetBoard() {
    for (int i = 0; i < size.value; i++) {
      currentMatrix[i] = List<int>.filled(size.value, 0);
    }
    currentMatrix.refresh();
  }
}
