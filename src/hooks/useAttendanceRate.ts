'use client';

import { useState, useCallback, useEffect, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { Attendance, Profile } from '@/types';

export type Period = '7d' | '30d' | 'custom';

export interface EmployeeStat {
  id: string;
  fullName: string;
  department: string | null;
  present: number;
  late: number;
  outside: number;
  absent: number;
  workingDays: number;
  attendanceRate: number;
  lateRate: number;
}

function countWorkingDays(start: Date, end: Date): number {
  let count = 0;
  const d = new Date(start);
  while (d <= end) {
    const day = d.getDay();
    if (day !== 0 && day !== 6) count++;
    d.setDate(d.getDate() + 1);
  }
  return count;
}

interface UseAttendanceRateReturn {
  stats: EmployeeStat[];
  loading: boolean;
  error: string | null;
  period: Period;
  setPeriod: (p: Period) => void;
  customStart: string;
  setCustomStart: (s: string) => void;
  customEnd: string;
  setCustomEnd: (s: string) => void;
  avgRate: number;
  mostLate: EmployeeStat | null;
  bestAttendee: EmployeeStat | null;
  totalAbsent: number;
}

export function useAttendanceRate(): UseAttendanceRateReturn {
  const [stats, setStats] = useState<EmployeeStat[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [period, setPeriod] = useState<Period>('30d');
  const [customStart, setCustomStart] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d.toISOString().split('T')[0];
  });
  const [customEnd, setCustomEnd] = useState(() =>
    new Date().toISOString().split('T')[0]
  );
  const mountedRef = useRef(true);

  const compute = useCallback(async (from: string, to: string) => {
    setLoading(true);
    setError(null);
    try {
      const { data: employees, error: empErr } = await supabase
        .from('profiles')
        .select('id, full_name, department')
        .eq('role', 'employee')
        .order('full_name');

      if (empErr) throw empErr;
      if (!mountedRef.current) return;

      const empList = (employees || []) as Pick<Profile, 'id' | 'full_name' | 'department'>[];

      if (empList.length === 0) {
        setStats([]);
        return;
      }

      const toDate = new Date(to);
      toDate.setDate(toDate.getDate() + 1);
      const toISO = toDate.toISOString();

      const { data: attendance, error: attErr } = await supabase
        .from('attendance')
        .select('user_id, status')
        .gte('check_in_time', from)
        .lt('check_in_time', toISO);

      if (attErr) throw attErr;
      if (!mountedRef.current) return;

      const records = (attendance || []) as Pick<Attendance, 'user_id' | 'status'>[];

      const workingDays = countWorkingDays(new Date(from), new Date(to));

      const userAttendance: Record<string, { present: number; late: number; outside: number }> = {};
      for (const rec of records) {
        if (!userAttendance[rec.user_id]) {
          userAttendance[rec.user_id] = { present: 0, late: 0, outside: 0 };
        }
        if (rec.status === 'present') userAttendance[rec.user_id].present++;
        else if (rec.status === 'late') userAttendance[rec.user_id].late++;
        else if (rec.status === 'outside_radius') userAttendance[rec.user_id].outside++;
      }

      const computed: EmployeeStat[] = empList.map((emp) => {
        const ua = userAttendance[emp.id] || { present: 0, late: 0, outside: 0 };
        const daysPresent = ua.present + ua.late;
        const absent = Math.max(0, workingDays - daysPresent);
        const attendanceRate = workingDays > 0
          ? Math.round((daysPresent / workingDays) * 100)
          : 0;
        const lateRate = daysPresent > 0
          ? Math.round((ua.late / daysPresent) * 100)
          : 0;
        return {
          id: emp.id,
          fullName: emp.full_name,
          department: emp.department,
          present: ua.present,
          late: ua.late,
          outside: ua.outside,
          absent,
          workingDays,
          attendanceRate,
          lateRate,
        };
      });

      computed.sort((a, b) => a.attendanceRate - b.attendanceRate);

      if (mountedRef.current) {
        setStats(computed);
      }
    } catch (err) {
      if (mountedRef.current) {
        setError(err instanceof Error ? err.message : 'Failed to compute stats');
      }
    } finally {
      if (mountedRef.current) {
        setLoading(false);
      }
    }
  }, []);

  const load = useCallback(async () => {
    let from: string;
    let to: string;
    if (period === '7d') {
      const d = new Date();
      d.setDate(d.getDate() - 7);
      from = d.toISOString().split('T')[0];
      to = new Date().toISOString().split('T')[0];
    } else if (period === '30d') {
      const d = new Date();
      d.setDate(d.getDate() - 30);
      from = d.toISOString().split('T')[0];
      to = new Date().toISOString().split('T')[0];
    } else {
      from = customStart;
      to = customEnd;
    }
    await compute(from, to);
  }, [period, customStart, customEnd, compute]);

  useEffect(() => {
    mountedRef.current = true;
    load();
    return () => { mountedRef.current = false; };
  }, [load]);

  const avgRate = stats.length > 0
    ? Math.round(stats.reduce((s, e) => s + e.attendanceRate, 0) / stats.length)
    : 0;

  const mostLate = stats.length > 0
    ? stats.reduce((a, b) => (a.late > b.late ? a : b))
    : null;

  const bestAttendee = stats.length > 0
    ? stats.reduce((a, b) => (a.attendanceRate > b.attendanceRate ? a : b))
    : null;

  const totalAbsent = stats.reduce((s, e) => s + e.absent, 0);

  return {
    stats,
    loading,
    error,
    period,
    setPeriod,
    customStart,
    setCustomStart,
    customEnd,
    setCustomEnd,
    avgRate,
    mostLate,
    bestAttendee,
    totalAbsent,
  };
}
