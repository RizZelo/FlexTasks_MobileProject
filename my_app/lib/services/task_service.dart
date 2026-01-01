import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection des tâches
  final String tasksCollection = 'tasks';

  // Créer une nouvelle tâche
  Future<String> createTask({
    required String title,
    required String description,
    required String category,
    required String budget,
    required String duration,
    required String location,
    required String startDate,
    String? additionalRequirements,
    bool backgroundCheckRequired = false,
    bool experienceRequired = false,
    bool referencesNeeded = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final docRef = await _firestore.collection(tasksCollection).add({
        'title': title,
        'description': description,
        'category': category,
        'budget': budget,
        'duration': duration,
        'location': location,
        'startDate': startDate,
        'additionalRequirements': additionalRequirements ?? '',
        'backgroundCheckRequired': backgroundCheckRequired,
        'experienceRequired': experienceRequired,
        'referencesNeeded': referencesNeeded,
        'clientId': user.uid,
        'clientName': user.displayName ?? 'Unknown',
        'clientEmail': user.email ?? '',
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'applicationsCount': 0,
      });

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la tâche: $e');
      rethrow;
    }
  }

  // Obtenir toutes les tâches actives (pour les étudiants)
  Stream<QuerySnapshot> getAllActiveTasks() {
    return _firestore
        .collection(tasksCollection)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir les tâches d'un client spécifique
  Stream<QuerySnapshot> getClientTasks(String clientId) {
    return _firestore
        .collection(tasksCollection)
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir les tâches de l'utilisateur actuel
  Stream<QuerySnapshot> getMyTasks() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection(tasksCollection)
        .where('clientId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir une tâche par ID
  Future<DocumentSnapshot> getTaskById(String taskId) async {
    return await _firestore.collection(tasksCollection).doc(taskId).get();
  }

  // Stream d'une tâche par ID
  Stream<DocumentSnapshot> getTaskStream(String taskId) {
    return _firestore.collection(tasksCollection).doc(taskId).snapshots();
  }

  // Mettre à jour une tâche
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? category,
    String? budget,
    String? duration,
    String? location,
    String? startDate,
    String? additionalRequirements,
    bool? backgroundCheckRequired,
    bool? experienceRequired,
    bool? referencesNeeded,
    String? status,
  }) async {
    try {
      Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (category != null) updates['category'] = category;
      if (budget != null) updates['budget'] = budget;
      if (duration != null) updates['duration'] = duration;
      if (location != null) updates['location'] = location;
      if (startDate != null) updates['startDate'] = startDate;
      if (additionalRequirements != null) {
        updates['additionalRequirements'] = additionalRequirements;
      }
      if (backgroundCheckRequired != null) {
        updates['backgroundCheckRequired'] = backgroundCheckRequired;
      }
      if (experienceRequired != null) {
        updates['experienceRequired'] = experienceRequired;
      }
      if (referencesNeeded != null) {
        updates['referencesNeeded'] = referencesNeeded;
      }
      if (status != null) updates['status'] = status;

      await _firestore.collection(tasksCollection).doc(taskId).update(updates);
    } catch (e) {
      print('Erreur lors de la mise à jour de la tâche: $e');
      rethrow;
    }
  }

  // Supprimer une tâche
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(tasksCollection).doc(taskId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la tâche: $e');
      rethrow;
    }
  }

  // Rechercher des tâches par catégorie
  Stream<QuerySnapshot> getTasksByCategory(String category) {
    return _firestore
        .collection(tasksCollection)
        .where('status', isEqualTo: 'active')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Incrémenter le compteur de candidatures
  Future<void> incrementApplicationsCount(String taskId) async {
    try {
      await _firestore.collection(tasksCollection).doc(taskId).update({
        'applicationsCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur lors de l\'incrémentation des candidatures: $e');
    }
  }
}
