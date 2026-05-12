import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

enum LeaveStatus { pending, approved, rejected, cancelled }

extension LeaveStatusExt on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Menunggu';
      case LeaveStatus.approved:
        return 'Disetujui';
      case LeaveStatus.rejected:
        return 'Ditolak';
      case LeaveStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return Colors.orange;
      case LeaveStatus.approved:
        return Colors.green;
      case LeaveStatus.rejected:
        return Colors.red;
      case LeaveStatus.cancelled:
        return Colors.grey;
    }
  }

  static LeaveStatus fromString(String? status) {
    switch (status) {
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.pending;
    }
  }
}

class LeaveRequest {
  final String id;
  final String userId;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final LeaveStatus status;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? respondedAt;

  LeaveRequest({
    required this.id,
    required this.userId,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.adminNote,
    required this.createdAt,
    this.respondedAt,
  });

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    return LeaveRequest(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      leaveType: map['leave_type'] ?? '',
      startDate: DateTime.parse(map['start_date']),
      endDate: DateTime.parse(map['end_date']),
      totalDays: map['total_days'] ?? 1,
      reason: map['reason'] ?? '',
      status: LeaveStatusExt.fromString(map['status']),
      adminNote: map['admin_note'],
      createdAt: DateTime.parse(map['created_at']),
      respondedAt: map['responded_at'] != null
          ? DateTime.parse(map['responded_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'leave_type': leaveType,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'total_days': totalDays,
      'reason': reason,
      'status': status.name,
    };
  }
}

class LeaveService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<LeaveRequest> _leaveList = [];
  bool _isLoading = false;
  String? _error;

  List<LeaveRequest> get leaveList => _leaveList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLeaveRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final data = await _supabase
          .from('leave_requests')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _leaveList = (data as List)
          .map((e) => LeaveRequest.fromMap(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitLeaveRequest({
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final totalDays = endDate.difference(startDate).inDays + 1;

      await _supabase.from('leave_requests').insert({
        'user_id': user.id,
        'leave_type': leaveType,
        'start_date': startDate.toIso8601String().substring(0, 10),
        'end_date': endDate.toIso8601String().substring(0, 10),
        'total_days': totalDays,
        'reason': reason,
        'status': 'pending',
      });

      NotificationService().showLeaveSubmitted();
      await fetchLeaveRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelLeaveRequest(String leaveId) async {
    try {
      await _supabase
          .from('leave_requests')
          .update({
            'status': 'cancelled',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId);

      await fetchLeaveRequests();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Admin Functions ───

  Future<bool> approveLeave(String leaveId, {String? note}) async {
    try {
      await _supabase
          .from('leave_requests')
          .update({
            'status': 'approved',
            'admin_note': note,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectLeave(String leaveId, {String? note}) async {
    try {
      await _supabase
          .from('leave_requests')
          .update({
            'status': 'rejected',
            'admin_note': note,
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', leaveId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  int get pendingCount =>
      _leaveList.where((l) => l.status == LeaveStatus.pending).length;

  int get approvedCount =>
      _leaveList.where((l) => l.status == LeaveStatus.approved).length;
}