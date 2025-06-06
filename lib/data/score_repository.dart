import 'package:cloud_firestore/cloud_firestore.dart';

class ScoreRepository {
  ScoreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _phaseCollection(
      String mapId, int phaseIndex) {
    return _firestore
        .collection('map_leaderboards')
        .doc('map$mapId')
        .collection('phase$phaseIndex');
  }

  Future<int> lowestTopScore(String mapId, int phaseIndex) async {
    final query = await _phaseCollection(mapId, phaseIndex)
        .orderBy('score', descending: true)
        .limit(3)
        .get();
    if (query.docs.length < 3) return 0;
    return query.docs.last['score'] as int;
  }

  Future<void> savePhaseScore(
    String mapId,
    int phaseIndex,
    String name,
    int score,
  ) async {
    final collection = _phaseCollection(mapId, phaseIndex);
    final query = await collection.orderBy('score', descending: true).get();
    final docs = query.docs;
    final shouldSave =
        docs.length < 3 || score > (docs.isNotEmpty ? docs.last['score'] as int : 0);

    if (shouldSave) {
      await collection.add({
        'name': name,
        'score': score,
        'ts': FieldValue.serverTimestamp(),
      });

      if (docs.length >= 3) {
        await docs.last.reference.delete();
      }
    }
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> phaseLeaders(
          String mapId, int phase) =>
      _phaseCollection(mapId, phase)
          .orderBy('score', descending: true)
          .limit(3)
          .snapshots();
}
