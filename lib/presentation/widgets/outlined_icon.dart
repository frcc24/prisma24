import 'package:flutter/material.dart';

class OutlinedIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  const OutlinedIcon(this.icon, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
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
}
