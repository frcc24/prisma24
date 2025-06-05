import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'full_mode_map_page.dart';

class FullModePage extends StatelessWidget {
  const FullModePage({super.key});

  Future<List<Map<String, dynamic>>> _maps() async {
    final snap = await FirebaseFirestore.instance
        .collection('maps')
        .orderBy('createdAt')
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return {
        'id': d.id,
        'createdAt': (data['createdAt'] as Timestamp?)?.toDate(),
        'message': data['message'] ?? '',
        'theme': data['theme'] ?? '',
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha o mapa'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _maps(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final maps = snap.data!;
          if (maps.isEmpty) {
            return const Center(child: Text('Nenhum mapa disponível'));
          }
          return ListView.builder(
            itemCount: maps.length,
            itemBuilder: (context, i) {
              final map = maps[i];
              final id = map['id'] as String;
              final date = map['createdAt'] as DateTime?;
              final message = map['message'] as String?;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Mapa ${i + 1}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date != null
                          ? 'Criado em ${date.day}/${date.month}/${date.year}'
                          : 'Sem data'),
                      if (message != null && message.isNotEmpty)
                        Text(message),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullModeMapPage(mapId: id),
                      settings: const RouteSettings(name: '/full_map'),
                    ),
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
