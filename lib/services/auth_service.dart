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
    
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
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

  Future<void> refreshProfile() async {
    await _fetchProfile();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String employeeId,
    required String role,
    String shiftType = 'non_shifting',
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Check if NIK already exists to prevent generic DB error saving new user
      final exists = await _supabase.rpc('check_employee_id_exists', params: {
        'emp_id': employeeId,
      });
      if (exists == true) {
        _isLoading = false;
        notifyListeners();
        return 'NIK/ID Karyawan sudah terdaftar. Silakan hubungi Admin.';
      }

      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'employee_id': employeeId,
          'role': role,
          'shift_type': shiftType,
          'registered_password': password,
        },
      );
      
      _isLoading = false;
      notifyListeners();
      return null;
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
      return null;
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

  Future<String?> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
      return null;
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

  Future<String?> updateProfile({
    String? fullName,
    String? employeeId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) updates['full_name'] = fullName;
      if (employeeId != null) updates['employee_id'] = employeeId;

      await _supabase.from('profiles').update(updates).eq('id', _user!.id);
      await _fetchProfile();

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.toString();
    }
  }

  Future<String?> changePassword(String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      _isLoading = false;
      notifyListeners();
      return null;
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
