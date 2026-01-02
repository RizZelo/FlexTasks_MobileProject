import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConnectionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String connectionsCollection = 'connections';

  /// Create or update a connection between the current user and [targetUserId].
  ///
  /// For now, we treat a "connect" as an immediately accepted connection
  /// for both users (no separate approval screen implemented yet).
  Future<void> connectWithUser(String targetUserId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    if (user.uid == targetUserId) return;

    final ids = [user.uid, targetUserId]..sort();
    final connectionId = '${ids[0]}_${ids[1]}';

    await _firestore.collection(connectionsCollection).doc(connectionId).set({
      'userIds': ids,
      'requesterId': user.uid,
      'receiverId': targetUserId,
      'status': 'accepted',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Return the set of userIds that are in an accepted connection
  /// with the current user.
  Future<Set<String>> getAcceptedConnectionUserIds() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final snapshot = await _firestore
        .collection(connectionsCollection)
        .where('userIds', arrayContains: user.uid)
        .where('status', isEqualTo: 'accepted')
        .get();

    final connectedIds = <String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final List<dynamic> userIds = data['userIds'] ?? [];
      for (final id in userIds) {
        if (id is String && id != user.uid) {
          connectedIds.add(id);
        }
      }
    }

    return connectedIds;
  }
}
