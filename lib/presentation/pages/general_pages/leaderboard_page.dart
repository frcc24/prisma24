import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _maps() => FirebaseFirestore.instance
      .collection('maps')
      .orderBy('createdAt')
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _leaders(String mapId) =>
      FirebaseFirestore.instance
          .collection('map_leaderboards')
          .where('mapId', isEqualTo: mapId)
          .orderBy('score', descending: true)
          .limit(5)
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _phases(String mapId) =>
      FirebaseFirestore.instance
          .collection('maps')
          .doc(mapId)
          .collection('phases')
          .orderBy('createdAt')
          .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> _phaseLeaders(
          String mapId, int phase) =>
      FirebaseFirestore.instance
          .collection('phase_scores')
          .where('mapId', isEqualTo: mapId)
          .where('phase', isEqualTo: phase)
          .orderBy('score', descending: true)
          .limit(5)
          .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('leaderboards'.tr)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _maps(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final maps = snap.data!.docs;
          if (maps.isEmpty) {
            return Center(child: Text('no_maps'.tr));
          }
          return ListView(
            children: [
              for (final m in maps)
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _leaders(m.id),
                  builder: (context, snap2) {
                    final docs = snap2.data?.docs ?? [];
                    final first = docs.isNotEmpty ? docs.first.data() : null;
                    return ExpansionTile(
                      title: Text(m.id),
                      subtitle: first != null
                          ? Text('${first['name']} - ${first['score']}')
                          : Text('no_scores'.tr),
                      children: [
                        for (int i = 1; i < docs.length; i++)
                          ListTile(
                            leading: Text('#${i + 1}'),
                            title: Text(docs[i]['name']),
                            trailing: Text('${docs[i]['score']}'),
                          ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _phases(m.id),
                          builder: (context, phaseSnap) {
                            final phases = phaseSnap.data?.docs ?? [];
                            return Column(
                              children: [
                                for (int p = 0; p < phases.length; p++)
                                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _phaseLeaders(m.id, p),
                                    builder: (context, phaseScoreSnap) {
                                      final pDocs = phaseScoreSnap.data?.docs ?? [];
                                      final pf = pDocs.isNotEmpty ? pDocs.first.data() : null;
                                      return ExpansionTile(
                                        title: Text('phase'.trArgs(['${p + 1}'])),
                                        subtitle: pf != null
                                            ? Text('${pf['name']} - ${pf['score']}')
                                            : Text('no_scores'.tr),
                                        children: [
                                          for (int j = 1; j < pDocs.length; j++)
                                            ListTile(
                                              leading: Text('#${j + 1}'),
                                              title: Text(pDocs[j]['name']),
                                              trailing: Text('${pDocs[j]['score']}'),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
