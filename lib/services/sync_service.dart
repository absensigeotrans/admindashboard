import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import 'notification_service.dart';
import 'selfie_service.dart';

class SyncService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseHelper _db = DatabaseHelper.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _syncTimer;
  Timer? _periodicSyncTimer;

  bool _isOnline = true;
  bool _isSyncing = false;
  bool _autoSyncEnabled = true;
  int _pendingCount = 0;
  String? _lastSyncTime;
  String? _lastError;

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get autoSyncEnabled => _autoSyncEnabled;
  int get pendingCount => _pendingCount;
  String? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;

  SyncService() {
    _initConnectivity();
    _loadLastSyncTime();
    _updatePendingCount();
    _startPeriodicSync();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final wasOnline = _isOnline;
      _isOnline = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);

      debugPrint('[SyncService] Connectivity changed: $_isOnline');

      if (_isOnline && !wasOnline) {
        // Connection restored - trigger sync
        _syncPendingData();
      }

      notifyListeners();
    });

    // Check initial state
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _isOnline = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);
    notifyListeners();
  }

  void _loadLastSyncTime() async {
    _lastSyncTime = await _db.getState('last_sync_time');
    notifyListeners();
  }

  Future<void> _updatePendingCount() async {
    _pendingCount = await _db.getPendingCount();
    notifyListeners();
  }

  void _startPeriodicSync() {
    // Periodic sync every 5 minutes when online
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (_isOnline && _autoSyncEnabled) {
          _syncPendingData();
        }
      },
    );
  }

