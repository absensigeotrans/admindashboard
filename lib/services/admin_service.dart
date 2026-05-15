import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _activeUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get pendingUsers => _pendingUsers;
  List<Map<String, dynamic>> get activeUsers => _activeUsers;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAllUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      _allUsers = List<Map<String, dynamic>>.from(data);
      _pendingUsers = _allUsers.where((u) => u['is_active'] == false).toList();
      _activeUsers = _allUsers.where((u) => u['is_active'] == true).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserActive(String userId, bool isActive) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_active': isActive})
          .eq('id', userId);

      // Update local state
      final index = _allUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        _allUsers[index]['is_active'] = isActive;
      }

      _pendingUsers = _allUsers.where((u) => u['is_active'] == false).toList();
      _activeUsers = _allUsers.where((u) => u['is_active'] == true).toList();

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveUser(String userId) async {
    return toggleUserActive(userId, true);
  }

  Future<bool> deactivateUser(String userId) async {
    return toggleUserActive(userId, false);
  }

  int get pendingCount => _pendingUsers.length;
  int get activeCount => _activeUsers.length;
  int get totalCount => _allUsers.length;
}
