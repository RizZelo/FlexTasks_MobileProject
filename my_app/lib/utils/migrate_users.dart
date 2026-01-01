import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Fonction pour migrer les utilisateurs Firebase Auth existants vers Firestore
/// À appeler une seule fois pour créer les profils des utilisateurs existants
Future<void> migrateAuthUsersToFirestore() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      print('Aucun utilisateur connecté pour la migration');
      return;
    }

    final firestore = FirebaseFirestore.instance;
    
    // Vérifier si l'utilisateur existe déjà dans Firestore
    final userDoc = await firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    if (userDoc.exists) {
      print('Utilisateur ${currentUser.displayName} existe déjà dans Firestore');
      return;
    }
    
    // Créer le profil utilisateur
    await firestore.collection('users').doc(currentUser.uid).set({
      'uid': currentUser.uid,
      'name': currentUser.displayName ?? 'Utilisateur',
      'email': currentUser.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
    
    print('✅ Utilisateur ${currentUser.displayName} migré vers Firestore');
  } catch (e) {
    print('❌ Erreur lors de la migration: $e');
  }
}
