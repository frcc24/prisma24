import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/phase_repository.dart';
import '../../../core/progress_storage.dart';
import '../../../core/life_manager.dart';
import '../../../core/sfx.dart';
import '../../../core/leaderboard_service.dart';
import '../../../utils/matrix_utils.dart';

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
  final PhaseRepository _repo = PhaseRepository();
  final RxInt size = 0.obs;
  RxBool isLoading = false.obs;
  late List<List<int>> solutionMatrix;
  final RxList<List<int>> currentMatrix = <List<int>>[].obs;

  String backgroundPath = 'assets/images/ui/bg_gradient.png';

  String? currentMapId;
  int? currentPhaseIndex;
  int leaderboardCutoff = 0;

  /// Colors used for the tiles. [closedTileColor] is for state 0 and
  /// [selectedTileColor] for state 1.
  Color closedTileColor = Colors.grey.shade900;
  Color selectedTileColor = Colors.blueAccent;

  /// Hints for each row/column as sequences of block sizes.
  List<List<int>> rowHints = [];
  List<List<int>> colHints = [];
  /// Indicates if the loaded puzzle has a unique solution.
  RxBool isUniqueSolution = false.obs;

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
    final timePen = (elapsedSeconds.value ~/ 2) * 10;
    final clickLimit = size.value * size.value;
    final clickPen = max(0, clicks.value - clickLimit) * 20;
    final hintPen = hintsUsed.value * 500;
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
  final RxList<List<bool>> hintMatrix = <List<bool>>[].obs;

  int get hintsRemaining {
    int count = 0;
    for (int i = 0; i < size.value; i++) {
      for (int j = 0; j < size.value; j++) {
        if (!revealedMatrix[i][j] &&
            currentMatrix[i][j] != solutionMatrix[i][j]) {
          count++;
        }
      }
    }
    return count;
  }

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
    hintMatrix.assignAll(
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

    rowHints = [
      for (final row in solutionMatrix) _blocksFromLine(row),
    ];
    colHints = List.generate(
      size.value,
      (c) => _blocksFromLine([
        for (final row in solutionMatrix) row[c]
      ]),
    );
    _updateImpossibleCells();
  }

  void toggleTile(int row, int col) {
    isLoading.value = true;
    Sfx().tap();
    if (revealedMatrix.isNotEmpty && revealedMatrix[row][col]) {
      isLoading.value = false;
      return;
    }
    final oldVal = currentMatrix[row][col];
    final newVal = (oldVal + 1) % 3;
    currentMatrix[row][col] = newVal;
    if (!_isRowValid(row) || !_isColValid(col)) {
      currentMatrix[row][col] = oldVal;
      isLoading.value = false;
      return;
    }
    currentMatrix.refresh();
    clicks.value++;
    _updateScore();
    _updateImpossibleCells();
    if (_checkCompletion()) {
      Sfx().win();
      _stopTimer();
      if (currentMapId != null && currentPhaseIndex != null) {
        ProgressStorage.getInstance().then(
            (p) => p.addCompletion(currentMapId!, currentPhaseIndex!));
        LeaderboardService().maybeSavePhaseScore(
            currentMapId!, currentPhaseIndex!, score.value, leaderboardCutoff);
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
        final cur = currentMatrix[i][j] == 2 ? 0 : currentMatrix[i][j];
        if (cur != solutionMatrix[i][j]) {
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
    hintMatrix.assignAll(
      List.generate(size.value, (_) => List.filled(size.value, false)),
    );
    currentMatrix.refresh();
    hintsUsed.value = 0;
    clicks.value = 0;
    elapsedSeconds.value = 0;
    _baseScore = 10000;
    score.value = _baseScore;
    _stopTimer();
    _startTimer();
    _updateImpossibleCells();
  }

  void revealHint() {
    isLoading.value = true;
    Sfx().tap();
    final List<List<int>> available = [];
    for (int i = 0; i < size.value; i++) {
      for (int j = 0; j < size.value; j++) {
        if (!revealedMatrix[i][j] &&
            currentMatrix[i][j] != solutionMatrix[i][j]) {
          available.add([i, j]);
        }
      }
    }
    final maxHints = size.value * size.value;
    if (available.isNotEmpty && hintsUsed.value < maxHints) {
      final choice = available[_random.nextInt(available.length)];
      final r = choice[0];
      final c = choice[1];
      revealedMatrix[r][c] = true;
      hintMatrix[r][c] = true;
      currentMatrix[r][c] = solutionMatrix[r][c];
      hintsUsed.value++;
      currentMatrix.refresh();
      revealedMatrix.refresh();
      hintMatrix.refresh();
      _updateScore();
      _updateImpossibleCells();
      if (_checkCompletion()) {
        Sfx().win();
        _stopTimer();
        if (currentMapId != null && currentPhaseIndex != null) {
          ProgressStorage.getInstance().then(
              (p) => p.addCompletion(currentMapId!, currentPhaseIndex!));
          LeaderboardService().maybeSavePhaseScore(
              currentMapId!, currentPhaseIndex!, score.value, leaderboardCutoff);
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
    }
    isLoading.value = false;
  }

  /// Carrega uma fase armazenada no Firestore.
  Future<void> loadPhase(String mapId, int index) async {
    isLoading.value = true;
    currentMapId = mapId;
    currentPhaseIndex = index;
    leaderboardCutoff = await LeaderboardService().getMinScore(mapId, index);
    try {
      final data = await _repo.fetchPhase(mapId, index);

      if (data == null) {
        isLoading.value = false;
        Get.snackbar('Erro', 'Fase nao implementada',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

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

  List<int> _blocksFromLine(List<int> line) {
    final List<int> blocks = [];
    int count = 0;
    for (final v in line) {
      if (v == 1) {
        count++;
      } else {
        if (count > 0) {
          blocks.add(count);
          count = 0;
        }
      }
    }
    if (count > 0) blocks.add(count);
    return blocks.isEmpty ? [0] : blocks;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<List<int>> _generatePatterns(int length, List<int> hints) {
    final List<List<int>> results = [];

    void place(List<int> partial, int hintIndex, int pos) {
      if (hintIndex == hints.length) {
        results.add([
          ...partial,
          ...List.filled(length - pos, 0),
        ]);
        return;
      }

      final hint = hints[hintIndex];
      final remaining = hints
              .sublist(hintIndex + 1)
              .fold(0, (p, e) => p + e) +
          (hints.length - hintIndex - 1);
      for (int start = pos; start <= length - hint - remaining; start++) {
        final prefixZeros = List.filled(start - pos, 0);
        final block = List.filled(hint, 1);
        final nextPos = start + hint;
        final newPartial = [...partial, ...prefixZeros, ...block];
        if (hintIndex < hints.length - 1) {
          if (nextPos < length) {
            place([...newPartial, 0], hintIndex + 1, nextPos + 1);
          }
        } else {
          place(newPartial, hintIndex + 1, nextPos);
        }
      }
    }

    place([], 0, 0);
    return results;
  }

  bool _columnsPrefixValid(List<List<int>> board, int lastRow) {
    final n = size.value;
    for (int c = 0; c < n; c++) {
      final hints = colHints[c];
      int hintIdx = 0;
      int runLen = 0;
      for (int r = 0; r <= lastRow; r++) {
        final val = board[r][c];
        if (val == 1) {
          if (hintIdx >= hints.length) return false;
          runLen++;
          if (runLen > hints[hintIdx]) return false;
        } else {
          if (runLen > 0) {
            if (runLen != hints[hintIdx]) return false;
            hintIdx++;
            runLen = 0;
          }
        }
      }
      if (runLen > hints[hintIdx.clamp(0, hints.length - 1)]) return false;
    }
    return true;
  }

  bool _columnsValidComplete(List<List<int>> board) {
    final n = size.value;
    for (int c = 0; c < n; c++) {
      final seq = _blocksFromLine([
        for (int r = 0; r < n; r++) board[r][c]
      ]);
      if (!_listEquals(seq, colHints[c])) return false;
    }
    return true;
  }

  List<List<List<int>>> _findAllSolutions({int limit = 2}) {
    final n = size.value;
    final options = <List<List<int>>>[];
    for (int r = 0; r < n; r++) {
      final rowOpts = <List<int>>[];
      for (final p in _generatePatterns(n, rowHints[r])) {
        bool ok = true;
        for (int c = 0; c < n; c++) {
          final cur = currentMatrix[r][c];
          if (cur == 1 && p[c] != 1) {
            ok = false;
            break;
          }
          if (cur == 2 && p[c] == 1) {
            ok = false;
            break;
          }
        }
        if (ok) rowOpts.add(p);
      }
      if (rowOpts.isEmpty) return [];
      options.add(rowOpts);
    }

    final board = List.generate(n, (_) => List<int>.filled(n, 0));
    final solutions = <List<List<int>>>[];

    void search(int row) {
      if (solutions.length >= limit) return;
      if (row == n) {
        if (_columnsValidComplete(board)) {
          solutions.add([
            for (final r in board) List<int>.from(r)
          ]);
        }
        return;
      }
      for (final pattern in options[row]) {
        board[row] = pattern;
        if (_columnsPrefixValid(board, row)) {
          search(row + 1);
        }
      }
    }

    search(0);
    return solutions;
  }

  void _updateImpossibleCells() {
    final sols = _findAllSolutions(limit: 2);
    isUniqueSolution.value = sols.length == 1;
    if (sols.isEmpty) return;
    final n = size.value;
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        if (currentMatrix[i][j] == 1) continue;
        bool canBe1 = false;
        for (final s in sols) {
          if (s[i][j] == 1) {
            canBe1 = true;
            break;
          }
        }
        if (!canBe1 && currentMatrix[i][j] == 0) {
          currentMatrix[i][j] = 2; // mark X
        }
      }
    }
    currentMatrix.refresh();
  }

  bool _isRowValid(int row) {
    final hints = rowHints[row];
    final line = [for (final v in currentMatrix[row]) v == 1 ? 1 : 0];
    final seq = _blocksFromLine(line);
    if (seq.length > hints.length) return false;
    for (int i = 0; i < seq.length; i++) {
      if (seq[i] > hints[i]) return false;
    }
    return true;
  }

  bool _isColValid(int col) {
    final hints = colHints[col];
    final line = [for (int r = 0; r < size.value; r++) currentMatrix[r][col] == 1 ? 1 : 0];
    final seq = _blocksFromLine(line);
    if (seq.length > hints.length) return false;
    for (int i = 0; i < seq.length; i++) {
      if (seq[i] > hints[i]) return false;
    }
    return true;
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