/// Simpan absensi ke local database
   Future<bool> saveAttendanceOffline({
     required String userId,
     required DateTime checkInTime,
     required double checkInLatitude,
     required double checkInLongitude,
     double? checkInDistance,
     bool isMocked = false,
     String? photoUrl,
     String? localPhotoPath,
     String? workStatus,
     Map<String, dynamic>? locationData,
   }) async {
    try {
      final checkInAccuracy = locationData?['accuracy'] as double?;
       await _db.insertPendingAttendance({
         'user_id': userId,
         'check_in_time': checkInTime.toIso8601String(),
         'check_in_latitude': checkInLatitude,
         'check_in_longitude': checkInLongitude,
         'check_in_accuracy': checkInAccuracy,
         'check_in_location_data': locationData,
         'is_mocked': isMocked ? 1 : 0,
         'distance_from_office': checkInDistance ?? 0,
         'photo_url': ?photoUrl,
         'local_photo_path': ?localPhotoPath,
         'sync_status': 'pending',
         'created_at': DateTime.now().toIso8601String(),
         'work_status': ?workStatus,
       });

      await _updatePendingCount();

      // If online, sync immediately
      if (_isOnline && _autoSyncEnabled) {
        _syncPendingData();
      } else {
        // Show offline saved notification
        NotificationService().showAttendanceSavedOffline();
      }

      return true;
    } catch (e) {
      debugPrint('[SyncService] Error saving offline attendance: $e');
      return false;
    }
  }

  /// Update absensi (check-out) di local database
  Future<bool> updateAttendanceOffline({
    required int localId,
    required DateTime checkOutTime,
    required double checkOutLatitude,
    required double checkOutLongitude,
  }) async {
    try {
      await _db.updatePendingAttendance(localId, {
        'check_out_time': checkOutTime.toIso8601String(),
        'check_out_latitude': checkOutLatitude,
        'check_out_longitude': checkOutLongitude,
      });

      await _updatePendingCount();

      if (_isOnline && _autoSyncEnabled) {
        _syncPendingData();
      }

      return true;
    } catch (e) {
      debugPrint('[SyncService] Error updating offline attendance: $e');
      return false;
    }
  }

  /// Simpan check-out offline untuk absensi yang check-in-nya sudah sinkron (online)
  Future<bool> saveCheckoutOffline({
    required String userId,
    required String checkInTime,
    required double checkInLatitude,
    required double checkInLongitude,
    required DateTime checkOutTime,
    required double checkOutLatitude,
    required double checkOutLongitude,
    String? workStatus,
  }) async {
    try {
      await _db.insertPendingAttendance({
        'user_id': userId,
        'check_in_time': checkInTime,
        'check_in_latitude': checkInLatitude,
        'check_in_longitude': checkInLongitude,
        'check_out_time': checkOutTime.toIso8601String(),
        'check_out_latitude': checkOutLatitude,
        'check_out_longitude': checkOutLongitude,
        'sync_status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'work_status': workStatus,
      });

      await _updatePendingCount();

      // Tampilkan notifikasi offline
      NotificationService().showAttendanceSavedOffline();

      if (_isOnline && _autoSyncEnabled) {
        _syncPendingData();
      }

      return true;
    } catch (e) {
      debugPrint('[SyncService] Error saving offline checkout: $e');
      return false;
    }
  }

  /// Sinkronisasi semua data pending ke Supabase
  Future<bool> _syncPendingData() async {
    if (_isSyncing) return false;
    if (!_isOnline) {
      _lastError = 'Tidak ada koneksi internet';
      notifyListeners();
      return false;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      final pendingList = await _db.getPendingAttendances();

      if (pendingList.isEmpty) {
        _isSyncing = false;
        notifyListeners();
        return true;
      }

      int successCount = 0;

      for (final item in pendingList) {
        final id = item['id'] as int;
        final checkOutTime = item['check_out_time'] as String?;
        final localPhotoPath = item['local_photo_path'] as String?;
        final existingPhotoUrl = item['photo_url'] as String?;

        // Skip records with invalid (0,0) coordinates
        final lat = item['check_in_latitude'] as num? ?? 0;
        final lng = item['check_in_longitude'] as num? ?? 0;
        if (lat == 0 && lng == 0 && checkOutTime == null) {
          debugPrint('[SyncService] Skipping record $id: invalid coordinates (0,0)');
          await _db.markAttendanceFailed(id, 'Invalid coordinates (0,0)');
          continue;
        }

        try {
          String? photoUrl = existingPhotoUrl;

          // Upload local photo if exists
          if (localPhotoPath != null && photoUrl == null) {
            final localFile = File(localPhotoPath);
            if (await localFile.exists()) {
              try {
                final selfieService = SelfieService();
                photoUrl = await selfieService.uploadLocalPhoto(
                  userId: item['user_id'],
                  localPath: localPhotoPath,
                );
              } catch (e) {
                debugPrint('[SyncService] Error uploading photo: $e');
              }
            }
          }

          // Check if already exists in Supabase (by check_in_time + user_id)
          final existing = await _supabase
              .from('attendance')
              .select('id')
              .eq('user_id', item['user_id'])
              .eq('check_in_time', item['check_in_time'])
              .maybeSingle();

          if (existing != null) {
           // Update existing record with check-out data if available
             if (checkOutTime != null) {
               await _supabase.from('attendance').update({
                 'check_out_time': item['check_out_time'],
                 'check_out_latitude': item['check_out_latitude'],
                 'check_out_longitude': item['check_out_longitude'],
                 'photo_url': ?photoUrl,
                 if (item['work_status'] != null) 'work_status': item['work_status'],
               }).eq('id', existing['id']);
             }
          } else {
             // Insert new record
             await _supabase.from('attendance').insert({
               'user_id': item['user_id'],
               'check_in_time': item['check_in_time'],
               'check_in_latitude': item['check_in_latitude'],
               'check_in_longitude': item['check_in_longitude'],
               'check_in_accuracy': item['check_in_accuracy'],
               'check_in_location_data': item['check_in_location_data'],
               'check_out_time': checkOutTime,
               'check_out_latitude': checkOutTime != null ? item['check_out_latitude'] : null,
               'check_out_longitude': checkOutTime != null ? item['check_out_longitude'] : null,
               'is_mocked': item['is_mocked'] == 1,
               'distance_from_office': item['distance_from_office'],
               'photo_url': ?photoUrl,
               if (item['work_status'] != null) 'work_status': item['work_status'],
             });
          }

          await _db.markAttendanceSynced(id);
          successCount++;
        } catch (e) {
          debugPrint('[SyncService] Error syncing item $id: $e');
          await _db.markAttendanceFailed(id, e.toString());
        }
      }

      // Clean up synced records
      await _db.deleteSyncedAttendance();

      // Update last sync time
      final now = DateTime.now().toIso8601String();
      await _db.setState('last_sync_time', now);
      _lastSyncTime = now;

      await _updatePendingCount();

      _isSyncing = false;
      notifyListeners();

      // Show sync completion notification
      if (successCount > 0) {
        NotificationService().showSyncComplete(successCount);
      }

      debugPrint('[SyncService] Sync complete: $successCount/${pendingList.length} items');
      return successCount == pendingList.length;
    } catch (e) {
      _lastError = e.toString();
      _isSyncing = false;
      notifyListeners();

      // Show sync failed notification
      NotificationService().showSyncFailed(_lastError ?? 'Unknown error');

      debugPrint('[SyncService] Sync error: $e');
      return false;
    }
  }

  /// Paksa sync manual
  Future<bool> forceSync() async {
    if (!_isOnline) {
      _lastError = 'Tidak ada koneksi internet';
      notifyListeners();
      return false;
    }
    return await _syncPendingData();
  }

  /// Toggle auto sync
  void toggleAutoSync() {
    _autoSyncEnabled = !_autoSyncEnabled;
    notifyListeners();

    if (_autoSyncEnabled && _isOnline) {
      _syncPendingData();
    }
  }

  /// Set auto sync enabled
  void setAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();

    if (enabled && _isOnline) {
      _syncPendingData();
    }
  }

  /// Get formatted last sync time
  String get formattedLastSync {
    if (_lastSyncTime == null) return 'Belum pernah sinkron';

    try {
      final dt = DateTime.parse(_lastSyncTime!);
      final diff = DateTime.now().difference(dt);

      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam lalu';
      return '${diff.inDays} hari lalu';
    } catch (e) {
      return _lastSyncTime!;
    }
  }

   /// Get local attendance for today (combined: synced + pending)
   Future<List<Map<String, dynamic>>> getTodayAttendance(String userId) async {
     final now = DateTime.now();
     final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
     final startUtc = startOfToday.toUtc().toIso8601String();
     final today = now.toIso8601String().substring(0, 10);
     final results = <Map<String, dynamic>>[];

     try {
       // Get from Supabase (synced)
       final synced = await _supabase
           .from('attendance')
           .select('id, user_id, check_in_time, check_in_latitude, check_in_longitude, check_out_time, check_out_latitude, check_out_longitude, is_mocked, distance_from_office, photo_url, work_status')
           .eq('user_id', userId)
           .gte('check_in_time', startUtc)
           .maybeSingle();

       if (synced != null) results.add(synced);

       // Get from local (pending)
       final pending = await _db.getAllPending();
       final localToday = pending.where((p) {
         final checkIn = p['check_in_time'] as String?;
         if (checkIn == null) return false;
         return checkIn.startsWith(today) && p['user_id'] == userId;
       }).toList();

       // If not in Supabase but in local, add from local
       if (synced == null && localToday.isNotEmpty) {
         final local = Map<String, dynamic>.from(localToday.first);
         local['is_local'] = true;
         local['local_id'] = local['id'];
         results.add(local);
       }

       return results;
     } catch (e) {
       debugPrint('[SyncService] Error getting today attendance: $e');
       return [];
     }
   }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _periodicSyncTimer?.cancel();
    super.dispose();
  }
}