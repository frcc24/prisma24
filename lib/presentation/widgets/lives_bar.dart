import 'package:flutter/material.dart';
import '../../core/life_manager.dart';

class LivesBar extends StatefulWidget {
  const LivesBar({super.key});

  @override
  State<LivesBar> createState() => _LivesBarState();
}

class _LivesBarState extends State<LivesBar> {
  final manager = LifeManager();

  @override
  void initState() {
    super.initState();
    manager.addListener(_update);
  }

  @override
  void dispose() {
    manager.removeListener(_update);
    super.dispose();
  }

  void _update() => setState(() {});

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.favorite, color: Colors.redAccent),
        const SizedBox(width: 4),
        Text('${manager.lives}'),
        if (!manager.isFull) ...[
          const SizedBox(width: 16),
          const Icon(Icons.timer, size: 18),
          const SizedBox(width: 4),
          Text(_format(manager.timeLeft)),
        ],
      ],
    );
  }
}
