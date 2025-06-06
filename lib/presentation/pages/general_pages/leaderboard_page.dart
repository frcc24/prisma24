import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show QuerySnapshot;
import 'package:get/get.dart';
import '../../../data/map_repository.dart';
import '../../../data/score_repository.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _maps() =>
      MapRepository().streamMaps();

  Stream<QuerySnapshot<Map<String, dynamic>>> _leaders(String mapId) =>
      ScoreRepository().mapLeaders(mapId);

  Stream<QuerySnapshot<Map<String, dynamic>>> _phases(String mapId) =>
      MapRepository().streamMapPhases(mapId);

  Stream<QuerySnapshot<Map<String, dynamic>>> _phaseLeaders(
          String mapId, int phase) =>
      ScoreRepository().phaseLeaders(mapId, phase);

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
                    if (snap2.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text(m.id),
                        subtitle: const LinearProgressIndicator(),
                      );
                    }
                    if (snap2.hasError) {
                      return ListTile(
                        title: Text(m.id),
                        subtitle: Text('error_loading'.tr),
                      );
                    }
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
                            if (phaseSnap.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: LinearProgressIndicator(),
                              );
                            }
                            final phases = phaseSnap.data?.docs ?? [];
                            return Column(
                              children: [
                                for (int p = 0; p < phases.length; p++)
                                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                    stream: _phaseLeaders(m.id, p),
                                    builder: (context, phaseScoreSnap) {
                                      if (phaseScoreSnap.connectionState == ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0),
                                          child: LinearProgressIndicator(),
                                        );
                                      }
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
