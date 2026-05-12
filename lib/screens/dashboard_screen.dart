import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/sync_service.dart';
import '../services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'history_screen.dart';
import 'leave_request_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  final double _officeLat = -6.2088; // Koordinat Kantor Pusat PTK (Seed Data)
  final double _officeLon = 106.8456;
  final double _radius = 100.0;

  bool _isProcessing = false;
  Map<String, dynamic>? _todayAttendance;
  int? _localAttendanceId; // ID absensi dari SQLite (kalau offline)

  @override
  void initState() {
    super.initState();
    _fetchTodayAttendance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDistanceUpdate();
    });
  }

  void _startDistanceUpdate() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    while (mounted) {
      await locationService.updateDistance(_officeLat, _officeLon, _radius);
      if (locationService.currentLocation != null) {
        _mapController.move(
          LatLng(locationService.currentLocation!.coords.latitude,
                 locationService.currentLocation!.coords.longitude),
          15.0
        );
      }
      await Future.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> _fetchTodayAttendance() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    try {
      // 1. Cek di Supabase (synced)
      final synced = await supabase
          .from('attendance')
          .select()
          .eq('user_id', user.id)
          .gte('check_in_time', '$today 00:00:00')
          .lte('check_in_time', '$today 23:59:59')
          .maybeSingle();

      if (synced != null) {
        if (mounted) {
          setState(() {
            _todayAttendance = synced;
            _localAttendanceId = null;
          });
        }
        return;
      }

      // 2. Cek di SQLite local (pending sync)
      final syncService = Provider.of<SyncService>(context, listen: false);
      final localData = await syncService.getTodayAttendance(user.id);

      if (localData.isNotEmpty) {
        if (mounted) {
          setState(() {
            _todayAttendance = localData.first;
            _localAttendanceId = localData.first['local_id'] as int?;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _todayAttendance = null;
            _localAttendanceId = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching attendance: $e');
    }
  }

  Future<void> _handleAttendance() async {
    setState(() => _isProcessing = true);

    final supabase = Supabase.instance.client;
    final locationService = Provider.of<LocationService>(context, listen: false);
    final syncService = Provider.of<SyncService>(context, listen: false);
    final user = supabase.auth.currentUser;

    if (user == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    final now = DateTime.now();
    final coords = locationService.currentLocation?.coords;

    try {
      if (_todayAttendance == null) {
        // ── CHECK-IN ──
        if (syncService.isOnline) {
          // Online: insert langsung ke Supabase
          await supabase.from('attendance').insert({
            'user_id': user.id,
            'check_in_time': now.toIso8601String(),
            'check_in_latitude': coords?.latitude,
            'check_in_longitude': coords?.longitude,
            'is_mocked': locationService.isMocked,
            'distance_from_office': locationService.currentDistance,
          });
          NotificationService().showCheckInSuccess();
        } else {
          // Offline: simpan ke SQLite
          await syncService.saveAttendanceOffline(
            userId: user.id,
            checkInTime: now,
            checkInLatitude: coords?.latitude ?? 0,
            checkInLongitude: coords?.longitude ?? 0,
            checkInDistance: locationService.currentDistance,
            isMocked: locationService.isMocked,
          );
        }
      } else {
        // ── CHECK-OUT ──
        if (_localAttendanceId != null) {
          // Ada di local SQLite → update local & sync
          await syncService.updateAttendanceOffline(
            localId: _localAttendanceId!,
            checkOutTime: now,
            checkOutLatitude: coords?.latitude ?? 0,
            checkOutLongitude: coords?.longitude ?? 0,
          );
        } else if (syncService.isOnline) {
          // Online & ada di Supabase → update Supabase
          await supabase.from('attendance').update({
            'check_out_time': now.toIso8601String(),
            'check_out_latitude': coords?.latitude,
            'check_out_longitude': coords?.longitude,
          }).eq('id', _todayAttendance!['id']);
        }
        NotificationService().showCheckOutSuccess();
      }

      await _fetchTodayAttendance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final locationService = Provider.of<LocationService>(context);
    final syncService = Provider.of<SyncService>(context);

    final role = authService.profile?['role'] ?? '';
    final isDriver = role == 'driver';
    final canAttend = (locationService.isInRadius || isDriver) && !locationService.isMocked;

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
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Column(
        children: [
          // ── Offline Banner ──
          if (!syncService.isOnline)
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

          // Map Section
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

          // Info Section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
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
                  if (locationService.isMocked)
                    const Text(
                      '⚠️ Fake GPS Terdeteksi! Absensi Dinonaktifkan.',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: (_isProcessing || !canAttend)
                          ? null
                          : _handleAttendance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _todayAttendance == null
                            ? const Color(0xFF005494)
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _todayAttendance == null ? 'CHECK-IN SEKARANG' : 'CHECK-OUT SEKARANG',
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
}
