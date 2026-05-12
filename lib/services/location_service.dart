import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'notification_service.dart';

class LocationService extends ChangeNotifier {
  bool _isTracking = false;
  double _currentDistance = 0.0;
  bool _isInRadius = false;
  bool _isMocked = false;
  bool _wasMocked = false; // Flag for alert
  bg.Location? _currentLocation;

  bool get isTracking => _isTracking;
  double get currentDistance => _currentDistance;
  bool get isInRadius => _isInRadius;
  bool get isMocked => _isMocked;
  bg.Location? get currentLocation => _currentLocation;

  LocationService() {
    _initBackgroundGeolocation();
  }

  void _initBackgroundGeolocation() {
    // Configure background geolocation
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      _currentLocation = location;
      _isMocked = location.isMock ?? false;
      
      if (_isMocked && !_wasMocked) {
        NotificationService().showMockLocationAlert();
      }
      _wasMocked = _isMocked;

      notifyListeners();
      debugPrint('[location] - $location');
    });

    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      debugPrint('[motionchange] - $location');
    });

    bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) {
      debugPrint('[heartbeat] - $event');
      // Logic for heartbeat ping to server can be added here
    });

    bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: false,
      logLevel: bg.Config.LOG_LEVEL_OFF,
      heartbeatInterval: 300, // 5 minutes heartbeat
      notification: bg.Notification(
        title: "GeoAttend PTK Aktif",
        text: "Pelacakan lokasi sedang berjalan untuk absensi.",
      )
    )).then((bg.State state) {
      _isTracking = state.enabled;
      notifyListeners();
    });
  }

  // Haversine Formula for Distance Calculation
  double calculateDistance(double startLat, double startLon, double endLat, double endLon) {
    const p = 0.017453292519943295;
    const c = math.cos;
    final a = 0.5 - c((endLat - startLat) * p) / 2 +
        c(startLat * p) * c(endLat * p) *
            (1 - c((endLon - startLon) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a)) * 1000; // Returns meters
  }

  Future<void> updateDistance(double officeLat, double officeLon, double radius) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      _isMocked = position.isMocked;
      if (_isMocked && !_wasMocked) {
        NotificationService().showMockLocationAlert();
      }
      _wasMocked = _isMocked;

      _currentDistance = calculateDistance(
        position.latitude, 
        position.longitude, 
        officeLat, 
        officeLon
      );
      
      _isInRadius = _currentDistance <= radius;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating distance: $e');
    }
  }

  Future<void> startTracking() async {
    await bg.BackgroundGeolocation.start();
    _isTracking = true;
    notifyListeners();
  }

  Future<void> stopTracking() async {
    await bg.BackgroundGeolocation.stop();
    _isTracking = false;
    notifyListeners();
  }
}
