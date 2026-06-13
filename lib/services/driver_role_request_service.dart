import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DriverRoleRequestStatus { pending, approved, rejected }

extension DriverRoleRequestStatusExt on DriverRoleRequestStatus {
  String get label {
    switch (this) {
      case DriverRoleRequestStatus.pending:
        return 'Menunggu';
      case DriverRoleRequestStatus.approved:
        return 'Disetujui';
      case DriverRoleRequestStatus.rejected:
        return 'Ditolak';
    }
  }

  Color get color {
    switch (this) {
      case DriverRoleRequestStatus.pending:
        return Colors.orange;
      case DriverRoleRequestStatus.approved:
        return Colors.green;
      case DriverRoleRequestStatus.rejected:
        return Colors.red;
    }
  }

  static DriverRoleRequestStatus fromString(String? status) {
    switch (status) {
      case 'approved':
        return DriverRoleRequestStatus.approved;
      case 'rejected':
        return DriverRoleRequestStatus.rejected;
      default:
        return DriverRoleRequestStatus.pending;
    }
  }
}

class DriverRoleRequest {
  final String id;
  final String userId;
  final String fromRole;
  final String toRole;
  final String reason;
  final DriverRoleRequestStatus status;
  final String? adminNotes;
  final DateTime createdAt;

  DriverRoleRequest({
    required this.id,
    required this.userId,
    required this.fromRole,
    required this.toRole,
    required this.reason,
    required this.status,
    this.adminNotes,
    required this.createdAt,
  });

  factory DriverRoleRequest.fromMap(Map<String, dynamic> map) {
    return DriverRoleRequest(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      fromRole: map['from_role'] ?? '',
      toRole: map['to_role'] ?? '',
      reason: map['reason'] ?? '',
      status: DriverRoleRequestStatusExt.fromString(map['status']),
      adminNotes: map['admin_notes'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class DriverRoleRequestService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<DriverRoleRequest> _requests = [];
  bool _isLoading = false;
  String? _error;

  List<DriverRoleRequest> get requests => _requests;
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
          .from('driver_role_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _requests = (data as List)
          .map((e) => DriverRoleRequest.fromMap(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitRequest({
    required String fromRole,
    required String toRole,
    required String reason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _supabase.from('driver_role_requests').insert({
        'user_id': user.id,
        'from_role': fromRole,
        'to_role': toRole,
        'reason': reason,
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
}
