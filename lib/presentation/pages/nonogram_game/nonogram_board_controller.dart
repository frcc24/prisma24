import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/progress_storage.dart';
import '../../../core/life_manager.dart';
import '../../../core/sfx.dart';
import '../../../core/leaderboard_service.dart';

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

  String backgroundPath = 'assets/images/ui/bg_gradient.png';

  String? currentMapId;
  int? currentPhaseIndex;

  /// Colors used for the tiles. [closedTileColor] is for state 0 and
  /// [selectedTileColor] for state 1.
  Color closedTileColor = Colors.grey.shade900;
  Color selectedTileColor = Colors.blueAccent;

  List<int> rowCounts = [];
  List<int> colCounts = [];

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
      _updateScore();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void stopTimer() => _stopTimer();

  void _updateScore() {
    final timePen = elapsedSeconds.value ~/ 2;
    final clickLimit = size.value * size.value;
    final clickPen = max(0, clicks.value - clickLimit) * 2;
    final hintPen = hintsUsed.value * 50;
    score.value = max(0, _baseScore - timePen - clickPen - hintPen);
    if (score.value <= 0) {
      _handleLoss();
    }
  }

  void _handleLoss() {
    Sfx().fail();
    _stopTimer();
    LifeManager().loseLife();
    Get.dialog(
      AlertDialog(
        title: Text('game_over'.tr),
        content: Text('score_zero_msg'.tr),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back();
            },
            child: Text('ok'.tr),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  final RxInt elapsedSeconds = 0.obs;
  final RxInt clicks = 0.obs;
  final RxInt hintsUsed = 0.obs;
  final RxInt score = 0.obs;
  Timer? _timer;
  int _baseScore = 0;

  final Random _random = Random();
  final RxList<List<bool>> revealedMatrix = <List<bool>>[].obs;

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
      for (final row in board['solution'] as List) List<int>.from(row as List)
    ];

    // Colors configuration
    final colorsField = board['colors'];
    if (colorsField is List && colorsField.isNotEmpty) {
      if (colorsField.length == 1) {
        selectedTileColor = _parseColor(colorsField[0]);
        closedTileColor = Colors.white.withValues(alpha: 0.1);
      } else {
        closedTileColor = _parseColor(colorsField[0]);
        selectedTileColor = _parseColor(colorsField[1]);
      }
    }

    // Setup revealed matrix
    revealedMatrix.assignAll(
      List.generate(size.value, (_) => List.filled(size.value, false)),
    );
    final initialField = board['initial'];
    if (initialField != null) {
      List<List<int>> init;
      if (initialField is String) {
        init = stringParaMatriz(initialField);
      } else {
        init = [
          for (final row in initialField as List) List<int>.from(row as List)
        ];
      }
      for (int i = 0; i < size.value; i++) {
        for (int j = 0; j < size.value; j++) {
          if (init[i][j] == 1) revealedMatrix[i][j] = true;
        }
      }
    } else {
      final total = size.value * size.value;
      int revealCount = max(1, (total * 0.1).round());
      final indices = List<int>.generate(total, (i) => i)..shuffle(_random);
      for (int k = 0; k < revealCount; k++) {
        final idx = indices[k];
        final r = idx ~/ size.value;
        final c = idx % size.value;
        revealedMatrix[r][c] = true;
      }
    }

    currentMatrix.assignAll(
      List.generate(size.value, (_) => List.filled(size.value, 0)),
    );
    rowCounts = [
      for (final row in solutionMatrix) row.where((e) => e == 1).length
    ];
    colCounts = List.generate(
      size.value,
      (c) => solutionMatrix.fold(0, (p, r) => p + (r[c] == 1 ? 1 : 0)),
    );
  }

  void toggleTile(int row, int col) {
    isLoading.value = true;
    Sfx().tap();
    if (revealedMatrix.isNotEmpty && revealedMatrix[row][col]) {
      isLoading.value = false;
      return;
    }
    final newVal = currentMatrix[row][col] == 1 ? 0 : 1;
    currentMatrix[row][col] = newVal;
    currentMatrix.refresh();
    clicks.value++;
    _updateScore();
    if (_checkCompletion()) {
      Sfx().win();
      _stopTimer();
      if (currentMapId != null && currentPhaseIndex != null) {
        ProgressStorage.getInstance().then(
            (p) => p.addCompletion(currentMapId!, currentPhaseIndex!));
        LeaderboardService()
            .savePhaseScore(currentMapId!, currentPhaseIndex!, score.value);
      }
      Get.dialog(
        AlertDialog(
          title: Text('congrats'.tr),
          content: Text('${'completed_puzzle'.tr}\nScore: ${score.value}'),
          actions: [
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: Text('ok'.tr),
            ),
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
    for (int i = 0; i < size.value; i++) {
      for (int j = 0; j < size.value; j++) {
        if (revealedMatrix.isNotEmpty && revealedMatrix[i][j]) {
          currentMatrix[i][j] = solutionMatrix[i][j];
        }
      }
    }
    currentMatrix.refresh();
    hintsUsed.value = 0;
    clicks.value = 0;
    elapsedSeconds.value = 0;
    _baseScore = size.value * size.value * 5;
    score.value = _baseScore;
    _stopTimer();
    _startTimer();
  }

  void revealHint() {
    isLoading.value = true;
    Sfx().tap();
    final List<List<int>> available = [];
    for (int i = 0; i < size.value; i++) {
      for (int j = 0; j < size.value; j++) {
        if (!revealedMatrix[i][j]) {
          available.add([i, j]);
        }
      }
    }
    if (available.isNotEmpty) {
      final choice = available[_random.nextInt(available.length)];
      final r = choice[0];
      final c = choice[1];
      revealedMatrix[r][c] = true;
      currentMatrix[r][c] = solutionMatrix[r][c];
      hintsUsed.value++;
      currentMatrix.refresh();
      revealedMatrix.refresh();
      _updateScore();
    }
    isLoading.value = false;
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
      final initialField = board['initial'];
      List<List<int>>? initial;
      if (initialField != null) {
        if (initialField is String) {
          initial = stringParaMatriz(initialField);
        } else {
          initial = [
            for (final row in initialField as List) List<int>.from(row as List)
          ];
        }
      }
      final colors = board['colors'];
      loadFromJson({
        'board': {
          'size': n,
          'solution': solution,
          'colors': colors,
          if (initial != null) 'initial': initial,
        }
      });
      resetBoard();
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _stopTimer();
    super.onClose();
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
