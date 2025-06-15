import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_service.dart';

class NotificationItem {
  final Color statusColor;
  final String title;
  final String message;
  final DateTime timestamp;
  bool read;

  NotificationItem({
    required this.statusColor,
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  final Map<String, double> _lastFillLevels = {};
  final Map<String, Set<String>> _sentThresholds = {}; // binName -> {"empty", "half", "full"}

  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  void setNotificationsEnabled(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localPlugin = FlutterLocalNotificationsPlugin();

  List<NotificationItem> get notifications => _notifications;

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localPlugin.initialize(initSettings);

    final settings = await _messaging.requestPermission();
    _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        if (_notificationsEnabled) {
          _showLocalNotification(notif.title ?? '', notif.body ?? '');
        }

        _notifications.insert(
          0,
          NotificationItem(
            statusColor: Colors.blue,
            title: notif.title ?? 'Notification',
            message: notif.body ?? '',
            timestamp: DateTime.now(),
          ),
        );
        notifyListeners();
      }
    });
  }

  Future<void> loadUserNotificationPreference(AuthService authService) async {
    final data = authService.userData;
    if (data != null && data.containsKey('notifications')) {
      final enabled = data['notifications'] == true;
      setNotificationsEnabled(enabled);
    }
  }

  void checkFillLevel(String binName, double fillLevel) {
    final prevLevel = _lastFillLevels[binName];
    _lastFillLevels[binName] = fillLevel;

    final sentSet = _sentThresholds[binName] ?? <String>{};

    if (fillLevel <= 10 && !sentSet.contains('empty')) {
      // 🔄 Sıfırla: Kutu boşaldıysa diğer eşikleri yeniden tetikleyebiliriz
      resetThresholdsForBin(binName);
      _markThresholdSent(binName, 'empty');

      _createAndShowNotification(binName, 'has been Emptied', Colors.green);
    } else if (fillLevel >= 85 && !sentSet.contains('full')) {
      _createAndShowNotification(binName, 'is nearly Full !!', Colors.red);
      _markThresholdSent(binName, 'full');
    } else if (fillLevel >= 55 && !sentSet.contains('half')) {
      _createAndShowNotification(binName, '%50 Full', Colors.amber);
      _markThresholdSent(binName, 'half');
    }
  }

  void _markThresholdSent(String binName, String threshold) {
    _sentThresholds.putIfAbsent(binName, () => <String>{});
    _sentThresholds[binName]!.add(threshold);
  }

  void resetThresholdsForBin(String binName) {
    _sentThresholds.remove(binName);
    print("🔄 Thresholds for '$binName' have been reset.");
  }

  void resetAllThresholds() {
    _sentThresholds.clear();
    print("🚨 All bin thresholds have been reset.");
  }

  void _createAndShowNotification(String binName, String message, Color color) {
    if (_notificationsEnabled) {
      _showLocalNotification(binName, message);
    }

    _notifications.insert(
      0,
      NotificationItem(
        statusColor: color,
        title: binName,
        message: message,
        timestamp: DateTime.now(),
        read: false,
      ),
    );
    notifyListeners();
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'bin_channel',
      'Trash Bin Alerts',
      importance: Importance.max,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _localPlugin.show(
      0,
      title,
      body,
      platformDetails,
    );
  }

  void markAllAsRead() {
    for (var notif in _notifications) {
      notif.read = true;
    }
    notifyListeners();
  }

  int get unreadCount => _notifications.where((n) => !n.read).length;
}
