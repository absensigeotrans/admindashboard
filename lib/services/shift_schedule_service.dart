import 'package:supabase_flutter/supabase_flutter.dart';

class ShiftScheduleService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get user's shift for today
  Future<String?> getTodayShift(String userId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final result = await _supabase
          .from('user_shift_schedules')
          .select('shift_type')
          .eq('user_id', userId)
          .eq('schedule_date', today)
          .maybeSingle();
      
      return result?['shift_type'] as String?;
    } catch (e) {
      _logDebug('Error getting today shift: $e');
      return null;
    }
  }

  /// Check if user has selected shift for today
  Future<bool> hasSelectedShiftToday(String userId) async {
    final shift = await getTodayShift(userId);
    return shift != null;
  }

  /// Select shift for a specific date (default: today)
  Future<bool> selectShift(String userId, String shiftType, {String? date}) async {
    try {
      final scheduleDate = date ?? DateTime.now().toIso8601String().split('T')[0];
      
      // Use upsert to handle both insert and update
      await _supabase
          .from('user_shift_schedules')
          .upsert({
            'user_id': userId,
            'schedule_date': scheduleDate,
            'shift_type': shiftType,
          }, onConflict: 'user_id,schedule_date');
      
      return true;
    } catch (e) {
      _logDebug('Error selecting shift: $e');
      return false;
    }
  }

  /// Get shift for a specific date
  Future<String?> getShiftForDate(String userId, String date) async {
    try {
      final result = await _supabase
          .from('user_shift_schedules')
          .select('shift_type')
          .eq('user_id', userId)
          .eq('schedule_date', date)
          .maybeSingle();
      
      return result?['shift_type'] as String?;
    } catch (e) {
      _logDebug('Error getting shift for date: $e');
      return null;
    }
  }

  /// Get shift history for a user (last N days)
  Future<List<Map<String, dynamic>>> getShiftHistory(String userId, {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final result = await _supabase
          .from('user_shift_schedules')
          .select('schedule_date, shift_type, created_at')
          .eq('user_id', userId)
          .gte('schedule_date', startDate.toIso8601String().split('T')[0])
          .order('schedule_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      _logDebug('Error getting shift history: $e');
      return [];
    }
  }
}

void _logDebug(String message) {
  // ignore: avoid_print
  print(message);
}