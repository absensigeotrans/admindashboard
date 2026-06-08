import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/office_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import '../services/shift_schedule_service.dart';
import '../services/selfie_service.dart';
import '../widgets/selfie_camera_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_screen.dart';
import 'leave_request_screen.dart';
import 'statistics_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();

  double _officeLat = -6.2088;
  double _officeLon = 106.8456;
  double _radius = 100.0;

  bool _isProcessing = false;
  Map<String, dynamic>? _todayAttendance;
  bool _hasCheckedOutToday = false;
  int? _localAttendanceId;
  bool _isLocationReady = false;
  bool _isLocationServiceEnabled = true;
  Timer? _distanceUpdateTimer;
  String _todayShift = '';

  @override
  void initState() {
    super.initState();
    _loadOffice();
    _loadUserData();
    _fetchTodayAttendance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationServiceEnabled().then((_) {
        _checkAndRequestPermission();
      });
    });
  }

  Future<void> _loadUserData() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user != null && mounted) {
      final shiftService = ShiftScheduleService();
      final todayShift = await shiftService.getTodayShift(user.id);
      if (mounted) {
        setState(() {
          _todayShift = todayShift ?? '';
        });
        // Auto-prompt shift selection for Juru Parkir who haven't selected
        final role = Provider.of<AuthService>(context, listen: false).profile?['role'] ?? '';
        if (role == 'juru_parkir' && todayShift == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (mounted) {
              await _showShiftSelectionDialog(user.id);
              // Re-fetch shift after selection to update UI
              final newShift = await shiftService.getTodayShift(user.id);
              if (mounted) {
                setState(() {
                  _todayShift = newShift ?? '';
                });
              }
            }
          });
        }
      }
    }
  }

  Future<void> _checkAndRequestPermission() async {
    final locationService = Provider.of<LocationService>(context, listen: false);

    if (locationService.permissionDenied) {
      final granted = await locationService.requestPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin lokasi diperlukan untuk absensi'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    if (mounted) {
      _startDistanceUpdate();
    }
  }

  Future<void> _checkLocationServiceEnabled() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() => _isLocationServiceEnabled = enabled);
      if (!enabled) {
        _showEnableLocationDialog();
      }
    }
  }

  Future<void> _showEnableLocationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (alertContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Lokasi Tidak Aktif'),
          ],
        ),
        content: const Text(
          'Untuk melakukan absensi, Anda perlu mengaktifkan layanan lokasi.\n\n'
          'Harap aktifkan lokasi di pengaturan perangkat dan kembali ke aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(alertContext).pop(),
            child: const Text('Nanti'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if (alertContext.mounted) Navigator.of(alertContext).pop();
            },
            label: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    // Re-check after dialog
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() => _isLocationServiceEnabled = enabled);
    }
  }

  Future<void> _loadOffice() async {
    final officeService = Provider.of<OfficeService>(context, listen: false);
    await officeService.fetchOffice();
    if (officeService.isReady && mounted) {
      setState(() {
        _officeLat = officeService.latitude!;
        _officeLon = officeService.longitude!;
        _radius = officeService.radius!;
      });
      _mapController.move(LatLng(_officeLat, _officeLon), 15.0);
    }
  }

  /// Returns last known GPS position (from Geolocator) or background geolocation coords.
  dynamic _getActiveCoords(LocationService locationService) {
    if (locationService.lastGpsPosition != null) {
      return locationService.lastGpsPosition;
    }
    return locationService.currentLocation?.coords;
  }

  void _startDistanceUpdate() {
    _distanceUpdateTimer?.cancel();
    _distanceUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final locationService = Provider.of<LocationService>(context, listen: false);

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) setState(() => _isLocationServiceEnabled = false);
        return;
      }
      if (mounted) setState(() => _isLocationServiceEnabled = true);

      await locationService.updateDistance(_officeLat, _officeLon, _radius);

      if (locationService.currentLocation != null && mounted) {
        setState(() => _isLocationReady = true);
        _mapController.move(
          LatLng(locationService.currentLocation!.coords.latitude,
                 locationService.currentLocation!.coords.longitude),
          15.0
        );
      }
    });
  }

  // Check if Juru Parkir has selected shift for today
  Future<bool> _checkJuruParkirShift(String userId) async {
    final shiftService = ShiftScheduleService();
    final hasShift = await shiftService.hasSelectedShiftToday(userId);
    return hasShift;
  }

  // Show shift selection dialog for Juru Parkir
  Future<void> _showShiftSelectionDialog(String userId) async {
    final shiftService = ShiftScheduleService();
    String? selectedShift;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Shift Hari Ini'),
        content: const Text(
          'Untuk role Juru Parkir, Anda wajib memilih shift sebelum melakukan absensi.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    selectedShift = 'morning';
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005494),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Column(
                    children: [
                      Text('Shift Pagi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('06:00 - 14:00', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    selectedShift = 'afternoon';
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Column(
                    children: [
                      Text('Shift Siang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('10:00 - 18:00', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    selectedShift = 'full_time';
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Column(
                    children: [
                      Text('Full Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('07:00 - 16:00', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (selectedShift != null) {
      await shiftService.selectShift(userId, selectedShift!);
      if (mounted) {
        final shiftLabel = selectedShift == 'morning' ? 'Pagi' : selectedShift == 'afternoon' ? 'Siang' : 'Full Time';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shift $shiftLabel dipilih!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _fetchTodayAttendance() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final results = await supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id)
          .gte('check_in_time', '$today 00:00:00')
          .lte('check_in_time', '$today 23:59:59')
          .order('check_in_time', ascending: false)
          .limit(1);

      final synced = results.isNotEmpty ? results.first : null;
      debugPrint('[Attendance] _fetchTodayAttendance: found=${results.length}, synced=$synced');

      if (synced != null) {
        final hasCheckout = synced['check_out_time'] != null;
        debugPrint('[Attendance] hasCheckout=$hasCheckout, check_out_time=${synced['check_out_time']}');
        if (mounted) {
          setState(() {
            _todayAttendance = synced;
            _hasCheckedOutToday = hasCheckout;
            _localAttendanceId = null;
          });
        }
        return;
      }

      final syncService = Provider.of<SyncService>(context, listen: false);
      final localData = await syncService.getTodayAttendance(user.id);
      debugPrint('[Attendance] Fallback localData: ${localData.length} items');

      if (localData.isNotEmpty) {
        final firstRecord = localData.first;
        final hasCheckout = firstRecord['check_out_time'] != null;
        debugPrint('[Attendance] Local hasCheckout=$hasCheckout, check_out_time=${firstRecord['check_out_time']}');
        if (mounted) {
          setState(() {
            _todayAttendance = firstRecord;
            _hasCheckedOutToday = hasCheckout;
            _localAttendanceId = hasCheckout ? null : (firstRecord['local_id'] as int?);
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _todayAttendance = null;
            _hasCheckedOutToday = false;
            _localAttendanceId = null;
          });
        }
      }
    } catch (e) {
      debugPrint('[Attendance] Error fetching attendance: $e');
    }
  }

  Future<void> _handleAttendance() async {
    setState(() => _isProcessing = true);

    final supabase = Supabase.instance.client;
    final locationService = Provider.of<LocationService>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    if (!_isLocationServiceEnabled) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mohon aktifkan lokasi (GPS) terlebih dahulu.'),
            backgroundColor: Colors.red,
          ),
        );
        _showEnableLocationDialog();
      }
      return;
    }

    // Check if user is driver (driver can check in from anywhere)
    final role = authService.profile?['role'] ?? '';
    final isDriver = role == 'driver_bebas';
    final isJuruParkir = role == 'juru_parkir';

    // For Juru Parkir, check if shift has been selected for today
    if (isJuruParkir && _todayAttendance == null) {
      final hasShift = await _checkJuruParkirShift(user.id);
      if (!hasShift && mounted) {
        await _showShiftSelectionDialog(user.id);
        // After selection, check again
        final stillNoShift = await _checkJuruParkirShift(user.id);
        if (stillNoShift) {
          // User didn't select shift, cancel check-in
          setState(() => _isProcessing = false);
          return;
        }
        // Update shift badge display
        final newShift = await ShiftScheduleService().getTodayShift(user.id);
        if (mounted) {
          setState(() {
            _todayShift = newShift ?? '';
          });
        }
      }
    }

    // Check if location is ready (skip for drivers)
    final coords = _getActiveCoords(locationService);
    if (coords == null && !isDriver && !locationService.isMocked) {
      // Try to get current position as fallback (except for drivers)
      await locationService.updateDistance(_officeLat, _officeLon, _radius);
      if (_getActiveCoords(locationService) == null) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi tidak tersedia. Mohon aktifkan GPS.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final now = DateTime.now();
    final currentCoords = _getActiveCoords(locationService);

// Reject invalid coordinates (0,0) — GPS not available
if (currentCoords != null && currentCoords.latitude == 0 && currentCoords.longitude == 0) {
  if (mounted) {
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi tidak valid (0,0). Mohon aktifkan GPS dan coba lagi.'),
        backgroundColor: Colors.red,
      ),
    );
  }
  return;
}

try {
  if (_todayAttendance != null && !_hasCheckedOutToday) {
    // CHECK-OUT
    if (syncService.isOnline) {
      if (_localAttendanceId != null) {
        await syncService.updateAttendanceOffline(
          localId: _localAttendanceId!,
          checkOutTime: now,
          checkOutLatitude: currentCoords?.latitude ?? 0,
          checkOutLongitude: currentCoords?.longitude ?? 0,
        );
      } else {
        final result = await supabase.from('attendance').update({
          'check_out_time': now.toUtc().toIso8601String(),
          'check_out_latitude': currentCoords?.latitude,
          'check_out_longitude': currentCoords?.longitude,
        }).eq('id', _todayAttendance!['id']).select('status').maybeSingle();

        if (result != null && mounted) {
          await _showCheckOutResultDialog(result['status']);
        }
        NotificationService().showCheckOutSuccess();
      }
    } else {
      if (_localAttendanceId != null) {
        await syncService.updateAttendanceOffline(
          localId: _localAttendanceId!,
          checkOutTime: now,
          checkOutLatitude: currentCoords?.latitude ?? 0,
          checkOutLongitude: currentCoords?.longitude ?? 0,
        );
      }
    }
    if (mounted) {
      setState(() => _hasCheckedOutToday = true);
    }
  } else if (_todayAttendance != null && _hasCheckedOutToday) {
    // Already checked in and checked out today - no more actions allowed
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah melakukan absensi hari ini.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  } else {
     // CHECK-IN
     // --- Select work status ---
     String? workStatus = await _showWorkStatusSelectionDialog();
     if (!mounted) {
       setState(() => _isProcessing = false);
       return;
     }
      // If user canceled dialog, stop check-in entirely
      if (workStatus == null) {
        setState(() => _isProcessing = false);
        return;
      }
     
     // --- Selfie capture ---
     String? photoUrl;
     String? localPhotoPath;
     if (mounted) {
       final selfieResult = await showDialog<SelfieResult>(
         context: context,
         barrierDismissible: false,
         builder: (_) => const SelfieCameraOverlay(),
       );
       photoUrl = selfieResult?.photoUrl;
       localPhotoPath = selfieResult?.localFilePath;
     }

     String? officeId;
     if (syncService.isOnline) {
       final officeData = await supabase.from('offices').select('id').eq('is_active', true).order('created_at', ascending: false).limit(1).maybeSingle();
       officeId = officeData?['id'];
     }

      if (syncService.isOnline) {
        final inserted = await supabase.from('attendance').insert({
          'user_id': user.id,
          'check_in_time': now.toUtc().toIso8601String(),
          'check_in_latitude': currentCoords?.latitude,
          'check_in_longitude': currentCoords?.longitude,
          'check_in_accuracy': currentCoords.accuracy,
          'check_in_location_data': locationService.buildLocationData(),
          'is_mocked': locationService.isMocked,
          'distance_from_office': locationService.currentDistance,
          'office_id': officeId,
          if (photoUrl != null) 'photo_url': photoUrl,
          'work_status': workStatus ?? 'WFO',
        }).select().maybeSingle();

        debugPrint('[Attendance] Insert result: $inserted');

        if (inserted != null && mounted) {
          setState(() {
            _todayAttendance = inserted;
            _hasCheckedOutToday = false;
            _localAttendanceId = null;
          });
          await _showCheckInResultDialog(inserted['status']);
          NotificationService().showCheckInSuccess();
        } else if (mounted) {
          setState(() {
            _todayAttendance = {
              'user_id': user.id,
              'check_in_time': now.toUtc().toIso8601String(),
              'check_in_latitude': currentCoords?.latitude,
              'check_in_longitude': currentCoords?.longitude,
              'check_in_accuracy': currentCoords?.accuracy,
              'check_in_location_data': locationService.buildLocationData(),
              'is_mocked': locationService.isMocked,
              'distance_from_office': locationService.currentDistance,
              'work_status': workStatus ?? 'WFO',
            };
            _hasCheckedOutToday = false;
            _localAttendanceId = null;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Check-in tersimpan lokal, menunggu sinkronisasi...'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          syncService.forceSync();
        }
      } else {
        final saved = await syncService.saveAttendanceOffline(
          userId: user.id,
          checkInTime: now,
          checkInLatitude: currentCoords?.latitude ?? 0,
          checkInLongitude: currentCoords?.longitude ?? 0,
          checkInDistance: locationService.currentDistance,
          isMocked: locationService.isMocked,
          photoUrl: photoUrl,
          localPhotoPath: localPhotoPath,
          workStatus: workStatus ?? 'WFO',
          locationData: locationService.buildLocationData(),
        );
        if (saved && mounted) {
          setState(() {
            _todayAttendance = {
              'user_id': user.id,
              'check_in_time': now.toUtc().toIso8601String(),
              'check_in_latitude': currentCoords?.latitude,
              'check_in_longitude': currentCoords?.longitude,
              'check_in_accuracy': currentCoords?.accuracy,
              'check_in_location_data': locationService.buildLocationData(),
              'is_mocked': locationService.isMocked,
              'distance_from_office': locationService.currentDistance,
              'work_status': workStatus ?? 'WFO',
            };
            _hasCheckedOutToday = false;
            _localAttendanceId = null;
          });
        }
      }
      }

  debugPrint('[Attendance] Check-in/out complete, refreshing state...');
} catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      await _fetchTodayAttendance();
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showCheckInResultDialog(String status) async {
    String title;
    String message;
    Color color;
    IconData icon;

    // Get user's shift for today to determine late threshold
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final shiftService = ShiftScheduleService();
    final userShift = user != null ? await shiftService.getTodayShift(user.id) : null;

    // Determine late threshold based on shift type
    String lateThresholdMsg;
    if (userShift == 'afternoon') {
      lateThresholdMsg = '10:03 WIB (Shift Siang)';
    } else if (userShift == 'morning') {
      lateThresholdMsg = '06:03 WIB (Shift Pagi)';
    } else {
      lateThresholdMsg = '07:03 WIB (Full Time)';
    }

    switch (status) {
      case 'present':
        title = 'Tepat Waktu';
        message = '✅ Anda check-in tepat waktu. Selamat bekerja!';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'late':
        title = '⚠️ Terlambat';
        message = 'Anda check-in setelah jam $lateThresholdMsg.\n迟到 (Terlambat)';
        color = Colors.orange;
        icon = Icons.access_time_filled;
        // Show late notification
        NotificationService().showLateNotification(lateThresholdMsg);
        break;
      case 'outside_radius':
        title = 'Di Luar Area';
        message = '📍 Lokasi Anda di luar area kantor. Absensi tetap tercatat.';
        color = Colors.blue;
        icon = Icons.location_off;
        break;
      default:
        title = 'Absensi Berhasil';
        message = '✅ Check-in berhasil.';
        color = Colors.green;
        icon = Icons.check;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: ${_nowWIB().toString().substring(11, 16)} WIB',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _showCheckOutResultDialog(String status) async {
    String title;
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case 'present':
        title = 'Check-Out Berhasil';
        message = '✅ Anda check-out tepat waktu.';
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'late':
        title = 'Check-Out Berhasil';
        message = '⚠️ Check-out terlambat (masuk terlambat).';
        color = Colors.orange;
        icon = Icons.access_time;
        break;
      case 'outside_radius':
        title = 'Check-Out Berhasil';
        message = '📍 Check-out berhasil (di luar area kantor).';
        color = Colors.blue;
        icon = Icons.location_off;
        break;
      default:
        title = 'Check-Out Berhasil';
        message = '✅ Check-out berhasil.';
        color = Colors.green;
        icon = Icons.check;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Waktu: ${_nowWIB().toString().substring(11, 16)} WIB',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Show dialog to select work status before check-in
  Future<String?> _showWorkStatusSelectionDialog() async {
    String? selectedStatus;
    String? customStatus;

    return await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Pilih Status Kerja'),
          content: StatefulBuilder(
            builder: (context, setState2) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  title: const Text('WFH (Work From Home)'),
                  value: 'WFH',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                RadioListTile<String>(
                  title: const Text('WFO (Work From Office)'),
                  value: 'WFO',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                RadioListTile<String>(
                  title: const Text('DINAS (Dinas/Travel)'),
                  value: 'DINAS',
                  groupValue: selectedStatus,
                  onChanged: (value) => setState(() => selectedStatus = value),
                ),
                RadioListTile<String>(
                  title: const Text('Lainnya'),
                  value: 'LAINNYA',
                  groupValue: selectedStatus,
                  onChanged: (value) => {
                    setState(() => selectedStatus = value),
                    // clear custom when switching away? we keep
                  },
                ),
                if (selectedStatus == 'LAINNYA')
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Masukkan status kustom',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => customStatus = value.trim(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                // Determine final status
                String? finalStatus;
                if (selectedStatus == 'LAINNYA') {
                  finalStatus = customStatus?.isNotEmpty == true ? customStatus : null;
                } else {
                  finalStatus = selectedStatus;
                }
                Navigator.of(context).pop(finalStatus);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _nowWIB() => DateTime.now().toUtc().add(const Duration(hours: 7));

  Widget _buildDigitalClock() {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = _nowWIB();
        final timeStr =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
        final days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        final dayName = days[now.weekday - 1];
        final months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        final dateStr = '$dayName, ${now.day} ${months[now.month - 1]} ${now.year}';
        return Column(
          children: [
            Text(
              timeStr,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w300,
                color: Color(0xFF005494),
                letterSpacing: 2,
              ),
            ),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final locationService = Provider.of<LocationService>(context);
    final syncService = Provider.of<SyncService>(context);

    final role = authService.profile?['role'] ?? '';
    final isDriver = role == 'driver_bebas';
    final hasLocation = locationService.currentLocation != null || locationService.lastGpsPosition != null || isDriver;
    final isWaitingForLocation = _isLocationServiceEnabled && !locationService.permissionDenied && !hasLocation && !locationService.isMocked;
    // Drivers can attend from anywhere (no radius check needed)
    final canAttend = _isLocationServiceEnabled && hasLocation && (locationService.isInRadius || isDriver) && !locationService.isMocked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoAttend Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Pengajuan Cuti',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Absensi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistik Bulanan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatisticsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profil Saya',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          if (!_isLocationServiceEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.red.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lokasi (GPS) Tidak Aktif',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Geolocator.openLocationSettings();
                    },
                    child: const Text(
                      'AKTIFKAN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          if (locationService.permissionDenied)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.red.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Izin Lokasi Ditolak',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      final granted = await locationService.requestPermission();
                      if (!granted && mounted) {
                        // Open app settings
                        await Geolocator.openAppSettings();
                      }
                    },
                    child: const Text(
                      'AKTIFKAN',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )
          else if (!syncService.isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.orange.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Offline Mode',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  if (syncService.pendingCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${syncService.pendingCount} pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else if (syncService.pendingCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sync, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Sinkronisasi ${syncService.pendingCount} data...',
                    style: const TextStyle(color: Colors.blue, fontSize: 13),
                  ),
                ],
              ),
            ),

          Expanded(
            flex: 3,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_officeLat, _officeLon),
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.dava.geoattend',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_officeLat, _officeLon),
                      color: Colors.blue.withOpacity(0.3),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
                      useRadiusInMeter: true,
                      radius: _radius,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(_officeLat, _officeLon),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.business, color: Colors.blue, size: 40),
                    ),
                    if (locationService.currentLocation != null)
                      Marker(
                        point: LatLng(locationService.currentLocation!.coords.latitude,
                                     locationService.currentLocation!.coords.longitude),
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildDigitalClock(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jarak ke Kantor', style: TextStyle(color: Colors.grey)),
                          Text(
                            '${locationService.currentDistance.toStringAsFixed(1)} Meter',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (!syncService.isOnline)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '📴 Offline',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (locationService.permissionDenied)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⚠️ Izin Ditolak',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (locationService.isInRadius || isDriver) ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isDriver
                                ? 'Bebas Area (Driver)'
                                : (locationService.isInRadius ? 'Dalam Area' : 'Di Luar Area'),
                              style: TextStyle(
                                color: (locationService.isInRadius || isDriver) ? Colors.green[800] : Colors.red[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Show shift info for Juru Parkir
                  if (role == 'juru_parkir')
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _todayShift.isEmpty
                            ? Colors.yellow[100]
                            : (_todayShift == 'morning' ? Colors.blue[100] : _todayShift == 'afternoon' ? Colors.orange[100] : Colors.grey[200]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: _todayShift.isEmpty
                                ? Colors.orange
                                : (_todayShift == 'morning' ? Colors.blue[800] : _todayShift == 'afternoon' ? Colors.orange[800] : Colors.grey[800]),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _todayShift.isEmpty
                                ? 'Shift: Belum Pilih'
                                : 'Shift ${_todayShift == 'morning' ? 'Pagi' : _todayShift == 'afternoon' ? 'Siang' : 'Full Time'}',
                            style: TextStyle(
                              color: _todayShift.isEmpty
                                  ? Colors.orange
                                  : (_todayShift == 'morning' ? Colors.blue[800] : _todayShift == 'afternoon' ? Colors.orange[800] : Colors.grey[800]),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          if (_todayShift.isNotEmpty) ...[
                            Text(
                              ' • Batas ${_todayShift == 'morning' ? '06:03' : _todayShift == 'afternoon' ? '10:03' : '07:03'}',
                              style: TextStyle(
                                color: _todayShift == 'morning' ? Colors.blue[600] : _todayShift == 'afternoon' ? Colors.orange[600] : Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (locationService.isMocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '⚠️ Fake GPS Terdeteksi! Absensi Dinonaktifkan.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || !canAttend || (_todayAttendance != null && _hasCheckedOutToday))
                          ? null
                          : _handleAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _todayAttendance != null && _hasCheckedOutToday
                            ? Colors.grey
                            : _todayAttendance != null
                                ? Colors.orange
                                : const Color(0xFF005494),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : isWaitingForLocation
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white70,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'MEMBACA LOKASI...',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              : _todayAttendance != null && _hasCheckedOutToday
                                  ? const Text(
                                      'SUDAH ABSEN HARI INI',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    )
                                  : Text(
                                      _todayAttendance != null
                                          ? 'CHECK-OUT SEKARANG'
                                          : 'CHECK-IN SEKARANG',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _distanceUpdateTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
