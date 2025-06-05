import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/life_manager.dart';
import '../../../core/sfx.dart';
import 'nonogram_board_controller.dart';

class NonogramBoard extends GetView<NonogramBoardController> {
  const NonogramBoard({super.key});

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
      controller.stopTimer();
      LifeManager().loseLife();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _confirmExit(context) && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('nonogram'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'restart'.tr,
            onPressed: () {
              controller.resetBoard();
              Sfx().tap();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/bg_gradient.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (controller.isLoading.value) {
                // return const CircularProgressIndicator();
              }

              final n = controller.size.value;
              if (n == 0) {
                return const CircularProgressIndicator();
              }

              final secs = controller.elapsedSeconds.value;
              final m = (secs ~/ 60).toString().padLeft(2, '0');
              final s = (secs % 60).toString().padLeft(2, '0');
              final sc = controller.score.value;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'time_score'.trParams({'elapsed': '$m:$s', 'score': '$sc'}),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final boardSize = math.min(constraints.maxWidth, constraints.maxHeight) - 24;
                        final tileSize = boardSize / n;
                        return Center(
                          child: SizedBox(
                            width: boardSize + 24,
                            height: boardSize + 24,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 24, height: 24),
                                    for (int c = 0; c < n; c++)
                                      SizedBox(
                                        width: tileSize,
                                        child: Center(
                                          child: Text(
                                            '${controller.colCounts[c]}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                for (int r = 0; r < n; r++)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 24,
                                        height: tileSize,
                                        child: Center(
                                          child: Text(
                                            '${controller.rowCounts[r]}',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      for (int c = 0; c < n; c++)
                                        SizedBox(
                                          width: tileSize,
                                          height: tileSize,
                                          child: _buildTile(r, c, controller.currentMatrix[r][c]),
                                        ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildTile(int row, int col, int state) {
    return GestureDetector(
      onTap: () => controller.toggleTile(row, col),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: math.pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, widgetChild) {
              final isUnder = rotate.value > math.pi / 2;
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(rotate.value);
              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: isUnder ? const SizedBox.shrink() : widgetChild,
              );
            },
          );
        },
        layoutBuilder: (widget, list) => Stack(children: [widget!, ...list]),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Container(
          key: ValueKey<int>(state),
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: state == 1
                ? controller.selectedTileColor
                : controller.closedTileColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
