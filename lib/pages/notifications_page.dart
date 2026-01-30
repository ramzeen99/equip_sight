// lib/pages/notifications_page.dart
import 'package:equip_sight/model/notification_model.dart';
import 'package:equip_sight/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart';

class NotificationsPage extends StatefulWidget {
  static const String id = 'Notifications';

  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    initializeTimeZones();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Уведомления'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount > 0) {
                return TextButton(
                  onPressed: () => notificationProvider.markAllAsRead(),
                  child: Text('Прочитать все'),
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Нет уведомлений',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notificationProvider.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationProvider.notifications[index];
              return _buildNotificationItem(notification, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    AppNotification notification,
    BuildContext context,
  ) {
    return Dismissible(
      key: Key(notification.id),
      background: Container(color: Colors.red),
      onDismissed: (_) {
        context.read<NotificationProvider>().removeNotification(
          notification.id,
        );
      },
      child: ListTile(
        leading: _getNotificationIcon(notification.type),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Text(notification.message),
        trailing: Text(
          _formatTime(notification.timestamp),
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
        },
      ),
    );
  }

  Icon _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.machineFinished:
        return Icon(Icons.check_circle, color: Colors.green);
      case NotificationType.machineAvailable:
        return Icon(Icons.local_laundry_service, color: Colors.blue);
      case NotificationType.reminder:
        return Icon(Icons.timer, color: Colors.orange);
      case NotificationType.maintenance:
        return Icon(Icons.warning, color: Colors.red);
      case NotificationType.system:
        return Icon(Icons.info, color: Colors.grey);
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Только что';
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    }
    return '${difference.inDays} д назад';
  }
}
