import 'package:cloud_firestore/cloud_firestore.dart';

class PhaseRepository {
  PhaseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> fetchPhase(String mapId, int index) async {
    final snap = await _firestore
        .collection('maps')
        .doc(mapId)
        .collection('phases')
        .orderBy('createdAt')
        .limit(index + 1)
        .get();

    if (snap.docs.length > index) {
      return snap.docs[index].data();
    }
    return null;
  }
}
