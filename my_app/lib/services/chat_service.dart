import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection de messages
  final String messagesCollection = 'messages';
  final String chatsCollection = 'chats';

  // Envoyer un message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String content,
  }) async {
    try {
      final timestamp = DateTime.now();

      // Ajouter le message dans la sous-collection du chat
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .add({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'content': content,
        'timestamp': timestamp,
        'isRead': false,
      });

      // Mettre à jour les informations du chat
      await _firestore.collection(chatsCollection).doc(chatId).set({
        'participants': [senderId, receiverId],
        'participantNames': {
          senderId: senderName,
          receiverId: receiverName,
        },
        'lastMessage': content,
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  // Écouter les messages en temps réel pour un chat spécifique
  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection(chatsCollection)
        .doc(chatId)
        .collection(messagesCollection)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Obtenir la liste des conversations pour un utilisateur
  Stream<QuerySnapshot> getChats(String userId) {
    return _firestore
        .collection(chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Créer un ID de chat unique entre deux utilisateurs
  String getChatId(String userId1, String userId2) {
    // Trier les IDs pour avoir toujours le même chatId
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Marquer les messages comme lus
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messages = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in messages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Erreur lors du marquage des messages: $e');
    }
  }

  // Supprimer un message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .doc(messageId)
          .delete();

      // Mettre à jour le dernier message du chat si nécessaire
      final messages = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (messages.docs.isNotEmpty) {
        final lastMsg = messages.docs.first.data();
        await _firestore.collection(chatsCollection).doc(chatId).update({
          'lastMessage': lastMsg['content'],
          'lastMessageTime': lastMsg['timestamp'],
          'lastMessageSenderId': lastMsg['senderId'],
        });
      }
    } catch (e) {
      print('Erreur lors de la suppression du message: $e');
      rethrow;
    }
  }

  // Obtenir le nombre de messages non lus
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(chatsCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Erreur lors du comptage des messages non lus: $e');
      return 0;
    }
  }
}
