// tango_board_controller.dart

import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/phase_repository.dart';
import '../../../core/progress_storage.dart';
import '../../../core/life_manager.dart';
import '../../../core/sfx.dart';
import '../../../core/leaderboard_service.dart';
import '../../../utils/matrix_utils.dart';

class TangoBoardController extends GetxController {
  final PhaseRepository _repo = PhaseRepository();
  /// Dimensão do tabuleiro (NxN)
  final RxInt sizeN = 0.obs;

  final isLoading = false.obs;

  /// Matriz inicial (0=vazio, 1=moon, 2=triangle) enviada ao chamar initBoard
  late List<List<int>> initialMatrix;

  /// Matriz solução final (1=moon, 2=triangle)
  late List<List<int>> solutionMatrix;

  /// Matriz atual que o usuário vai preenchendo
  // ignore: unintended_html_in_doc_comment
  /// Cada elemento de currentMatrix é uma List<int> simples, mas o "container" é reativo (RxList).
  final RxList<List<int>> currentMatrix = <List<int>>[].obs;

  /// Lista de dicas (hints). Cada Hint tem um row,col, direção (horizontal/vertical),
  /// se a dica é “iguais” ou “diferentes” e se já foi revelada (hidden=false).
  final RxList<Hint> hints = <Hint>[].obs;

  final Random _random = Random();

  final RxInt elapsedSeconds = 0.obs;
  final RxInt clicks = 0.obs;
  final RxInt hintsUsed = 0.obs;
  final RxInt score = 0.obs;
  Timer? _timer;
  int _baseScore = 0;

  String backgroundPath = 'assets/images/ui/bg_gradient.png';

  String? currentMapId;
  int? currentPhaseIndex;
  int leaderboardCutoff = 0;

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
    final clickLimit = sizeN.value * sizeN.value;
    final clickPen = max(0, clicks.value - clickLimit) * 20;
    final hintPen = hintsUsed.value * 500;
    score.value = max(0, _baseScore - timePen - clickPen - hintPen);
    if (score.value <= 0) {
      _handleLoss();
    }
  }

  void _handleLoss() {
    Sfx().fail();
    if (_timer != null) {
      _stopTimer();
    }
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
    // Gera as dicas a partir da solução
    _generateHints();

    // As dicas começam todas ocultas (hidden=true)
    hints.refresh();
    // Não precisa chamar update(), pois usamos Obx() para ouvir currentMatrix e sizeN automaticamente.
  }


  /// Gera uma lista de Hint aleatórias (com base na solução). 
  /// Cada Hint compara dois tiles vizinhos (horizontal ou vertical).
  /// Se os valores na solutionMatrix forem iguais => isEqual = true; 
  /// caso contrário, isEqual = false.
  /// Apenas escolhe algumas dicas (porcentagem ou quantidade fixa).
  void _generateHints() {
    hints.clear();

    final int n = sizeN.value;
    // Para cada posição possível, podemos comparar com o tile à direita (se existir)
    // e com o tile abaixo (se existir). Mas pegaremos apenas um subconjunto aleatório.
    // Construímos primeiro todas as possíveis dicas:
    List<Hint> todasPossiveis = [];

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < n; j++) {
        // Se houver tile à direita
        if (j + 1 < n) {
          // Apenas adiciona a dica se pelo menos um dos dois tiles
          // não veio pré-preenchido na matriz inicial
          if (initialMatrix[i][j] == 0 || initialMatrix[i][j + 1] == 0) {
            bool eq = (solutionMatrix[i][j] == solutionMatrix[i][j + 1]);
            todasPossiveis.add(Hint(
              row: i,
              col: j,
              isHorizontal: true,
              isEqual: eq,
              hidden: true,
            ));
          }
        }
        // Se houver tile abaixo
        if (i + 1 < n) {
          // Apenas adiciona a dica se ao menos um dos dois tiles
          // não veio pré-preenchido na matriz inicial
          if (initialMatrix[i][j] == 0 || initialMatrix[i + 1][j] == 0) {
            bool eq = (solutionMatrix[i][j] == solutionMatrix[i + 1][j]);
            todasPossiveis.add(Hint(
              row: i,
              col: j,
              isHorizontal: false,
              isEqual: eq,
              hidden: true,
            ));
          }
        }
      }
    }

    // Agora selecionamos um número X de dicas para exibir (de forma aleatória).
    // Atualmente utilizamos 100% das dicas possíveis, mas revelaremos
    // apenas uma parte ao iniciar o tabuleiro.
    int quantidadeParaRevelar = (todasPossiveis.length * 1).round();
    quantidadeParaRevelar = max(quantidadeParaRevelar, 1); // no mínimo 1 dica

    // Embaralha a lista para sortear as dicas a mostrar e também as que
    // já começarão visíveis.
    todasPossiveis.shuffle(_random);

    // Define quantas dicas serão visíveis inicialmente (20% do total gerado).
    int jaVisiveis = (quantidadeParaRevelar * 0.2).round();
    if (jaVisiveis == 0 && quantidadeParaRevelar > 0) {
      jaVisiveis = 1;
    }

    // Pega os N primeiros e marca os primeiros "jaVisiveis" como não ocultos.
    for (int k = 0; k < quantidadeParaRevelar; k++) {
      final hint = todasPossiveis[k];
      if (k < jaVisiveis) {
        hint.hidden = false;
      }
      hints.add(hint);
    }

    // As demais dicas permanecem ocultas até o jogador solicitá-las
  }

