import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/life_manager.dart';
import '../../../core/progress_storage.dart';
import '../../../data/map_repository.dart';
import '../../../data/phase_repository.dart';
import '../../pages/nonogram_game/nonogram_board_controller.dart';
import '../../pages/tango_game/tango_board_controller.dart';
import '../../widgets/loading_dialog.dart';

class FullModeMapController extends GetxController {
  final String mapId;
  final MapRepository _mapRepo;
  final PhaseRepository _phaseRepo;
  FullModeMapController(this.mapId,
      {MapRepository? mapRepository, PhaseRepository? phaseRepository})
      : _mapRepo = mapRepository ?? MapRepository(),
        _phaseRepo = phaseRepository ?? PhaseRepository();

  final RxList<int> completed = <int>[].obs;
  late final List<Offset> relativePoints;
  final RxnString nextMapId = RxnString();
  final RxBool nextUnlocked = false.obs;
  final RxnString bgAsset = RxnString();
  final RxnString btnAsset = RxnString();
  final RxInt mapTotal = 0.obs;

  String get bgPath {
    final asset = bgAsset.value;
    if (asset == null) return 'assets/images/ui/bg_gradient.png';
    return asset.contains('/') ? asset : 'assets/images/ui/bgs/$asset';
  }

  String? get btnPath {
    final asset = btnAsset.value;
    if (asset == null) return null;
    return asset.contains('/') ? asset : 'assets/images/ui/buttons/$asset';
  }

  static const List<Offset> _basePoints = [
    Offset(0.1, 0.85),
    Offset(0.3, 0.70),
    Offset(0.15, 0.55),
    Offset(0.35, 0.40),
    Offset(0.20, 0.25),
    Offset(0.50, 0.20),
    Offset(0.70, 0.35),
    Offset(0.55, 0.55),
    Offset(0.75, 0.70),
    Offset(0.60, 0.85),
  ];

  @override
  void onInit() {
    super.onInit();
    _generatePoints();
    loadMapAssets();
    checkNextMap();
    loadCompleted();
  }

  void _generatePoints() {
    final rnd = Random(mapId.hashCode);
    relativePoints = _basePoints
        .map((p) => Offset(
              (p.dx + rnd.nextDouble() * 0.1 - 0.05).clamp(0.05, 0.95),
              (p.dy + rnd.nextDouble() * 0.1 - 0.05).clamp(0.05, 0.95),
            ))
        .toList();
  }

  Future<void> loadMapAssets() async {
    final doc = await _mapRepo.getMap(mapId);
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        bgAsset.value = data['bg'] as String?;
        btnAsset.value = data['btn'] as String?;
      }
    }
  }

  Future<void> checkNextMap() async {
    // Extract the trailing number of the current map identifier. The previous
    // regular expression expected a literal dollar sign at the end of the
    // string, which does not match ids like "mapa1". Using an end-of-string
    // anchor ensures we capture the digits correctly.
    final match = RegExp(r'(\d+)$').firstMatch(mapId);
    if (match == null) return;
    final nextId = 'mapa${int.parse(match.group(1)!) + 1}';
    final exists = await _mapRepo.mapExists(nextId);
    if (exists) {
      final storage = await ProgressStorage.getInstance();
      final unlocked =
          storage.isMapUnlocked(nextId) || storage.getCompleted(mapId).length >= 8;
      nextMapId.value = nextId;
      nextUnlocked.value = unlocked;
    }
  }

  Future<void> loadCompleted() async {
    final storage = await ProgressStorage.getInstance();
    final list = storage.getCompleted(mapId);
    completed.assignAll(list);
    mapTotal.value = storage.getMapTotal(mapId);
    final nextId = nextMapId.value;
    if (nextId != null) {
      nextUnlocked.value =
          storage.isMapUnlocked(nextId) || list.length >= 8;
    }
    await checkNextMap();
  }

  Future<int> phaseCount() async {
    return _mapRepo.phaseCount(mapId);
  }

  Future<void> openPhase(int index) async {
    if (LifeManager().lives == 0) {
      await Get.dialog(
        AlertDialog(
          title: Text('no_lives'.tr),
          content: Text('no_lives_msg'.tr),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                LifeManager().fillLives();
                Get.back();
              },
              child: Text('watch_ad'.tr),
            ),
          ],
        ),
      );
      return;
    }
    bool closed = false;
    Get.dialog(
      LoadingDialog(onClose: () {
        closed = true;
        Get.back();
      }),
      barrierDismissible: false,
      barrierColor: Colors.black54,
    );
    try {
      final data = await _phaseRepo.fetchPhase(mapId, index);
      if (!closed && data != null) {
        final game = data['game'] as String? ?? 'tango';
        if (game == 'nonogram') {
          final ctrl = Get.find<NonogramBoardController>();
          ctrl.backgroundPath = bgPath;
          await ctrl.loadPhase(mapId, index);
          if (!closed) Get.back();
          await Get.toNamed('/nonogram');
        } else {
          final ctrl = Get.find<TangoBoardController>();
          ctrl.backgroundPath = bgPath;
          await ctrl.loadPhase(mapId, index);
          if (!closed) Get.back();
          await Get.toNamed('/tango');
        }
        await loadCompleted();
      } else if (!closed) {
        Get.snackbar('error'.tr, 'phase_not_impl'.tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (!closed) Get.back();
    }
  }
}
