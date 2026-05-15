'use client';

import { useEffect, useState } from 'react';
import { useAttendance } from '@/hooks/useAttendance';
import { useOffices } from '@/hooks/useOffices';
import { useEmployees } from '@/hooks/useEmployees';
import { supabase } from '@/lib/supabase';
import { StatsCard } from '@/components/ui/StatsCard';
import { formatDistance } from '@/lib/utils';
import { format, startOfWeek, endOfWeek, startOfMonth, endOfMonth } from 'date-fns';
import {
  CheckCircle, Clock, XCircle, Users, Building2, MapPin,
  TrendingUp, Calendar, ArrowUpRight,
} from 'lucide-react';
import Link from 'next/link';

interface WeeklyStats {
  totalClockIns: number;
  avgCheckIn: string;
  avgDistance: number;
  lateRate: string;
}

export default function AdminDashboard() {
  const { history, fetchHistory } = useAttendance();
  const { offices, fetchOffices } = useOffices();
  const { fetchEmployees } = useEmployees();
  const [weeklyStats, setWeeklyStats] = useState<WeeklyStats>({
    totalClockIns: 0, avgCheckIn: '--:--', avgDistance: 0, lateRate: '0%',
  });
  const [monthlyStats, setMonthlyStats] = useState({ present: 0, late: 0, outside: 0 });
  const [recentActivity, setRecentActivity] = useState<unknown[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      fetchHistory(500),
      fetchOffices(),
      fetchEmployees(1, 10),
    ]).then(() => setLoading(false));
  }, [fetchHistory, fetchOffices, fetchEmployees]);

  useEffect(() => {
    if (history.length === 0) return;

    // Today's stats
    const today = new Date().toISOString().split('T')[0];
    const todayRecords = history.filter((h) => h.check_in_time.startsWith(today));

    // Weekly stats
    const now = new Date();
    const weekStart = startOfWeek(now, { weekStartsOn: 1 });
    const weekEnd = endOfWeek(now, { weekStartsOn: 1 });
    const weekRecords = history.filter((h) => {
      const d = new Date(h.check_in_time);
      return d >= weekStart && d <= weekEnd;
    });

    // Monthly stats
    const monthStart = startOfMonth(now);
    const monthEnd = endOfMonth(now);
    const monthRecords = history.filter((h) => {
      const d = new Date(h.check_in_time);
      return d >= monthStart && d <= monthEnd;
    });

    const avgDistance = weekRecords.length > 0
      ? weekRecords.reduce((s, r) => s + r.distance_from_office, 0) / weekRecords.length
      : 0;

    const avgHour = weekRecords.length > 0
      ? weekRecords.reduce((s, r) => {
          const d = new Date(r.check_in_time);
          return s + d.getHours() + d.getMinutes() / 60;
        }, 0) / weekRecords.length
      : 9;

    const lateCount = weekRecords.filter((r) => r.status === 'late').length;
    const lateRate = weekRecords.length > 0
      ? Math.round((lateCount / weekRecords.length) * 100)
      : 0;

    const mPresent = monthRecords.filter((r) => r.status === 'present').length;
    const mLate = monthRecords.filter((r) => r.status === 'late').length;
    const mOutside = monthRecords.filter((r) => r.status === 'outside_radius').length;

    setWeeklyStats({
      totalClockIns: weekRecords.length,
      avgCheckIn: `${Math.floor(avgHour).toString().padStart(2, '0')}:${Math.round((avgHour % 1) * 60).toString().padStart(2, '0')}`,
      avgDistance,
      lateRate: `${lateRate}%`,
    });

    setMonthlyStats({ present: mPresent, late: mLate, outside: mOutside });

    // Recent activity (today)
    setRecentActivity(
      todayRecords.slice(0, 8).map((r) => ({
        ...r,
        time: format(new Date(r.check_in_time), 'HH:mm'),
        distance: formatDistance(r.distance_from_office),
      }))
    );
  }, [history]);

  const today = new Date().toISOString().split('T')[0];
  const todayPresent = history.filter((h) => h.check_in_time.startsWith(today) && h.status === 'present').length;
  const todayLate = history.filter((h) => h.check_in_time.startsWith(today) && h.status === 'late').length;
  const todayOutside = history.filter((h) => h.check_in_time.startsWith(today) && h.status === 'outside_radius').length;

  // Fetch employee count
  const [employeeCount, setEmployeeCount] = useState(0);
  useEffect(() => {
    supabase.from('profiles').select('id', { count: 'exact', head: true })
      .then(({ count }) => setEmployeeCount(count || 0));
  }, []);

  return (
    <div className="space-y-6">
      {/* Today's Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          icon={<CheckCircle className="w-6 h-6" />}
          value={todayPresent}
          label="Present Today"
          color="green"
        />
        <StatsCard
          icon={<Clock className="w-6 h-6" />}
          value={todayLate}
          label="Late Today"
          color="yellow"
        />
        <StatsCard
          icon={<XCircle className="w-6 h-6" />}
          value={todayOutside}
          label="Outside Radius"
          color="red"
        />
        <StatsCard
          icon={<Users className="w-6 h-6" />}
          value={employeeCount}
          label="Total Employees"
          color="blue"
        />
      </div>

      {/* This Week */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard
          icon={<TrendingUp className="w-6 h-6" />}
          value={weeklyStats.totalClockIns}
          label="Clock-ins This Week"
          color="blue"
        />
        <StatsCard
          icon={<Clock className="w-6 h-6" />}
          value={weeklyStats.avgCheckIn}
          label="Avg Check-in Time"
          color="purple"
        />
        <StatsCard
          icon={<MapPin className="w-6 h-6" />}
          value={formatDistance(weeklyStats.avgDistance)}
          label="Avg Distance"
          color="yellow"
        />
        <StatsCard
          icon={<XCircle className="w-6 h-6" />}
          value={weeklyStats.lateRate}
          label="Late Rate (Week)"
          color="red"
        />
      </div>

      {/* Quick Actions + Office Info */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Active Office */}
        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
            <Building2 className="w-5 h-5 text-blue-600" />
            Active Office
          </h3>
          {offices.length > 0 ? (
            <div className="space-y-2">
              <p className="font-medium text-gray-900">{offices[0].name}</p>
              <p className="text-sm text-gray-500">
                {offices[0].latitude.toFixed(6)}, {offices[0].longitude.toFixed(6)}
              </p>
              <p className="text-sm text-gray-500">
                Radius: {formatDistance(offices[0].geofence_radius)}
              </p>
            </div>
          ) : (
            <p className="text-yellow-600 bg-yellow-50 p-3 rounded-lg text-sm">
              No office configured.{" "}
              <Link href="/admin/offices" className="underline font-medium">Add one now</Link>
            </p>
          )}
        </div>

        {/* This Month Summary */}
        <div className="bg-white rounded-xl shadow-sm border p-5">
          <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
            <Calendar className="w-5 h-5 text-blue-600" />
            This Month ({format(new Date(), 'MMMM yyyy')})
          </h3>
          <div className="grid grid-cols-3 gap-3 text-center">
            <div className="bg-green-50 rounded-lg p-3">
              <p className="text-xl font-bold text-green-700">{monthlyStats.present}</p>
              <p className="text-xs text-green-600">Present</p>
            </div>
            <div className="bg-yellow-50 rounded-lg p-3">
              <p className="text-xl font-bold text-yellow-700">{monthlyStats.late}</p>
              <p className="text-xs text-yellow-600">Late</p>
            </div>
            <div className="bg-red-50 rounded-lg p-3">
              <p className="text-xl font-bold text-red-700">{monthlyStats.outside}</p>
              <p className="text-xs text-red-600">Outside</p>
            </div>
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="px-5 py-4 border-b flex items-center justify-between">
          <h3 className="font-semibold text-gray-900">Today&apos;s Activity</h3>
          <Link
            href="/admin/reports"
            className="text-sm text-blue-600 hover:text-blue-700 flex items-center gap-1"
          >
            View Reports <ArrowUpRight className="w-4 h-4" />
          </Link>
        </div>
        {recentActivity.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            No attendance records today
          </div>
        ) : (
          <div className="divide-y">
            {recentActivity.map((record: unknown) => {
              const r = record as { id: string; check_in_time: string; status: string; time: string; distance: string };
              return (
                <div key={r.id} className="px-5 py-3 hover:bg-gray-50 flex items-center justify-between">
                  <div>
                    <p className="text-sm font-medium text-gray-900">
                      {format(new Date(r.check_in_time), 'HH:mm')}
                    </p>
                    <p className="text-xs text-gray-500">{r.distance}</p>
                  </div>
                  <span className={`
                    px-2 py-0.5 rounded-full text-xs font-medium
                    ${r.status === 'present' ? 'bg-green-100 text-green-700' :
                      r.status === 'late' ? 'bg-yellow-100 text-yellow-700' :
                      'bg-red-100 text-red-700'}
                  `}>
                    {r.status.replace('_', ' ')}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}