import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class ParentNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'settings_access_attempt' | 'goal_completed' | 'routine_alert'

  const ParentNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'settings_access_attempt',
  });

  ParentNotification copyWith({bool? isRead}) {
    return ParentNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'type': type,
    };
  }

  factory ParentNotification.fromMap(Map<String, dynamic> map) {
    return ParentNotification(
      id: (map['id'] ?? '') as String,
      title: (map['title'] ?? '') as String,
      message: (map['message'] ?? '') as String,
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isRead: (map['is_read'] ?? false) as bool,
      type: (map['type'] ?? 'settings_access_attempt') as String,
    );
  }
}

class ParentNotificationService {
  static final ParentNotificationService instance = ParentNotificationService._internal();
  ParentNotificationService._internal();

  static const String keyNotifications = 'parent_notifications_list';

  final ValueNotifier<List<ParentNotification>> notificationsNotifier =
      ValueNotifier<List<ParentNotification>>([]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  List<ParentNotification> get notifications => notificationsNotifier.value;
  int get unreadCount => unreadCountNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(keyNotifications);
    if (raw != null && raw.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        final loaded = list.map((item) => ParentNotification.fromMap(item as Map<String, dynamic>)).toList();
        notificationsNotifier.value = loaded;
        _updateUnreadCount();
      } catch (e) {
        debugPrint('Error loading parent notifications: $e');
      }
    }
  }

  void _updateUnreadCount() {
    unreadCountNotifier.value = notificationsNotifier.value.where((n) => !n.isRead).length;
  }

  Future<void> sendNotification({
    required String title,
    required String message,
    String type = 'settings_access_attempt',
  }) async {
    final newNotification = ParentNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
      type: type,
    );

    final updated = [newNotification, ...notificationsNotifier.value];
    notificationsNotifier.value = updated;
    _updateUnreadCount();

    // Persist locally
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(updated.map((n) => n.toMap()).toList());
    await prefs.setString(keyNotifications, jsonString);

    // Persist to Firestore if available
    try {
      if (FirebaseService.instance.isFirebaseReady) {
        await FirebaseFirestore.instance.collection('parent_notifications').add(newNotification.toMap());
      }
    } catch (e) {
      debugPrint('Firestore notification sync error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final updated = notificationsNotifier.value.map((n) => n.copyWith(isRead: true)).toList();
    notificationsNotifier.value = updated;
    _updateUnreadCount();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyNotifications, jsonEncode(updated.map((n) => n.toMap()).toList()));
  }

  Future<void> clearAll() async {
    notificationsNotifier.value = [];
    unreadCountNotifier.value = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyNotifications);
  }
}
