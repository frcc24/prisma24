import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreRepository {
  ScoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> savePrismScore(String name, int score) {
    return _firestore.collection('scores').add({
      'name': name,
      'score': score,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  Future<void> savePhaseScore(
    String mapId,
    int phaseIndex,
    String name,
    int score,
  ) async {
    final query = await _firestore
        .collection('phase_scores')
        .where('mapId', isEqualTo: mapId)
        .where('phase', isEqualTo: phaseIndex)
        .orderBy('score', descending: true)
        .get();

    final docs = query.docs;
    final shouldSave =
        docs.length < 5 || score > (docs.isNotEmpty ? docs.last['score'] as int : 0);

    if (shouldSave) {
      await _firestore.collection('phase_scores').add({
        'mapId': mapId,
        'phase': phaseIndex,
        'name': name,
        'score': score,
        'ts': FieldValue.serverTimestamp(),
      });

      if (docs.length >= 5) {
        await docs.last.reference.delete();
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> mapLeaders(String mapId) =>
      _firestore
          .collection('map_leaderboards')
          .where('mapId', isEqualTo: mapId)
          .orderBy('score', descending: true)
          .limit(5)
          .snapshots();

  Future<void> updateMapTotal(String mapId, String name, int score) {
    return _firestore
        .collection('map_leaderboards')
        .doc('$mapId-$name')
        .set({'mapId': mapId, 'name': name, 'score': score, 'ts': FieldValue.serverTimestamp()});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> phaseLeaders(
          String mapId, int phase) =>
      _firestore
          .collection('phase_scores')
          .where('mapId', isEqualTo: mapId)
          .where('phase', isEqualTo: phase)
          .orderBy('score', descending: true)
          .limit(5)
          .snapshots();
}
