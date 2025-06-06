import 'package:flutter/material.dart';

import 'outlined_text.dart';

class PhaseButton extends StatelessWidget {
  final int index;
  final bool completed;
  final String? assetPath;
  final VoidCallback onTap;
  const PhaseButton({
    super.key,
    required this.index,
    required this.completed,
    this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget button;
    if (assetPath != null) {
      button = Material(
        color: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black87,
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
                image: AssetImage(assetPath!),
                fit: BoxFit.cover,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(child: OutlinedText('${index + 1}')),
          ),
        ),
      );
    } else {
      button = Material(
        color: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black54,
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
            child: OutlinedText('${index + 1}'),
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
              child: const Icon(Icons.check, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}
