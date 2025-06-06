import 'package:cloud_firestore/cloud_firestore.dart';
import 'progress_storage.dart';
import 'player_prefs.dart';

class LeaderboardService {
  LeaderboardService._();
  static final LeaderboardService _instance = LeaderboardService._();
  factory LeaderboardService() => _instance;

  final _firestore = FirebaseFirestore.instance;

  Future<void> savePhaseScore(String mapId, int phaseIndex, int score) async {
    final name = await getPlayerName();
    await _firestore.collection('phase_scores').add({
      'mapId': mapId,
      'phase': phaseIndex,
      'name': name,
      'score': score,
      'ts': FieldValue.serverTimestamp(),
    });

    final storage = await ProgressStorage.getInstance();
    await storage.setHighScore(mapId, phaseIndex, score);
    final total = storage.getMapTotal(mapId);
    await _firestore
        .collection('map_leaderboards')
        .doc('$mapId-$name')
        .set({'mapId': mapId, 'name': name, 'score': total, 'ts': FieldValue.serverTimestamp()});
  }
}
