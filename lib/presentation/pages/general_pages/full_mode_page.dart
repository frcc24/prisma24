import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'full_mode_map_page.dart';

class FullModePage extends StatelessWidget {
  const FullModePage({super.key});

  Future<List<String>> _maps() async {
    final snap = await FirebaseFirestore.instance
        .collection('maps')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha o mapa'),
      ),
      body: FutureBuilder<List<String>>( 
        future: _maps(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final maps = snap.data!;
          if (maps.isEmpty) {
            return const Center(child: Text('Nenhum mapa disponível'));
          }
          return ListView.separated(
            itemCount: maps.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final id = maps[i];
              return ListTile(
                title: Text('Mapa ${i + 1}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullModeMapPage(mapId: id),
                    settings: const RouteSettings(name: '/full_map'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
