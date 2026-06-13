import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum PasswordChangeRequestStatus { pending, approved, rejected }

extension PasswordChangeRequestStatusExt on PasswordChangeRequestStatus {
  String get label {
    switch (this) {
      case PasswordChangeRequestStatus.pending:
        return 'Menunggu';
      case PasswordChangeRequestStatus.approved:
        return 'Disetujui';
      case PasswordChangeRequestStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case PasswordChangeRequestStatus.pending:
        return Colors.orange;
      case PasswordChangeRequestStatus.approved:
        return Colors.green;
      case PasswordChangeRequestStatus.rejected:
        return Colors.red;
    }
  }

  static PasswordChangeRequestStatus fromString(String? status) {
    switch (status) {
      case 'approved':
        return PasswordChangeRequestStatus.approved;
      case 'rejected':
        return PasswordChangeRequestStatus.rejected;
      default:
        return PasswordChangeRequestStatus.pending;
    }
  }
}

class PasswordChangeRequest {
  final String id;
  final String userId;
  final String newPassword;
  final PasswordChangeRequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;

  PasswordChangeRequest({
    required this.id,
    required this.userId,
    required this.newPassword,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory PasswordChangeRequest.fromMap(Map<String, dynamic> map) {
    return PasswordChangeRequest(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      newPassword: map['new_password'] ?? '',
      status: PasswordChangeRequestStatusExt.fromString(map['status']),
      adminNotes: map['admin_notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class PasswordChangeRequestService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<PasswordChangeRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  List<PasswordChangeRequest> get requests => _requests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = await _supabase
          .from('password_change_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _requests = (data as List)
          .map((e) => PasswordChangeRequest.fromMap(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest({
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('password_change_requests').insert({
        'user_id': user.id,
        'new_password': newPassword,
        'status': 'pending',
      });

      await fetchRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitForgotPasswordRequest({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _supabase.rpc('submit_forgot_password_request', params: {
        'p_email': email,
        'p_new_password': newPassword,
      });

      final success = response['success'] as bool? ?? false;
      if (!success) {
        _error = response['error'] as String? ?? 'Gagal mengirim pengajuan';
        notifyListeners();
        return false;
      }

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
