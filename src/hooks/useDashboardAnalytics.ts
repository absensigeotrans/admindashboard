'use client';

import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';

export interface StatusDistribution {
  present: number;
  late: number;
  outside: number;
}

export interface DailyAttendance {
  date: string;
  total: number;
  present: number;
  late: number;
  outside: number;
}

export interface LateTrend {
  date: string;
  lateCount: number;
  avgLateMinutes: number;
}

export interface DashboardAnalytics {
  statusDistribution: StatusDistribution;
  dailyAttendance: DailyAttendance[];
  lateTrend: LateTrend[];
}

export type Period = 'today' | '7d' | '30d' | 'custom';

export function useDashboardAnalytics() {
  const [data, setData] = useState<DashboardAnalytics | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [period, setPeriod] = useState<Period>('7d');
  const [customStart, setCustomStart] = useState<string>('');
  const [customEnd, setCustomEnd] = useState<string>('');

  const getDateRange = useCallback(() => {
    const now = new Date();
    const end = now.toISOString().split('T')[0];

    if (period === 'today') {
      return { start: end, end };
    }
    if (period === '7d') {
      const start = new Date(now);
      start.setDate(start.getDate() - 6);
      return { start: start.toISOString().split('T')[0], end };
    }
    if (period === '30d') {
      const start = new Date(now);
      start.setDate(start.getDate() - 29);
      return { start: start.toISOString().split('T')[0], end };
    }
    return { start: customStart || end, end: customEnd || end };
  }, [period, customStart, customEnd]);

  const fetchAnalytics = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const { start, end } = getDateRange();
      const { data: result, error: rpcError } = await supabase
        .rpc('get_dashboard_analytics', { start_date: start, end_date: end });

      if (rpcError) throw rpcError;
      setData(result as DashboardAnalytics);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch analytics';
      setError(msg);
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [getDateRange]);

  useEffect(() => {
    fetchAnalytics();
  }, [fetchAnalytics]);

  return {
    data,
    loading,
    error,
    period,
    setPeriod,
    customStart,
    setCustomStart,
    customEnd,
    setCustomEnd,
    refresh: fetchAnalytics,
  };
}
