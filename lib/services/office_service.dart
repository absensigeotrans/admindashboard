import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfficeService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  double? _latitude;
  double? _longitude;
  double? _radius;
  String? _name;
  bool _isLoading = false;
  String? _error;

  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get radius => _radius;
  String? get name => _name;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchOffice() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('offices')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data != null) {
        _latitude = (data['latitude'] as num?)?.toDouble();
        _longitude = (data['longitude'] as num?)?.toDouble();
        _radius = (data['geofence_radius'] as num?)?.toDouble();
        _name = data['name'] as String?;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool get isReady => _latitude != null && _longitude != null && _radius != null;
}
