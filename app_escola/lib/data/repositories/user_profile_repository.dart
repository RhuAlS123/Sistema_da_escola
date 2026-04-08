import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/domain.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Coleção `usuarios` — documento `{uid}` com `nome` e `role`.
  Stream<AppUserProfile?> watchProfile(String uid) {
    return _firestore.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return AppUserProfile.fromFirestoreMap(data);
    });
  }
}
