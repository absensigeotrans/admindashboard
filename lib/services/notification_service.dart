import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService extends FlutterLocalNotificationsPlugin {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isInitialized = false;

  // ─── Channel Definitions ───

  static const _channelAttendance = 'attendance_channel';
  static const _channelSync = 'sync_channel';
  static const _channelLeave = 'leave_channel';
  static const _channelReminder = 'reminder_channel';

  // ─── Initialize ───

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final result = await super.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    _isInitialized = result ?? false;

    if (_isInitialized) {
      // Create notification channels for Android
      await _createAndroidChannels();
    }

    debugPrint('[NotificationService] Initialized: $_isInitialized');
    return _isInitialized;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
    // Handle navigation based on payload
    // Can be handled via a global navigator key in main.dart
  }

  Future<void> _createAndroidChannels() async {
    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelAttendance,
          'Absensi',
          description: 'Notifikasi terkait absensi check-in/check-out',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelSync,
          'Sinkronisasi',
          description: 'Status sinkronisasi data offline',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelLeave,
          'Pengajuan Cuti',
          description: 'Status persetujuan cuti',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelReminder,
          'Pengingat',
          description: 'Pengingat absensi harian',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  // ─── Request Permissions ───

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }
    return false;
  }

  // ─── Attendance Notifications ───

  Future<void> showCheckInSuccess() async {
    await _show(
      id: 1001,
      channel: _channelAttendance,
      title: '✅ Check-In Berhasil',
      body: 'Absensi masuk telah tercatat. Selamat bekerja!',
      importance: Importance.high,
    );
  }

  Future<void> showCheckOutSuccess() async {
    await _show(
      id: 1002,
      channel: _channelAttendance,
      title: '✅ Check-Out Berhasil',
      body: 'Absensi pulang telah tercatat. Sampai jumpa besok!',
      importance: Importance.high,
    );
  }

  Future<void> showAttendanceSavedOffline() async {
    await _show(
      id: 1003,
      channel: _channelAttendance,
      title: '📴 Absensi Tersimpan Offline',
      body: 'Data absensi disimpan sementara. Akan disinkronkan saat online.',
      importance: Importance.high,
    );
  }

  // ─── Sync Notifications ───

  Future<void> showSyncComplete(int count) async {
    if (count == 0) return;
    await _show(
      id: 2001,
      channel: _channelSync,
      title: '🔄 Sinkronisasi Selesai',
      body: '$count data absensi berhasil disinkronkan ke server.',
      importance: Importance.defaultImportance,
    );
  }

  Future<void> showSyncFailed(String error) async {
    await _show(
      id: 2002,
      channel: _channelSync,
      title: '⚠️ Sinkronisasi Gagal',
      body: 'Gagal sinkronkan data: $error. Akan dicoba lagi nanti.',
      importance: Importance.defaultImportance,
    );
  }

  Future<void> showPendingSync(int count) async {
    await _show(
      id: 2003,
      channel: _channelSync,
      title: '📤 Ada Data Pending',
      body: '$count data absensi menunggu sinkronisasi. Pastikan koneksi internet tersedia.',
      importance: Importance.defaultImportance,
    );
  }

  // ─── Leave Notifications ───

  Future<void> showLeaveSubmitted() async {
    await _show(
      id: 3001,
      channel: _channelLeave,
      title: '📝 Pengajuan Cuti Terkirim',
      body: 'Pengajuan cuti Anda sedang dalam proses peninjauan oleh Admin.',
      importance: Importance.high,
    );
  }

  Future<void> showLeaveApproved(String dates) async {
    await _show(
      id: 3002,
      channel: _channelLeave,
      title: '🎉 Cuti Disetujui!',
      body: 'Pengajuan cuti ($dates) telah disetujui oleh Admin.',
      importance: Importance.high,
    );
  }

  Future<void> showLeaveRejected(String? note) async {
    await _show(
      id: 3003,
      channel: _channelLeave,
      title: '❌ Cuti Ditolak',
      body: note != null
          ? 'Catatan Admin: $note'
          : 'Pengajuan cuti Anda ditolak oleh Admin.',
      importance: Importance.high,
    );
  }

  Future<void> showLeaveCancelled() async {
    await _show(
      id: 3004,
      channel: _channelLeave,
      title: 'ℹ️ Cuti Dibatalkan',
      body: 'Pengajuan cuti Anda telah dibatalkan.',
      importance: Importance.defaultImportance,
    );
  }

  // ─── Security Notifications ───

  Future<void> showMockLocationAlert() async {
    await _show(
      id: 9001,
      channel: _channelAttendance,
      title: '⚠️ Peringatan Keamanan',
      body: 'Fake GPS terdeteksi! Absensi dinonaktifkan demi keamanan.',
      importance: Importance.max,
    );
  }

  // ─── Reminder Notifications ───

  /// Jadwalkan pengingat check-in harian
  Future<void> scheduleCheckInReminder({
    required int hour,
    required int minute,
    required String shiftLabel,
  }) async {
    // Cancel existing reminder first
    await cancelCheckInReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // If time already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await zonedSchedule(
      id: 4001,
      title: '⏰ Pengingat Absensi',
      body: 'Shift $shiftLabel dimulai! Jangan lupa check-in.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );

    debugPrint('[NotificationService] Check-in reminder scheduled: ${scheduledDate.hour}:${scheduledDate.minute}');
  }

  Future<void> cancelCheckInReminder() async {
    await cancel(4001);
  }

  /// Jadwalkan pengingat check-out harian
  Future<void> scheduleCheckOutReminder({
    required int hour,
    required int minute,
    required String shiftLabel,
  }) async {
    await cancelCheckOutReminder();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await zonedSchedule(
      id: 4002,
      title: '⏰ Pengingat Check-Out',
      body: 'Shift $shiftLabel hampir selesai. Jangan lupa check-out!',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('[NotificationService] Check-out reminder scheduled: ${scheduledDate.hour}:${scheduledDate.minute}');
  }

  Future<void> cancelCheckOutReminder() async {
    await cancel(4002);
  }

  /// Jadwalkan pengingat cuti yang akan datang (1 hari sebelum)
  Future<void> scheduleLeaveReminder({
    required String leaveId,
    required DateTime startDate,
    required String leaveType,
  }) async {
    final reminderDate = startDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    if (reminderDate.isBefore(now)) return; // Don't schedule if date passed

    final scheduledDate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // 09:00 AM
      0,
    );

    await zonedSchedule(
      id: 5000 + leaveId.hashCode % 1000,
      title: '📅 Pengingat Cuti Besok',
      body: 'Cuti $leaveType dimulai besok. Pastikan semuanya sudah siap.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null, // One-time
    );
  }

  // ─── Utility ───

  Future<void> _show({
    required int id,
    required String channel,
    required String title,
    required String body,
    required Importance importance,
    String? payload,
  }) async {
    if (!_isInitialized) {
      debugPrint('[NotificationService] Not initialized, skipping notification');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channel,
      _getChannelName(channel),
      importance: importance,
      priority: _toPriority(importance),
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await show(
      id: id,
      title: title,
      body: body,
      payload: payload,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  String _getChannelName(String channel) {
    switch (channel) {
      case _channelAttendance: return 'Absensi';
      case _channelSync: return 'Sinkronisasi';
      case _channelLeave: return 'Pengajuan Cuti';
      case _channelReminder: return 'Pengingat';
      default: return 'GeoAttend PTK';
    }
  }

  Priority _toPriority(Importance importance) {
    switch (importance) {
      case Importance.max:
        return Priority.max;
      case Importance.high:
        return Priority.high;
      case Importance.defaultImportance:
        return Priority.defaultPriority;
      case Importance.low:
        return Priority.low;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await pendingNotificationRequests();
  }
}