/// Revela a próxima dica oculta (outra, aleatória entre as que ainda não foram mostradas).
  /// Se não houver mais dicas para revelar, não faz nada.
  void revealHint() {
    isLoading.value = true;
    Sfx().tap();
    // Filtra apenas as dicas que ainda estão ocultas
    final ocultas = hints.where((h) => h.hidden).toList();
    if (ocultas.isEmpty) return;

    // Escolhe uma aleatoriamente
    final idx = _random.nextInt(ocultas.length);
    ocultas[idx].hidden = false;
    hintsUsed.value++;
    _updateScore();

    // Como modificamos um Hint dentro de hints, precisamos chamar refresh() para atualizar a UI
    hints.refresh();
    isLoading.value = false;
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
    Sfx().tap();
    // 1) Se veio pré-preenchido, bloqueia alteração
    if (initialMatrix[row][col] != 0) return;

    isLoading.value = false;

    // 2) Calcula novo valor (0,1,2)
    int novoValor = (currentMatrix[row][col] + 1) % 3;

    // 3) Atribui diretamente na lista interna
    currentMatrix[row][col] = novoValor;
    clicks.value++;
    _updateScore();

    // 4) Para que Obx saiba que a matriz inteira mudou, chamamos refresh() no RxList
    currentMatrix.refresh();

    // 5) Se terminado, exibe o diálogo
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
          content:
              Text('${'completed_puzzle'.tr}\nScore: ${score.value}'),
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
  /// No TangoBoardController:
void resetBoard() {
    isLoading.value = true;

    // 1) Redefine currentMatrix como cópia profunda de initialMatrix
    currentMatrix.clear();
    for (var row in initialMatrix) {
      currentMatrix.add(List<int>.from(row));
    }
    currentMatrix.refresh();

    // 2) Gera novamente as dicas para que 20% já fiquem visíveis
    _generateHints();
    hints.refresh();

    clicks.value = 0;
    hintsUsed.value = 0;
    elapsedSeconds.value = 0;
    _baseScore = 10000;
    score.value = _baseScore;
    _stopTimer();
    _startTimer();

    isLoading.value = false;
}

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
      final initial = stringParaMatriz(board['initial']);
      final solution = stringParaMatriz(board['solution']);
      initBoard(n, initial, solution);
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

}



/// Classe que representa uma dica (hint) sobre dois tiles vizinhos.
/// row, col = posição (linha/coluna) do tile onde será exibido o ícone da dica.
/// Se isHorizontal = true, significa que a dica compara o tile (row,col) com (row, col+1).
/// Caso contrário, compara com o tile (row+1, col).
/// isEqual = true se a dica for “=” (iguais), false se for “≠” (diferentes).
/// hidden = true enquanto não for revelada; quando o jogador pedir dica, hidden = false.
class Hint {
  final int row;
  final int col;
  final bool isHorizontal;
  final bool isEqual;
  bool hidden;

  Hint({
    required this.row,
    required this.col,
    required this.isHorizontal,
    required this.isEqual,
    this.hidden = true,
  });
}

