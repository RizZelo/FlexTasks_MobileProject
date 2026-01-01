import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_service.dart';

class ApplicationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TaskService _taskService = TaskService();

  // Collection des candidatures
  final String applicationsCollection = 'applications';

  // Soumettre une candidature
  Future<String> submitApplication({
    required String taskId,
    required String taskTitle,
    required String clientId,
    required String clientName,
    required String coverLetter,
    required String expectedBudget,
    required String availability,
    String? experience,
    String? skills,
    String? portfolio,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Vérifier si l'utilisateur a déjà postulé
      final existingApplication = await _firestore
          .collection(applicationsCollection)
          .where('taskId', isEqualTo: taskId)
          .where('applicantId', isEqualTo: user.uid)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        throw Exception('Vous avez déjà postulé à cette tâche');
      }

      final docRef = await _firestore.collection(applicationsCollection).add({
        'taskId': taskId,
        'taskTitle': taskTitle,
        'clientId': clientId,
        'clientName': clientName,
        'applicantId': user.uid,
        'applicantName': user.displayName ?? 'Unknown',
        'applicantEmail': user.email ?? '',
        'coverLetter': coverLetter,
        'expectedBudget': expectedBudget,
        'availability': availability,
        'experience': experience ?? '',
        'skills': skills ?? '',
        'portfolio': portfolio ?? '',
        'status': 'pending', // pending, accepted, rejected
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Incrémenter le compteur de candidatures sur la tâche
      await _taskService.incrementApplicationsCount(taskId);

      return docRef.id;
    } catch (e) {
      print('Erreur lors de la soumission de la candidature: $e');
      rethrow;
    }
  }

  // Obtenir les candidatures d'un étudiant
  Stream<QuerySnapshot> getMyApplications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection(applicationsCollection)
        .where('applicantId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir les candidatures pour une tâche (pour le client)
  Stream<QuerySnapshot> getApplicationsForTask(String taskId) {
    return _firestore
        .collection(applicationsCollection)
        .where('taskId', isEqualTo: taskId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir toutes les candidatures reçues par un client
  Stream<QuerySnapshot> getReceivedApplications() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection(applicationsCollection)
        .where('clientId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtenir une candidature par ID
  Future<DocumentSnapshot> getApplicationById(String applicationId) async {
    return await _firestore
        .collection(applicationsCollection)
        .doc(applicationId)
        .get();
  }

  // Mettre à jour le statut d'une candidature
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection(applicationsCollection)
          .doc(applicationId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      rethrow;
    }
  }

  // Accepter une candidature
  Future<void> acceptApplication(String applicationId) async {
    await updateApplicationStatus(
      applicationId: applicationId,
      status: 'accepted',
    );
  }

  // Rejeter une candidature
  Future<void> rejectApplication(String applicationId) async {
    await updateApplicationStatus(
      applicationId: applicationId,
      status: 'rejected',
    );
  }

  // Supprimer une candidature
  Future<void> deleteApplication(String applicationId) async {
    try {
      await _firestore
          .collection(applicationsCollection)
          .doc(applicationId)
          .delete();
    } catch (e) {
      print('Erreur lors de la suppression de la candidature: $e');
      rethrow;
    }
  }

  // Vérifier si l'utilisateur a déjà postulé à une tâche
  Future<bool> hasApplied(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final existingApplication = await _firestore
        .collection(applicationsCollection)
        .where('taskId', isEqualTo: taskId)
        .where('applicantId', isEqualTo: user.uid)
        .get();

    return existingApplication.docs.isNotEmpty;
  }
}
