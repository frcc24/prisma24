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
  String? _bgAsset;
  String? _btnAsset;

  String get _bgPath {
    if (_bgAsset == null) return 'assets/images/ui/bg_gradient.png';
    return _bgAsset!.contains('/')
        ? _bgAsset!
        : 'assets/images/ui/bgs/$_bgAsset';
  }

  String? get _btnPath {
    if (_btnAsset == null) return null;
    return _btnAsset!.contains('/')
        ? _btnAsset!
        : 'assets/images/ui/buttons/$_btnAsset';
  }

  Widget _outlinedText(String text, {double size = 18}) {
    return Stack(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Colors.black,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _outlinedIcon(IconData icon, {double size = 24}) {
    final code = String.fromCharCode(icon.codePoint);
    return Stack(
      children: [
        Text(
          code,
          style: TextStyle(
            fontSize: size,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = Colors.black,
          ),
        ),
        Text(
          code,
          style: TextStyle(
            fontSize: size,
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _phaseButton(BuildContext context, int i, int phaseCount) {
    final onTap = i < phaseCount ? () => _openPhase(context, i) : null;
    final completed = _completed.contains(i);
    final btnPath = _btnPath;
    Widget button;
    if (btnPath != null) {
      button = Material(
        elevation: 2,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(btnPath),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(child: _outlinedText('${i + 1}')),
          ),
        ),
      );
    } else {
      button = Material(
        elevation: 2,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            child: _outlinedText('${i + 1}'),
          ),
        ),
      );
    }

    return Stack(
      children: [
        button,
        if (completed)
          Positioned(
            bottom: 4,
            right: 4,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.green,
              child:
                  const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCompleted();
    _loadMapAssets();
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

  Future<void> _loadMapAssets() async {
    final doc = await FirebaseFirestore.instance
        .collection('maps')
        .doc(widget.mapId)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        setState(() {
          _bgAsset = data['bg'] as String?;
          _btnAsset = data['btn'] as String?;
        });
      }
    }
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
          title: Text('no_lives'.tr),
          content: Text('no_lives_msg'.tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr),
            ),
            TextButton(
              onPressed: () {
                LifeManager().fillLives();
                Navigator.pop(context);
              },
              child: Text('watch_ad'.tr),
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
      if (!closed && context.mounted && phases.docs.length > i) {
        final data = phases.docs[i].data();
        final game = data['game'] as String? ?? 'tango';
        if (game == 'nonogram') {
          await Get.find<NonogramBoardController>().loadPhase(widget.mapId, i);
          Navigator.of(Get.context!, rootNavigator: true).pop(); //fechar o dialog
          await Navigator.pushNamed(Get.context!, '/nonogram');
        } else {
          await Get.find<TangoBoardController>().loadPhase(widget.mapId, i);
          Navigator.of(Get.context!, rootNavigator: true).pop(); //fechar o dialog
          await Navigator.pushNamed(Get.context!, '/tango');
        }
        _loadCompleted();
      } else if (!closed) {
        Get.snackbar('error'.tr, 'phase_not_impl'.tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_bgPath),
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
                        child: _phaseButton(context, i, phaseCount),
                      ),
                    if (nextPoint != null)
                      Positioned(
                        left: nextPoint.dx - 30,
                        top: nextPoint.dy - 30,
                        child: Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FullModeMapPage(mapId: _nextMapId!),
                                settings: const RouteSettings(name: '/full_map'),
                              ),
                            ),
                            customBorder: const CircleBorder(),
                            child: Ink(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                image: _btnPath != null
                                    ? DecorationImage(
                                        image: AssetImage(_btnPath!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: _btnPath == null ? Colors.purple : null,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: _outlinedIcon(Icons.arrow_forward),
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
