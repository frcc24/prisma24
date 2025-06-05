import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/progress_storage.dart';

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

  String? currentMapId;
  int? currentPhaseIndex;

  /// Colors used for the tiles. [closedTileColor] is for state 0 and
  /// [selectedTileColor] for state 1.
  Color closedTileColor = Colors.grey.shade900;
  Color selectedTileColor = Colors.blueAccent;

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
        ],
        'colors': ['#222222', 'blue']
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
    // Colors configuration
    final colorsField = board['colors'];
    if (colorsField is List && colorsField.isNotEmpty) {
      if (colorsField.length == 1) {
        selectedTileColor = _parseColor(colorsField[0]);
        closedTileColor = Colors.white.withOpacity(0.1);
      } else {
        closedTileColor = _parseColor(colorsField[0]);
        selectedTileColor = _parseColor(colorsField[1]);
      }
    }
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
      if (currentMapId != null && currentPhaseIndex != null) {
        ProgressStorage.getInstance().then(
            (p) => p.addCompletion(currentMapId!, currentPhaseIndex!));
      }
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

  /// Carrega uma fase armazenada no Firestore.
  Future<void> loadPhase(String mapId, int index) async {
    isLoading.value = true;
    currentMapId = mapId;
    currentPhaseIndex = index;
    try {
      final phases = await FirebaseFirestore.instance
          .collection('maps')
          .doc(mapId)
          .collection('phases')
          .orderBy('createdAt')
          .limit(index + 1)
          .get();

      if (phases.docs.length <= index) {
        isLoading.value = false;
        Get.snackbar('Erro', 'Fase nao implementada',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final data = phases.docs[index].data();
      final board = Map<String, dynamic>.from(data['board'] as Map);
      final n = board['size'] as int;
      final solutionField = board['solution'];
      List<List<int>> solution;
      if (solutionField is String) {
        solution = stringParaMatriz(solutionField);
      } else {
        solution = [
          for (final row in solutionField as List) List<int>.from(row as List)
        ];
      }
      final colors = board['colors'];
      loadFromJson({
        'board': {
          'size': n,
          'solution': solution,
          'colors': colors,
        }
      });
      resetBoard();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Color _parseColor(dynamic value) {
    if (value is int) return Color(value);
    if (value is String) {
      final v = value.toLowerCase();
      if (v.startsWith('#')) {
        final hex = v.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('0xFF$hex'));
        } else if (hex.length == 8) {
          return Color(int.parse('0x$hex'));
        }
      }
      if (v.startsWith('0x')) {
        return Color(int.parse(v));
      }
      const names = {
        'black': Colors.black,
        'white': Colors.white,
        'red': Colors.red,
        'green': Colors.green,
        'blue': Colors.blue,
        'yellow': Colors.yellow,
        'grey': Colors.grey,
        'gray': Colors.grey,
        'cyan': Colors.cyan,
        'magenta': Colors.pinkAccent,
        'purple': Colors.purple,
        'orange': Colors.orange,
        'pink': Colors.pink,
        'brown': Colors.brown,
        'teal': Colors.teal,
        'amber': Colors.amber,
      };
      return names[v] ?? Colors.blueAccent;
    }
    return Colors.blueAccent;
  }
}

List<List<int>> stringParaMatriz(String s) {
  final listaDinamica = jsonDecode(s) as List<dynamic>;
  return listaDinamica
      .map((linha) => List<int>.from(linha as List<dynamic>))
      .toList();
}
