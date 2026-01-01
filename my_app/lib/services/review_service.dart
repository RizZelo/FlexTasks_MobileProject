import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String reviewsCollection = 'reviews';
  final String usersCollection = 'users';

  Future<void> submitReview({
    required String revieweeId,
    required String revieweeName,
    required String revieweeRole,
    required String taskId,
    required String taskTitle,
    required int rating,
    required String comment,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    await _firestore.runTransaction((transaction) async {
      final reviewerRef = _firestore
          .collection(usersCollection)
          .doc(currentUser.uid);
      final revieweeRef = _firestore
          .collection(usersCollection)
          .doc(revieweeId);
      final reviewRef = _firestore.collection(reviewsCollection).doc();

      final reviewerSnapshot = await transaction.get(reviewerRef);
      final reviewerData =
          reviewerSnapshot.data() as Map<String, dynamic>? ?? {};

      final revieweeSnapshot = await transaction.get(revieweeRef);
      final revieweeData =
          revieweeSnapshot.data() as Map<String, dynamic>? ?? {};

      final reviewerName =
          reviewerData['name'] ?? currentUser.displayName ?? 'Unknown';
      final reviewerRole = reviewerData['role'] ?? 'student';

      transaction.set(reviewRef, {
        'reviewerId': currentUser.uid,
        'reviewerName': reviewerName,
        'reviewerRole': reviewerRole,
        'revieweeId': revieweeId,
        'revieweeName': revieweeName,
        'revieweeRole': revieweeRole,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final currentAvg =
          (revieweeData['ratingAverage'] ?? 0).toDouble() as double;
      final currentCount = (revieweeData['ratingCount'] ?? 0) as int;
      final newCount = currentCount + 1;
      final newAvg = ((currentAvg * currentCount) + rating) / newCount;

      transaction.update(revieweeRef, {
        'ratingAverage': newAvg,
        'ratingCount': newCount,
      });
    });
  }

  Stream<QuerySnapshot> getReviewsForUser(String userId) {
    return _firestore
        .collection(reviewsCollection)
        .where('revieweeId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
