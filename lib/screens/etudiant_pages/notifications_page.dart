import 'package:flutter/material.dart';
import '/services/list_notification_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notificationService = ListNotificationService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: notificationService.getUserNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune notification"));
          }

          List<Map<String, dynamic>> notifications = snapshot.data!;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notification = notifications[index];

              return ListTile(
                leading: const Icon(Icons.message, color: Colors.blue),
                title: Text("Nouveau message dans ${notification['chatId']}"),
                subtitle: Text(notification["lastMessage"]),
                trailing: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text(notification["unreadCount"].toString(),
                      style: const TextStyle(color: Colors.white)),
                ),
                onTap: () {
                  // Marquer comme lu et ouvrir le chat
                  notificationService.markMessagesAsRead(notification["chatId"]);
                  Navigator.pushNamed(context, '/chat', arguments: notification["chatId"]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
