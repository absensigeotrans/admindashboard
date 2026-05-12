import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  AuthService() {
    _user = _supabase.auth.currentUser;
    if (_user != null) {
      _fetchProfile();
    }
    
    // Listen for auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.user;
      if (_user != null) {
        _fetchProfile();
      } else {
        _profile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchProfile() async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .single();
      _profile = data;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeId,
    required String role,
    required String shiftType,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'employee_id': employeeId,
          'role': role,
          'shift_type': shiftType,
        },
      );
      
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on AuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
