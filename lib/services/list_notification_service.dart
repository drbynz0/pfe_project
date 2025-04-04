import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? currentUserId;

    Future<void> _getCurrentUserId() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
          currentUserId = userSnapshot.docs.first.id;
      }
    }
  }

  /// 🔍 Récupérer les notifications de l'utilisateur (messages non lus)
  Stream<List<Map<String, dynamic>>> getUserNotifications() {
    _getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('Users')
        .doc(currentUserId)
        .collection("UserChats")
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> notifications = [];

      for (var chatDoc in querySnapshot.docs) {
        QuerySnapshot messageSnapshot = await chatDoc.reference
            .collection("Messages")
            .where("receiver_id", isEqualTo: currentUserId)
            .where("isRead", isEqualTo: false)
            .get();

        if (messageSnapshot.docs.isNotEmpty) {
          notifications.add({
            "chatId": chatDoc.id,
            "unreadCount": messageSnapshot.docs.length,
            "lastMessage": messageSnapshot.docs.last["text"],
          });
        }
      }

      return notifications;
    });
  }

  /// 📌 Marquer les messages comme lus
  Future<void> markMessagesAsRead(String chatId) async {
    String? userId = _auth.currentUser?.uid;
    if (userId == null) return;

    QuerySnapshot messageSnapshot = await _firestore
        .collection('Users')
        .doc(userId)
        .collection("UserChats")
        .doc(chatId)
        .collection("Messages")
        .where("receiver_id", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .get();

    for (var doc in messageSnapshot.docs) {
      await doc.reference.update({"isRead": true});
    }
  }
}
