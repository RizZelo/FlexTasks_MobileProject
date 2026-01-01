import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection des utilisateurs
  final String usersCollection = 'users';

  // Créer ou mettre à jour le profil utilisateur dans Firestore
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String email,
    required String role, // 'client' or 'student'
  }) async {
    try {
      await _firestore.collection(usersCollection).doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
        'isOnline': true,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la création du profil: $e');
      rethrow;
    }
  }

  // Obtenir le rôle de l'utilisateur actuel
  Future<String?> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(usersCollection)
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      return null;
    }
  }

  // Mettre à jour le statut en ligne
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection(usersCollection).doc(user.uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
    }
  }

  // Obtenir tous les utilisateurs sauf l'utilisateur actuel
  Stream<QuerySnapshot> getUsers() {
    final currentUserId = _auth.currentUser?.uid;

    return _firestore
        .collection(usersCollection)
        .where('uid', isNotEqualTo: currentUserId)
        .orderBy('uid')
        .snapshots();
  }

  // Obtenir un utilisateur spécifique
  Future<DocumentSnapshot> getUserById(String uid) async {
    return await _firestore.collection(usersCollection).doc(uid).get();
  }

  // Rechercher des utilisateurs par nom
  Stream<QuerySnapshot> searchUsers(String searchTerm) {
    final currentUserId = _auth.currentUser?.uid;

    return _firestore
        .collection(usersCollection)
        .where('uid', isNotEqualTo: currentUserId)
        .orderBy('uid')
        .snapshots();
  }

  // Obtenir les informations de l'utilisateur actuel
  Stream<DocumentSnapshot> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Aucun utilisateur connecté');
    }

    return _firestore.collection(usersCollection).doc(user.uid).snapshots();
  }
}
