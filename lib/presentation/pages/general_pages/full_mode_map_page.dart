import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import '../../../core/progress_storage.dart';
import '../../../core/life_manager.dart';
import '../tango_game/tango_board_controller.dart';
import '../nonogram_game/nonogram_board_controller.dart';
import '../../widgets/loading_dialog.dart';
import '../../widgets/lives_bar.dart';

class FullModeMapPage extends StatefulWidget {
  final String mapId;
  const FullModeMapPage({super.key, required this.mapId});

  @override
  State<FullModeMapPage> createState() => _FullModeMapPageState();
}

class _FullModeMapPageState extends State<FullModeMapPage> {
  List<int> _completed = [];
  late final List<Offset> _relativePoints;
  String? _nextMapId;

  @override
  void initState() {
    super.initState();
    _loadCompleted();
    _generatePoints();
    _checkNextMap();
  }

  Future<void> _loadCompleted() async {
    final storage = await ProgressStorage.getInstance();
    setState(() {
      _completed = storage.getCompleted(widget.mapId);
    });
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

  void _generatePoints() {
    final rnd = Random(widget.mapId.hashCode);
    _relativePoints = _basePoints
        .map((p) => Offset(
              (p.dx + rnd.nextDouble() * 0.1 - 0.05).clamp(0.05, 0.95),
              (p.dy + rnd.nextDouble() * 0.1 - 0.05).clamp(0.05, 0.95),
            ))
        .toList();
  }

  Future<void> _checkNextMap() async {
    final match = RegExp(r'(\d+)$').firstMatch(widget.mapId);
    if (match == null) return;
    final nextId = 'mapa${int.parse(match.group(1)!) + 1}';
    final doc = await FirebaseFirestore.instance
        .collection('maps')
        .doc(nextId)
        .get();
    if (doc.exists) {
      setState(() => _nextMapId = nextId);
    }
  }

  Future<int> _phaseCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('maps')
        .doc(widget.mapId)
        .collection('phases')
        .get();
    return snap.size;
  }

  Future<void> _openPhase(BuildContext context, int i) async {
    if (LifeManager().lives == 0) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sem vidas'),
          content: const Text('Você não tem mais vidas para jogar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () {
                LifeManager().fillLives();
                Navigator.pop(context);
              },
              child: const Text('Assistir anúncio'),
            ),
          ],
        ),
      );
      return;
    }
    bool closed = false;
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => LoadingDialog(onClose: () {
        closed = true;
        Navigator.of(context, rootNavigator: true).pop();
      }),
    );

      final phases = await FirebaseFirestore.instance
          .collection('maps')
          .doc(widget.mapId)
          .collection('phases')
          .orderBy('createdAt')
          .limit(i + 1)
          .get();
      if (!closed && phases.docs.length > i) {
        final data = phases.docs[i].data();
        final game = data['game'] as String? ?? 'tango';
        if (game == 'nonogram') {
          await Get.find<NonogramBoardController>().loadPhase(widget.mapId, i);
          Navigator.of(context, rootNavigator: true).pop(); //fechar o dialog
          await Navigator.pushNamed(context, '/nonogram');
        } else {
          await Get.find<TangoBoardController>().loadPhase(widget.mapId, i);
          Navigator.of(context, rootNavigator: true).pop(); //fechar o dialog
          await Navigator.pushNamed(context, '/tango');
        }
        _loadCompleted();
      } else if (!closed) {
        Get.snackbar('Erro', 'Fase nao implementada',
            snackPosition: SnackPosition.BOTTOM);
      }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/ui/bg_gradient.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<int>(
          future: _phaseCount(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final phaseCount = snap.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final points = _relativePoints
                    .map((p) => Offset(
                          p.dx * constraints.maxWidth,
                          p.dy * constraints.maxHeight,
                        ))
                    .toList();
                Offset? nextPoint;
                if (_nextMapId != null) {
                  nextPoint = Offset(
                    constraints.maxWidth * 0.9,
                    constraints.maxHeight * 0.9,
                  );
                  points.add(nextPoint);
                }
                return Stack(
                  children: [
                    const Positioned(
                      top: 120,
                      left: 8,
                      right: 8,
                      child: LivesBar(),
                    ),
                    CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: _PathPainter(points),
                    ),
                    for (int i = 0; i < _relativePoints.length; i++)
                      Positioned(
                        left: points[i].dx - 30,
                        top: points[i].dy - 30,
                        child: Stack(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: const CircleBorder(),
                                padding: const EdgeInsets.all(20),
                              ),
                              onPressed: i < phaseCount
                                  ? () => _openPhase(context, i)
                                  : null,
                              child: Text('${i + 1}'),
                            ),
                            if (_completed.contains(i))
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.green,
                                  child: const Icon(Icons.check,
                                      size: 12, color: Colors.white),
                                ),
                            ),
                          ],
                        ),
                      ),
                    if (nextPoint != null)
                      Positioned(
                        left: nextPoint.dx - 30,
                        top: nextPoint.dy - 30,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FullModeMapPage(mapId: _nextMapId!),
                              settings: const RouteSettings(name: '/full_map'),
                            ),
                          ),
                          child: const Icon(Icons.arrow_forward),
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
