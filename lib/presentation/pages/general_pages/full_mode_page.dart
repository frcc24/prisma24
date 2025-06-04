import 'package:flutter/material.dart';

class FullModePage extends StatelessWidget {
  const FullModePage({super.key});

  static const List<Offset> _relativePoints = [
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final points = _relativePoints
                .map((p) => Offset(p.dx * constraints.maxWidth,
                    p.dy * constraints.maxHeight))
                .toList();
            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _PathPainter(points),
                ),
                for (int i = 0; i < points.length; i++)
                  Positioned(
                    left: points[i].dx - 30,
                    top: points[i].dy - 30,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(20),
                      ),
                      onPressed: () {},
                      child: Text('${i + 1}'),
                    ),
                  ),
              ],
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
