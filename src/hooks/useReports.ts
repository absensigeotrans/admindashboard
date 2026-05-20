import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Attendance, AttendanceStatus, ShiftType } from '@/types';

interface ReportFilters {
  from?: string;
  to?: string;
  status?: AttendanceStatus;
  search?: string;
  isMocked?: boolean;
  excludeOutsideRadius?: boolean; // For driver role - they don't use geofencing
}

interface AttendanceWithProfile {
  id: string;
  user_id: string;
  shift_id?: string;
  office_id?: string;
  check_in_time: string;
  check_in_latitude: number;
  check_in_longitude: number;
  check_in_location_data?: Record<string, unknown>;
  check_out_time?: string | null;
  check_out_latitude?: number | null;
  check_out_longitude?: number | null;
  check_out_location_data?: Record<string, unknown>;
  is_valid: boolean;
  is_mocked: boolean;
  distance_from_office: number;
  status: AttendanceStatus;
  created_at: string;
  updated_at: string;
  shift_type?: ShiftType | null;
  profiles?: {
    full_name: string;
    email?: string;
    employee_id?: string;
    nik?: string;
    role?: string;
  };
}

export function useReports() {
  const [records, setRecords] = useState<AttendanceWithProfile[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchReport = useCallback(async (
    filters: ReportFilters = {},
    page = 1,
    limit = 50
  ) => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase
        .from('attendance')
        .select(`
          *,
          profiles!user_id(full_name, email, employee_id, nik, role)
        `, { count: 'exact' })
        .order('check_in_time', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

      if (filters.from) {
        query = query.gte('check_in_time', filters.from);
      }
      if (filters.to) {
        // Use inclusive end of day
        const toDate = new Date(filters.to);
        if (!isNaN(toDate.getTime())) {
          toDate.setHours(23, 59, 59, 999);
          query = query.lte('check_in_time', toDate.toISOString());
        }
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.isMocked !== undefined) {
        query = query.eq('is_mocked', filters.isMocked);
      }
      if (filters.search) {
        // Search in profile names via the relation
        query = query.or(`full_name.ilike.%${filters.search}%,email.ilike.%${filters.search}%,employee_id.ilike.%${filters.search}%`, { foreignTable: 'profiles' });
      }
      if (filters.excludeOutsideRadius) {
        query = query.neq('status', 'outside_radius');
      }

      const { data, error: fetchError, count } = await query;
      if (fetchError) {
        console.error('useReports fetchReport ERROR OBJECT:', fetchError);
        console.error('useReports fetchReport ERROR STRING:', JSON.stringify(fetchError, null, 2));
        throw fetchError;
      }

      // Enrich with shift type from user_shift_schedules
      const result = await Promise.all(
        (data || []).map(async (record) => {
          const checkInDate = new Date(record.check_in_time).toISOString().split('T')[0];
          const shiftResult = await supabase
            .from('user_shift_schedules')
            .select('shift_type')
            .eq('user_id', record.user_id)
            .eq('schedule_date', checkInDate)
            .maybeSingle();

          return {
            ...record,
            shift_type: (shiftResult as { shift_type?: string } | null)?.shift_type as ShiftType | undefined,
          };
        })
      );

      setRecords(result as AttendanceWithProfile[]);
      return { data: result as AttendanceWithProfile[], count: count || 0 };
    } catch (err: any) {
      console.error('Report fetch catch block err:', err);
      const msg = err?.message || err?.details || (typeof err === 'string' ? err : 'Failed to fetch report');
      setError(msg);
      return { data: [], count: 0 };
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchReportWithUsers = useCallback(async (
    filters: ReportFilters = {},
    page = 1,
    limit = 50
  ) => {
    // Re-use fetchReport which now includes profiles
    return fetchReport(filters, page, limit);
  }, [fetchReport]);

  // Fetch ALL records without pagination (for exports)
  const fetchAllRecords = useCallback(async (
    filters: ReportFilters = {}
  ) => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase
        .from('attendance')
        .select(`
          *,
          profiles!user_id(full_name, email, employee_id, nik, role)
        `)
        .order('check_in_time', { ascending: false });

      if (filters.from) {
        query = query.gte('check_in_time', filters.from);
      }
      if (filters.to) {
        const toDate = new Date(filters.to);
        if (!isNaN(toDate.getTime())) {
          toDate.setHours(23, 59, 59, 999);
          query = query.lte('check_in_time', toDate.toISOString());
        }
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }
      if (filters.isMocked !== undefined) {
        query = query.eq('is_mocked', filters.isMocked);
      }
      if (filters.excludeOutsideRadius) {
        query = query.neq('status', 'outside_radius');
      }

      const { data, error: fetchError } = await query;
      if (fetchError) {
        console.error('useReports fetchAllRecords ERROR:', JSON.stringify(fetchError, null, 2));
        throw fetchError;
      }

      // Enrich with shift type from user_shift_schedules
      const result = await Promise.all(
        (data || []).map(async (record) => {
          const checkInDate = new Date(record.check_in_time).toISOString().split('T')[0];
          const shiftResult = await supabase
            .from('user_shift_schedules')
            .select('shift_type')
            .eq('user_id', record.user_id)
            .eq('schedule_date', checkInDate)
            .maybeSingle();

          return {
            ...record,
            shift_type: (shiftResult as { shift_type?: string } | null)?.shift_type as ShiftType | undefined,
          };
        })
      );

      setRecords(result as AttendanceWithProfile[]);
      return { data: result as AttendanceWithProfile[], count: result.length };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch all records';
      console.error('All records fetch error:', msg);
      setError(msg);
      return { data: [], count: 0 };
    } finally {
      setLoading(false);
    }
  }, []);

  // Fetch dashboard summary data
  const fetchDashboardData = useCallback(async (days = 30) => {
    setLoading(true);
    setError(null);
    try {
      const fromDate = new Date();
      fromDate.setDate(fromDate.getDate() - days);
      fromDate.setHours(0, 0, 0, 0);

      const { data, error: fetchError } = await supabase
        .from('attendance')
        .select(`
          *,
          profiles!user_id(full_name, email, employee_id, nik)
        `)
        .gte('check_in_time', fromDate.toISOString())
        .order('check_in_time', { ascending: false });

      if (fetchError) {
        console.error('useReports fetchDashboardData ERROR:', JSON.stringify(fetchError, null, 2));
        throw fetchError;
      }

      const result = data as AttendanceWithProfile[] || [];
      setRecords(result);
      return { data: result, count: result.length };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch dashboard data';
      console.error('Dashboard data fetch error:', msg);
      setError(msg);
      return { data: [], count: 0 };
    } finally {
      setLoading(false);
    }
  }, []);


  const getStats = useCallback((data: AttendanceWithProfile[]) => {
    const total = data.length;
    const present = data.filter((r) => r.status === 'present').length;
    const late = data.filter((r) => r.status === 'late').length;
    // Note: outside_radius still tracked internally but not displayed in UI
    const outside = data.filter((r) => r.status === 'outside_radius').length;
    const suspicious = data.filter((r) => r.is_mocked).length;
    const avgDistance = total > 0
      ? data.reduce((sum, r) => sum + (r.distance_from_office || 0), 0) / total
      : 0;

    // UI displays only: total, present, late, suspicious, avgDistance
    return { total, present, late, outside, suspicious, avgDistance };
  }, []);

  // Get employee-wise summary
  const getEmployeeSummary = useCallback((data: AttendanceWithProfile[]) => {
    const summary: Record<string, {
      name: string;
      employee_id?: string;
      total: number;
      present: number;
      late: number;
      absent: number; // calculated - not from records
      suspicious: number;
      shifts?: Record<string, number>; // shift type counts
    }> = {};

    data.forEach((record) => {
      const uid = record.user_id;
      if (!summary[uid]) {
        summary[uid] = {
          name: record.profiles?.full_name || 'Unknown',
          employee_id: record.profiles?.employee_id,
          total: 0,
          present: 0,
          late: 0,
          absent: 0,
          suspicious: 0,
          shifts: {},
        };
      }
      summary[uid].total++;
      if (record.status === 'present') summary[uid].present++;
      if (record.status === 'late') summary[uid].late++;
      if (record.is_mocked) summary[uid].suspicious++;

      // Track shift distribution
      const shiftType = (record as any).shift_type || 'default';
      summary[uid].shifts![shiftType] = (summary[uid].shifts![shiftType] || 0) + 1;
    });

    // Note: absent is calculated based on working days vs attendance records
    return Object.entries(summary).map(([uid, stats]) => ({
      user_id: uid,
      ...stats,
      // Rate calculation: only present counts, late is separate
      rate: stats.total > 0 ? Math.round((stats.present / stats.total) * 100) : 0,
    })).sort((a, b) => b.rate - a.rate);
  }, []);

  // Get shift label from shift type
  const getShiftLabel = (shiftType: string | undefined | null): string => {
    if (!shiftType || shiftType === 'default') return '—';
    return shiftType === 'morning' ? 'Pagi' : 'Siang';
  };

  // Delete all attendance records for a specific date
  const deleteByDate = useCallback(async (date: string) => {
    setLoading(true);
    setError(null);
    try {
      // Parse date as local time (WIB/UTC+7)
      const [year, month, day] = date.split('-').map(Number);
      const startOfDay = new Date(year, month - 1, day, 0, 0, 0, 0);
      const endOfDay = new Date(year, month - 1, day, 23, 59, 59, 999);

      console.log('Deleting attendance for date:', date);
      console.log('Start:', startOfDay.toISOString());
      console.log('End:', endOfDay.toISOString());

      const { error: deleteError, count } = await supabase
        .from('attendance')
        .delete()
        .gte('check_in_time', startOfDay.toISOString())
        .lte('check_in_time', endOfDay.toISOString());

      console.log('Delete result - count:', count, 'error:', deleteError);

      if (deleteError) {
        console.error('deleteByDate ERROR:', deleteError);
        throw deleteError;
      }

      // Clear local records since data changed
      setRecords([]);
      return { success: true, message: `Berhasil menghapus ${count || 0} data untuk ${date}`, count };
    } catch (err: any) {
      const msg = err?.message || err?.details || 'Failed to delete records';
      console.error('deleteByDate catch error:', msg);
      setError(msg);
      return { success: false, error: msg };
    } finally {
      setLoading(false);
    }
  }, []);

  return {
    records,
    loading,
    error,
    fetchReport,
    fetchReportWithUsers,
    fetchAllRecords,
    fetchDashboardData,
    getStats,
    getEmployeeSummary,
    getShiftLabel,
    deleteByDate,
  };
}