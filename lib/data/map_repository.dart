import 'package:cloud_firestore/cloud_firestore.dart';

class MapRepository {
  MapRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('maps');

  Future<DocumentSnapshot<Map<String, dynamic>>> getMap(String id) =>
      _collection.doc(id).get();

  Future<QuerySnapshot<Map<String, dynamic>>> fetchMaps() =>
      _collection.orderBy('createdAt').get();

  Future<QuerySnapshot<Map<String, dynamic>>> fetchPhases(
    String mapId, {
    int? limit,
  }) {
    var query = _collection.doc(mapId).collection('phases').orderBy('createdAt');
    if (limit != null) {
      query = query.limit(limit);
    }
    return query.get();
  }

  Future<bool> mapExists(String id) async {
    final doc = await _collection.doc(id).get();
    return doc.exists;
  }

  Future<int> phaseCount(String mapId) async {
    final snap = await _collection.doc(mapId).collection('phases').get();
    return snap.size;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMaps() =>
      _collection.orderBy('createdAt').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> streamMapPhases(String mapId) =>
      _collection.doc(mapId).collection('phases').orderBy('createdAt').snapshots();
}
