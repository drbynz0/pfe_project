import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  String? currentUserId;

  Future<void> initialize() async {
    _getCurrentUserId();
    // 🔹 Demander la permission pour iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Permission accordée !");
    } else {
      print("❌ Permission refusée !");
    }

    // 🔹 Récupérer le token FCM et l'enregistrer dans Firestore
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(currentUserId) // Remplace par l'UID de l'utilisateur connecté
          .update({'fcm_token': token});
    }

    // 🔹 Configurer la réception des notifications en arrière-plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Nouveau message : ${message.notification?.title}");
      _showNotification(message);
    });

    // 🔹 Gérer le clic sur la notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔔 Notification cliquée : ${message.data}");
    });

    _configureLocalNotifications();
  }

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

  /// 🔹 Configurer les notifications locales pour afficher une alerte
  void _configureLocalNotifications() {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    _localNotifications.initialize(settings);
  }

  /// 🔔 Afficher une notification locale
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Nouvelle notification',
      message.notification?.body ?? 'Vous avez un nouveau message',
      platformDetails,
    );
  }
}
