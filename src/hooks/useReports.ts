import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Attendance, AttendanceStatus } from '@/types';

interface ReportFilters {
  from?: string;
  to?: string;
  status?: AttendanceStatus;
  search?: string;
}

export function useReports() {
  const [records, setRecords] = useState<Attendance[]>([]);
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
        .select('*', { count: 'exact' })
        .order('check_in_time', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

      if (filters.from) {
        query = query.gte('check_in_time', filters.from);
      }
      if (filters.to) {
        const toDate = new Date(filters.to);
        toDate.setDate(toDate.getDate() + 1);
        query = query.lt('check_in_time', toDate.toISOString());
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      const { data, error: fetchError, count } = await query;
      if (fetchError) throw fetchError;

      let result = data as Attendance[] || [];

      // Client-side search filter
      if (filters.search) {
        // Note: Would ideally join with profiles on server-side
        // For now we return all and let the report page handle it
        result = result;
      }

      setRecords(result);
      return { data: result, count: count || 0 };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch report';
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
    setLoading(true);
    setError(null);
    try {
      let query = supabase
        .from('attendance')
        .select('*, profiles:user_id(full_name, email, department)')
        .order('check_in_time', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

      if (filters.from) {
        query = query.gte('check_in_time', filters.from);
      }
      if (filters.to) {
        const toDate = new Date(filters.to);
        toDate.setDate(toDate.getDate() + 1);
        query = query.lt('check_in_time', toDate.toISOString());
      }
      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      const { data, error: fetchError, count } = await query;
      if (fetchError) throw fetchError;

      setRecords(data as Attendance[] || []);
      return { data: data as Attendance[], count: count || 0 };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch report';
      setError(msg);
      return { data: [], count: 0 };
    } finally {
      setLoading(false);
    }
  }, []);

  const getStats = useCallback((data: Attendance[]) => {
    const total = data.length;
    const present = data.filter((r) => r.status === 'present').length;
    const late = data.filter((r) => r.status === 'late').length;
    const outside = data.filter((r) => r.status === 'outside_radius').length;
    const suspicious = data.filter((r) => r.is_mocked).length;
    const avgDistance = total > 0
      ? data.reduce((sum, r) => sum + r.distance_from_office, 0) / total
      : 0;

    return { total, present, late, outside, suspicious, avgDistance };
  }, []);

  return {
    records,
    loading,
    error,
    fetchReport,
    fetchReportWithUsers,
    getStats,
  };
}