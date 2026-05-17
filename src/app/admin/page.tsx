'use client';

import { useEffect, useState } from 'react';
import { useAttendance } from '@/hooks/useAttendance';
import { useOffices } from '@/hooks/useOffices';
import { useEmployees } from '@/hooks/useEmployees';
import { useDashboardAnalytics, Period } from '@/hooks/useDashboardAnalytics';
import { supabase } from '@/lib/supabase';
import { StatsCard } from '@/components/ui/StatsCard';
import { ChartCard } from '@/components/admin/ChartCard';
import { formatDistance } from '@/lib/utils';
import { format, startOfWeek, endOfWeek, startOfMonth, endOfMonth } from 'date-fns';
import {
  CheckCircle, Clock, XCircle, Users, Building2, MapPin,
  TrendingUp, Calendar, ArrowUpRight, AlertTriangle,
} from 'lucide-react';
import Link from 'next/link';
import {
  PieChart, Pie, Cell,
  BarChart, Bar, XAxis, YAxis, CartesianGrid,
  LineChart, Line,
  Tooltip, Legend, ResponsiveContainer,
} from 'recharts';
import type { PieLabelRenderProps } from 'recharts';

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
  const [monthlyStats, setMonthlyStats] = useState({ present: 0, late: 0, outside: 0, suspicious: 0 });
  const [weeklySuspicious, setWeeklySuspicious] = useState(0);
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
    const mSuspicious = monthRecords.filter((r) => r.is_mocked).length;

    setWeeklySuspicious(weekRecords.filter((r) => r.is_mocked).length);

    setWeeklyStats({
      totalClockIns: weekRecords.length,
      avgCheckIn: `${Math.floor(avgHour).toString().padStart(2, '0')}:${Math.round((avgHour % 1) * 60).toString().padStart(2, '0')}`,
      avgDistance,
      lateRate: `${lateRate}%`,
    });

    setMonthlyStats({ present: mPresent, late: mLate, outside: mOutside, suspicious: mSuspicious });

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

  const analytics = useDashboardAnalytics();

  const PIE_COLORS = ['#22c55e', '#eab308', '#ef4444'];
  const periods: { value: Period; label: string }[] = [
    { value: 'today', label: 'Today' },
    { value: '7d', label: '7 Days' },
    { value: '30d', label: '30 Days' },
    { value: 'custom', label: 'Custom' },
  ];

  const renderPeriodFilter = () => (
    <div className="flex items-center gap-2 flex-wrap">
      {periods.map((p) => (
        <button
          key={p.value}
          onClick={() => analytics.setPeriod(p.value)}
          className={`px-3 py-1.5 text-sm rounded-lg font-medium transition-colors ${
            analytics.period === p.value
              ? 'bg-blue-600 text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          {p.label}
        </button>
      ))}
      {analytics.period === 'custom' && (
        <div className="flex items-center gap-2">
          <input
            type="date"
            value={analytics.customStart}
            onChange={(e) => analytics.setCustomStart(e.target.value)}
            className="px-2 py-1.5 text-sm border rounded-lg"
          />
          <span className="text-gray-400">to</span>
          <input
            type="date"
            value={analytics.customEnd}
            onChange={(e) => analytics.setCustomEnd(e.target.value)}
            className="px-2 py-1.5 text-sm border rounded-lg"
          />
        </div>
      )}
    </div>
  );

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
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
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
        <StatsCard
          icon={<AlertTriangle className="w-6 h-6" />}
          value={weeklySuspicious}
          label="Kejanggalan (Week)"
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
          <div className="grid grid-cols-4 gap-3 text-center">
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
            <div className="bg-orange-50 rounded-lg p-3">
              <p className="text-xl font-bold text-orange-700">{monthlyStats.suspicious}</p>
              <p className="text-xs text-orange-600">Kejanggalan</p>
            </div>
          </div>
        </div>
      </div>

      {/* Dashboard Analytics */}
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Analytics</h2>
          {renderPeriodFilter()}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Pie Chart - Status Distribution */}
          <ChartCard
            title="Status Distribution"
            subtitle="Present vs Late vs Outside Radius"
            loading={analytics.loading}
            error={analytics.error}
          >
            {analytics.data ? (
              <ResponsiveContainer width="100%" height={260}>
                <PieChart>
                  <Pie
                    data={[
                      { name: 'Present', value: analytics.data.statusDistribution.present },
                      { name: 'Late', value: analytics.data.statusDistribution.late },
                      { name: 'Outside', value: analytics.data.statusDistribution.outside },
                    ]}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={90}
                    dataKey="value"
                    label={(entry: PieLabelRenderProps) =>
                      `${entry.name ?? ''} ${((entry.percent ?? 0) * 100).toFixed(0)}%`}
                  >
                    {PIE_COLORS.map((color, idx) => (
                      <Cell key={idx} fill={color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => [value ?? 0, 'Records']} />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-48 text-gray-400 text-sm">
                No data for this period
              </div>
            )}
          </ChartCard>

          {/* Bar Chart - Daily Attendance */}
          <ChartCard
            title="Daily Attendance"
            subtitle="Per-day breakdown for selected period"
            loading={analytics.loading}
            error={analytics.error}
          >
            {analytics.data && analytics.data.dailyAttendance.length > 0 ? (
              <ResponsiveContainer width="100%" height={260}>
                <BarChart data={analytics.data.dailyAttendance}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                  <XAxis
                    dataKey="date"
                    tickFormatter={(d) => format(new Date(String(d)), 'dd MMM')}
                    tick={{ fontSize: 11 }}
                  />
                  <YAxis tick={{ fontSize: 11 }} />
                  <Tooltip
                    labelFormatter={(d) => format(new Date(String(d)), 'dd MMM yyyy')}
                  />
                  <Legend />
                  <Bar dataKey="present" name="Present" stackId="a" fill="#22c55e" />
                  <Bar dataKey="late" name="Late" stackId="a" fill="#eab308" />
                  <Bar dataKey="outside" name="Outside" stackId="a" fill="#ef4444" />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-48 text-gray-400 text-sm">
                No attendance records for this period
              </div>
            )}
          </ChartCard>
        </div>

        {/* Line Chart - Late Trend */}
        <ChartCard
          title="Late Trend"
          subtitle="Daily late attendance count"
          loading={analytics.loading}
          error={analytics.error}
        >
          {analytics.data && analytics.data.lateTrend.length > 0 ? (
            <ResponsiveContainer width="100%" height={220}>
              <LineChart data={analytics.data.lateTrend}>
                <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
                <XAxis
                  dataKey="date"
                  tickFormatter={(d) => format(new Date(String(d)), 'dd MMM')}
                  tick={{ fontSize: 11 }}
                />
                <YAxis tick={{ fontSize: 11 }} allowDecimals={false} />
                <Tooltip
                  labelFormatter={(d) => format(new Date(String(d)), 'dd MMM yyyy')}
                />
                <Legend />
                <Line
                  type="monotone"
                  dataKey="lateCount"
                  name="Late Count"
                  stroke="#eab308"
                  strokeWidth={2}
                  dot={{ fill: '#eab308', r: 3 }}
                />
                {analytics.data.lateTrend.some((d) => d.avgLateMinutes > 0) && (
                  <Line
                    type="monotone"
                    dataKey="avgLateMinutes"
                    name="Avg Late (min)"
                    stroke="#f97316"
                    strokeWidth={2}
                    dot={{ fill: '#f97316', r: 3 }}
                    strokeDasharray="5 5"
                  />
                )}
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="flex items-center justify-center h-48 text-gray-400 text-sm">
              No late records for this period
            </div>
          )}
        </ChartCard>
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