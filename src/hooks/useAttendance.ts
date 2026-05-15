'use client';

import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Attendance, AttendanceStatus } from '@/types';

interface UseAttendanceReturn {
  todayAttendance: Attendance | null;
  history: Attendance[];
  loading: boolean;
  error: string | null;
  clockIn: (latitude: number, longitude: number) => Promise<{ success: boolean; error?: string }>;
  clockOut: (attendanceId: string) => Promise<{ success: boolean; error?: string }>;
  fetchTodayAttendance: () => Promise<void>;
  fetchHistory: (limit?: number) => Promise<void>;
}

export function useAttendance(): UseAttendanceReturn {
  const [todayAttendance, setTodayAttendance] = useState<Attendance | null>(null);
  const [history, setHistory] = useState<Attendance[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchTodayAttendance = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const today = new Date().toISOString().split('T')[0];
      const { data, error: fetchError } = await supabase
        .from('attendance')
        .select('*')
        .gte('check_in_time', today)
        .order('check_in_time', { ascending: false })
        .limit(1)
        .single();

      if (fetchError && fetchError.code !== 'PGRST116') {
        throw fetchError;
      }

      setTodayAttendance((data as Attendance | null) ?? null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch attendance');
    } finally {
      setLoading(false);
    }
  }, []);

  const fetchHistory = useCallback(async (limit = 30) => {
    setLoading(true);
    setError(null);

    try {
      const { data, error: fetchError } = await supabase
        .from('attendance')
        .select('*')
        .order('check_in_time', { ascending: false })
        .limit(limit);

      if (fetchError) throw fetchError;

      setHistory(data as Attendance[] || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch history');
    } finally {
      setLoading(false);
    }
  }, []);

  const clockIn = useCallback(async (latitude: number, longitude: number) => {
    setLoading(true);
    setError(null);

    try {
      const { data, error: insertError } = await supabase
        .from('attendance')
        .insert([{
          latitude,
          longitude,
          distance_from_office: 0,
        }])
        .select()
        .single();

      if (insertError) throw insertError;

      setTodayAttendance(data as Attendance);
      return { success: true };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to clock in';
      setError(message);
      return { success: false, error: message };
    } finally {
      setLoading(false);
    }
  }, []);

  const clockOut = useCallback(async (attendanceId: string) => {
    setLoading(true);
    setError(null);

    try {
      const { error: updateError } = await supabase
        .from('attendance')
        .update({ check_out_time: new Date().toISOString() })
        .eq('id', attendanceId);

      if (updateError) throw updateError;

      await fetchTodayAttendance();
      return { success: true };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to clock out';
      setError(message);
      return { success: false, error: message };
    } finally {
      setLoading(false);
    }
  }, [fetchTodayAttendance]);

  return {
    todayAttendance,
    history,
    loading,
    error,
    clockIn,
    clockOut,
    fetchTodayAttendance,
    fetchHistory,
  };
}
