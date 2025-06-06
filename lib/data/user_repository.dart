import 'package:cloud_firestore/cloud_firestore.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> registerUser(String name) async {
    final users = _firestore.collection('users');
    final query = await users.where('name', isEqualTo: name).limit(1).get();
    if (query.docs.isEmpty) {
      await users.add({'name': name, 'ts': FieldValue.serverTimestamp()});
    }
  }
}
