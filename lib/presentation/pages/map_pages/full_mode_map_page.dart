import 'package:flutter/material.dart';
import 'package:get/get.dart';

import "../../../core/progress_storage.dart";
import '../../controllers/map_pages/full_mode_map_controller.dart';
import '../../widgets/lives_bar.dart';
import '../../widgets/phase_button.dart';
import '../../widgets/outlined_icon.dart';
import '../../bindings/full_mode_map_binding.dart';

class FullModeMapPage extends GetView<FullModeMapController> {
  final String mapId;
  @override
  final String? tag;
  const FullModeMapPage({super.key, required this.mapId}) : tag = mapId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black54,
          elevation: 0,
          centerTitle: true,
          title: Text('${controller.mapTotal.value}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Get.until(
              (route) => route.settings.name == '/full',
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: LivesBar(),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(controller.bgPath),
              fit: BoxFit.cover,
            ),
          ),
          child: FutureBuilder<int>(
            future: controller.phaseCount(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return LayoutBuilder(
                builder: (context, constraints) {
                  final points = controller.relativePoints
                      .map((p) => Offset(
                            p.dx * constraints.maxWidth,
                            p.dy * constraints.maxHeight,
                          ))
                      .toList();
                  Offset? nextPoint;
                  if (controller.nextMapId.value != null) {
                    nextPoint = Offset(
                      constraints.maxWidth * 0.9,
                      constraints.maxHeight * 0.9,
                    );
                    points.add(nextPoint);
                  }
                  return Stack(
                    children: [
                      CustomPaint(
                        size:
                            Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _PathPainter(points),
                      ),
                      for (int i = 0; i < controller.relativePoints.length; i++)
                        Positioned(
                          left: points[i].dx - 30,
                          top: points[i].dy - 30,
                          child: PhaseButton(
                            index: i,
                            completed: controller.completed.contains(i),
                            assetPath: controller.btnPath,
                            onTap: () => controller.openPhase(i),
                          ),
                        ),
                      if (nextPoint != null)
                        Positioned(
                          left: nextPoint.dx - 30,
                          top: nextPoint.dy - 30,
                          child: Material(
                            color: Colors.transparent,
                            elevation: 4,
                            shadowColor: Colors.black87,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () async {
                                if (controller.nextUnlocked.value) {
                                  final id = controller.nextMapId.value!;
                                  await Get.to(
                                    () => FullModeMapPage(mapId: id),
                                    binding: FullModeMapBinding(id),
                                    routeName: '/full_map',
                                  );
                                } else {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: Text('unlock_map_q'.tr),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: Text('cancel'.tr),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: Text('watch_ad'.tr),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true &&
                                      controller.nextMapId.value != null) {
                                    final storage =
                                        await ProgressStorage.getInstance();
                                    await storage
                                        .unlockMap(controller.nextMapId.value!);
                                    controller.nextUnlocked.value = true;
                                    Get.snackbar('Ok', 'unlocked'.tr,
                                        snackPosition: SnackPosition.BOTTOM);
                                  }
                                }
                              },
                              customBorder: const CircleBorder(),
                              child: Ink(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  image: controller.btnPath != null
                                      ? DecorationImage(
                                          image:
                                              AssetImage(controller.btnPath!),
                                          fit: BoxFit.cover,
                                          colorFilter: !controller
                                                  .nextUnlocked.value
                                              ? const ColorFilter.mode(
                                                  Colors.black45,
                                                  BlendMode.srcATop,
                                                )
                                              : null,
                                        )
                                      : null,
                                  color: controller.btnPath == null
                                      ? Colors.purple.withValues(alpha:
                                          controller.nextUnlocked.value ? 1 : 0.4)
                                      : null,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: controller.nextUnlocked.value
                                      ? const OutlinedIcon(Icons.arrow_forward)
                                      : const OutlinedIcon(Icons.lock),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    });
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  _PathPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
