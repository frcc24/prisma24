// lib/presentation/pages/game_page.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../../core/player_prefs.dart';
import 'package:get/get.dart';

import '../../../core/sfx.dart';
import '../../../core/life_manager.dart';
import '../../../domain/models/prism_game_models/game_state.dart';
import '../../providers/prism_game_provider/game_provider.dart';
import '../../widgets/prism_game_widgets/hex_board.dart';

/* ───────────────────────── TIMER PROVIDER ───────────────────────── */
/*  Emite segundos decorrido desde que a tela foi aberta. Ao sair, o  */
/*  autoDispose cancela o Stream.periodic automaticamente.            */
final elapsedProvider = StreamProvider.autoDispose<int>((ref) async* {
  final sw = Stopwatch()..start();
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    yield sw.elapsed.inSeconds;
  }
});

/* ───────────────────────── GAME PAGE ───────────────────────── */
class GamePage extends ConsumerWidget {
  const GamePage({super.key});

  Future<bool> _confirmExit(BuildContext context) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('exit_stage_q'.tr),
        content: Text('lose_life_msg'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('exit'.tr),
          ),
        ],
      ),
    );
    if (res == true) {
      LifeManager().loseLife();
      return true;
    }
    return false;
  }

  /* ───────── Ajuda ───────── */
  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('how_to_play'.tr,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('help_line1'.tr),
            Text('help_line2'.tr),
            Text('help_line3'.tr),
            Text('help_line4'.tr),
            Text('help_line5'.tr),
          ],
        ),
      ),
    );
  }

    Future<void> saveScore(String name, int score) =>
      FirebaseFirestore.instance
      .collection('scores')
      .add({'name': name, 'score': score, 'ts': FieldValue.serverTimestamp()});

  /* ───────── Diálogo de fim ───────── */

  void _showEndDialog(
      BuildContext context, WidgetRef ref, bool won, int elapsed) {
      if (!won) LifeManager().loseLife();
      final base   = ref.read(gameProvider.notifier).baseTiles;
      final moves  = ref.read(gameProvider.notifier).movesUsed;
      final bonus  = (10 * base / max(moves, 1)).floor();
      final pen    = elapsed ~/ 3;
      final total  = base + bonus - pen;

      getPlayerName().then((name) {
        if (won) {
          saveScore(name, total);
        }
      });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(won ? 'victory'.tr : 'game_over'.tr),
        content: Text(
          'Base: $base'
          '\nBônus eficiência: +$bonus'
          '\nPenalização tempo: −$pen'
          '\n-------------------------'
          '\nTOTAL: $total',
        ),

        actions: [
          TextButton(
            onPressed: () {
              ref.read(gameProvider.notifier).reset();
              // ignore: unused_result
              ref.refresh(elapsedProvider);
              Navigator.of(context).pop();
            },
            child: Text('new_game'.tr),
          ),
        ],
      ),
  );
  }

  /* ─────────────────────── Build ─────────────────────── */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /* escuta vitória / derrota */
    ref.listen(gameProvider, (prev, next) {
      if (next.status == GameStatus.won || next.status == GameStatus.lost) {
        final delay = next.status == GameStatus.won
            ? const Duration(seconds: 2)
            : const Duration(milliseconds: 1200);
        final elapsed = ref.read(elapsedProvider).value ?? 0;
        Future.delayed(delay,
            () => _showEndDialog(Get.context!, ref, next.status == GameStatus.won, elapsed));
      }
    });

    final game = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final elapsed = ref.watch(elapsedProvider).maybeWhen(
          data: (s) => _formatSeconds(s),
          orElse: () => '00:00',
        );

    /* calcula score: nº de peças do território */
  final base = controller.baseTiles;
  final bonus = (10 * base / max(controller.movesUsed, 1)).floor();
  final currentScore = base + bonus;   // sem penalidade de tempo ainda


    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit(context) && context.mounted) {
          Navigator.of(context).popUntil(
            ModalRoute.withName('/full_map'),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
        backgroundColor:
            controller.isAwaitingBomb ? Colors.orange.shade700 : Colors.transparent,
        elevation: 0,
        leadingWidth: 160,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                if (await _confirmExit(context) && context.mounted) {
                  Navigator.of(context).popUntil(
                    ModalRoute.withName('/full_map'),
                  );
                }
              },
            ),
            _UndoButton(
              remaining: game.undosLeft,
              onPressed: game.undosLeft == 0
                  ? null
                  : () {
                      controller.useUndo();
                      Sfx().tap();
                    },
            ),
            _ResetButton(
              onPressed: () {
                controller.reset();                 // zera estado do jogo
                // ignore: unused_result              
                ref.refresh(elapsedProvider);       // reinicia cronômetro
                Sfx().tap();                        // som
              },
            ),

          ],
        ),
        actions: [
          _BombButton(
            remaining: game.bombsLeft,
            awaiting: controller.isAwaitingBomb,
            onPressed: controller.toggleBombMode,
          ),
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home),
            onPressed: () async {
              if (await _confirmExit(context) && context.mounted) {
                Navigator.of(context).popUntil(
                  ModalRoute.withName('/full_map'),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'help'.tr,
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/ui/bg_gradient.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /* cabeçalho */
              Padding(
                padding: const EdgeInsets.only(top: 4.0, bottom: 2),
                child: Text(
                  'moves_left'.trArgs(['${game.movesLeft}']),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text('time_score'.trParams({'elapsed': elapsed, 'score': '$currentScore'}),
                  style: Theme.of(context).textTheme.bodyMedium),
              if (controller.isAwaitingBomb)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'bomb_prompt'.tr,
                    style: const TextStyle(color: Colors.orangeAccent),
                  ),
                ),
              const SizedBox(height: 4),
              /* tabuleiro */
              Expanded(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      HexBoard(
                        board: game.board,
                        onCellTap: controller.isAwaitingBomb
                            ? (r, c) => controller.tapCell(r, c)
                            : null,
                      ),
                      if (game.status == GameStatus.won)
                        Lottie.asset('assets/animations/confetti_win.json',
                            repeat: false),
                      if (game.status == GameStatus.lost)
                        Lottie.asset('assets/animations/fail_shake.json',
                            repeat: false),
                    ],
                  ),
                ),
              ),
              /* paleta */
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (int i = 0; i < kBoardPalette.length; i++)
                      GestureDetector(
                        onTap: () => controller.playTurn(i),
                        child: _ColorDot(
                          color: kBoardPalette[i],
                          selected: i == game.selectedColor,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }

  /* ───────── helpers ───────── */
  static String _formatSeconds(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

}

/* ───────────────── Botões auxiliares ───────────────── */
class _UndoButton extends StatelessWidget {
  final int remaining;
  final VoidCallback? onPressed;
  const _UndoButton({required this.remaining, required this.onPressed});
  @override
  Widget build(BuildContext context) => _stackedIcon(
        icon: Icons.undo,
        tooltip: 'undo'.trArgs(['$remaining']),
        value: remaining,
        colorBadge: remaining == 0 ? Colors.grey : Colors.orangeAccent,
        onPressed: onPressed,
      );
}

class _ResetButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ResetButton({required this.onPressed});
  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'restart'.tr,
        icon: const Icon(Icons.refresh),
        onPressed: onPressed,
      );
}

