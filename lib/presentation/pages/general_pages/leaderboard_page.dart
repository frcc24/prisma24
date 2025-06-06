import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show QuerySnapshot;
import 'package:get/get.dart';
import '../../../data/map_repository.dart';
import '../../../data/score_repository.dart';

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _maps() =>
      MapRepository().streamMaps();

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
            padding: const EdgeInsets.all(8),
            children: [
              for (final m in maps)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          _bgPath(m['bg'] as String?),
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            textTheme: const TextTheme(
                                bodyMedium: TextStyle(color: Colors.white))),
                        child: ExpansionTile(
                          title: Text(m.id),
                          children: [
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
                                        builder: (context, scoreSnap) {
                                          if (scoreSnap.connectionState == ConnectionState.waiting) {
                                            return const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 8.0),
                                              child: LinearProgressIndicator(),
                                            );
                                          }
                                          final docs = scoreSnap.data?.docs ?? [];
                                          return ExpansionTile(
                                            title: Text('phase'.trArgs(['${p + 1}'])),
                                            children: [
                                              for (int i = 0; i < docs.length; i++)
                                                ListTile(
                                                  leading: Text('#${i + 1}'),
                                                  title: Text(docs[i]['name']),
                                                  trailing: Text('${docs[i]['score']}'),
                                                ),
                                              if (docs.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Text('no_scores'.tr),
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
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _bgPath(String? theme) {
    if (theme == null || theme.isEmpty) return 'assets/images/ui/bg_gradient.png';
    return theme.contains('/') ? theme : 'assets/images/ui/bgs/$theme';
  }
}
