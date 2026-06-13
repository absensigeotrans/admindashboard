import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_notification.dart';
import 'notification_service.dart';

class InboxService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UserNotificationModel> _notifications = [];
  bool _isLoading = false;
  int _unreadCount = 0;
  RealtimeChannel? _channel;

  List<UserNotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  StreamSubscription<AuthState>? _authStateSubscription;

  // Initialize and subscribe
  void initialize() {
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        fetchNotifications();
        subscribeToNotifications();
      } else {
        unsubscribe();
        _notifications = [];
        _unreadCount = 0;
        notifyListeners();
      }
    });

    if (_supabase.auth.currentUser != null) {
      fetchNotifications();
      subscribeToNotifications();
    }
  }

  // Fetch notifications
  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('user_notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _notifications = (data as List)
          .map((e) => UserNotificationModel.fromJson(e))
          .toList();

      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('[InboxService] Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark a single notification as read
  Future<void> markAsRead(String id) async {
    try {
      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('id', id);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = UserNotificationModel(
          id: _notifications[index].id,
          userId: _notifications[index].userId,
          title: _notifications[index].title,
          message: _notifications[index].message,
          isRead: true,
          createdAt: _notifications[index].createdAt,
        );
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[InboxService] Error marking as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      _notifications = _notifications.map((n) => UserNotificationModel(
        id: n.id,
        userId: n.userId,
        title: n.title,
        message: n.message,
        isRead: true,
        createdAt: n.createdAt,
      )).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[InboxService] Error marking all as read: $e');
    }
  }

  // Subscribe to realtime database changes
  void subscribeToNotifications() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Unsubscribe from existing if any
    unsubscribe();

    _channel = _supabase
        .channel('public:user_notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'user_notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('[InboxService] Realtime insert received: ${payload.newRecord}');
            final newNotif = UserNotificationModel.fromJson(payload.newRecord);
            
            // Check if it already exists locally to avoid duplicates
            if (!_notifications.any((n) => n.id == newNotif.id)) {
              _notifications.insert(0, newNotif);
              _unreadCount++;
              notifyListeners();

              // Trigger ringtone and local notification
              NotificationService().showInboxNotification(
                title: newNotif.title,
                body: newNotif.message,
              );
            }
          },
        )
        .subscribe();
  }

  // Unsubscribe
  void unsubscribe() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
      _channel = null;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    unsubscribe();
    super.dispose();
  }
}