class _BombButton extends StatelessWidget {
  final int remaining;
  final bool awaiting;
  final VoidCallback onPressed;
  const _BombButton(
      {required this.remaining, required this.awaiting, required this.onPressed});
  @override
  Widget build(BuildContext context) => _stackedIcon(
        icon: Icons.whatshot,
        tooltip: awaiting
            ? 'cancel_bomb'.tr
            : remaining > 0
                ? 'bomb'.trArgs(['$remaining'])
                : 'no_bombs'.tr,
        value: remaining,
        colorBadge: remaining == 0 ? Colors.grey : Colors.redAccent,
        iconColor: awaiting ? Colors.yellow : null,
        onPressed: remaining > 0 || awaiting ? onPressed : null,
      );
}

/* ────── fábrica para ícones com badge ────── */
Widget _stackedIcon({
  required IconData icon,
  required String tooltip,
  required int value,
  required Color colorBadge,
  Color? iconColor,
  VoidCallback? onPressed,
}) {
  return Stack(
    alignment: Alignment.topRight,
    children: [
      IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
      ),
      Positioned(
        right: 6,
        top: 6,
        child: CircleAvatar(
          radius: 9,
          backgroundColor: colorBadge,
          child: Text('$value',
              style: const TextStyle(fontSize: 11, color: Colors.black)),
        ),
      ),
    ],
  );
}

/* ──────────────────── Bolinha da paleta ──────────────────── */
class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  const _ColorDot({required this.color, required this.selected});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: selected ? 46 : 40,
      height: selected ? 46 : 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          if (selected) const BoxShadow(blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}
