// lib/presentation/pages/leaderboard_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Página que exibe o TOP-100 de pontuações, em tempo real, via Firestore.
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  /// Stream ordenada (desc) por score, limitada a 100 documentos.
  Stream<QuerySnapshot<Map<String, dynamic>>> _top100Stream() =>
      FirebaseFirestore.instance
          .collection('scores')
          .orderBy('score', descending: true)
          .limit(100)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top 100 Jogadores'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _top100Stream(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Nenhuma pontuação ainda.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final name  = data['name']  ?? 'Jogador';
              final score = data['score'] ?? 0;
              return ListTile(
                leading: Text(
                  '#${i + 1}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                title: Text(name),
                trailing: Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
