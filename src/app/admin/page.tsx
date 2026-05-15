'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useAttendance } from '@/hooks/useAttendance';
import { useOffices } from '@/hooks/useOffices';
import { formatDistance } from '@/lib/utils';
import { format } from 'date-fns';
import {
  ArrowLeft,
  Users,
  MapPin,
  CheckCircle,
  XCircle,
  Clock,
  Building2,
  Settings,
  ChevronRight,
} from 'lucide-react';
import Link from 'next/link';

interface Stats {
  totalPresent: number;
  totalLate: number;
  totalOutside: number;
}

export default function AdminPage() {
  const { user, profile, loading: authLoading } = useAuth();
  const { history, fetchHistory } = useAttendance();
  const { offices, fetchOffices } = useOffices();
  const [stats, setStats] = useState<Stats>({ totalPresent: 0, totalLate: 0, totalOutside: 0 });

  useEffect(() => {
    fetchHistory(100);
    fetchOffices();
  }, [fetchHistory, fetchOffices]);

  useEffect(() => {
    const today = new Date().toISOString().split('T')[0];
    const todayRecords = history.filter(h => h.check_in_time.startsWith(today));

    setStats({
      totalPresent: todayRecords.filter(h => h.status === 'present').length,
      totalLate: todayRecords.filter(h => h.status === 'late').length,
      totalOutside: todayRecords.filter(h => h.status === 'outside_radius').length,
    });
  }, [history]);

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user || profile?.role !== 'admin') {
    if (typeof window !== 'undefined') {
      window.location.href = profile?.role === 'admin' ? '/login' : '/';
    }
    return null;
  }

  const recentAttendance = history.slice(0, 10);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link
            href="/"
            className="p-2 text-gray-600 hover:text-blue-600 transition-colors"
          >
            <ArrowLeft className="w-5 h-5" />
          </Link>
          <h1 className="text-xl font-bold text-gray-900">HR Dashboard</h1>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-6xl mx-auto px-4 py-6">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
          <div className="bg-white rounded-xl shadow-sm border p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-green-100 rounded-lg">
                <CheckCircle className="w-6 h-6 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.totalPresent}</p>
                <p className="text-sm text-gray-600">Present Today</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-yellow-100 rounded-lg">
                <Clock className="w-6 h-6 text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.totalLate}</p>
                <p className="text-sm text-gray-600">Late Today</p>
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border p-6">
            <div className="flex items-center gap-3">
              <div className="p-3 bg-red-100 rounded-lg">
                <XCircle className="w-6 h-6 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-gray-900">{stats.totalOutside}</p>
                <p className="text-sm text-gray-600">Outside Radius</p>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Links */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
          <Link
            href="/admin/employees"
            className="bg-white rounded-xl shadow-sm border p-6 hover:border-blue-300 transition-colors"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-blue-100 rounded-lg">
                  <Users className="w-6 h-6 text-blue-600" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Employees</p>
                  <p className="text-sm text-gray-600">Manage employee data</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </div>
          </Link>

          <Link
            href="/admin/offices"
            className="bg-white rounded-xl shadow-sm border p-6 hover:border-blue-300 transition-colors"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-purple-100 rounded-lg">
                  <Building2 className="w-6 h-6 text-purple-600" />
                </div>
                <div>
                  <p className="font-semibold text-gray-900">Office Locations</p>
                  <p className="text-sm text-gray-600">Manage geofence settings</p>
                </div>
              </div>
              <ChevronRight className="w-5 h-5 text-gray-400" />
            </div>
          </Link>
        </div>

        {/* Current Office */}
        <div className="bg-white rounded-xl shadow-sm border p-6 mb-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
            <MapPin className="w-5 h-5" />
            Active Office Location
          </h2>
          {offices.length > 0 ? (
            <div className="space-y-2">
              <p className="text-gray-900 font-medium">{offices[0].name}</p>
              <p className="text-sm text-gray-600">
                Coordinates: {offices[0].latitude.toFixed(6)}, {offices[0].longitude.toFixed(6)}
              </p>
              <p className="text-sm text-gray-600">
                Geofence Radius: {formatDistance(offices[0].geofence_radius)}
              </p>
            </div>
          ) : (
            <p className="text-yellow-600 bg-yellow-50 p-3 rounded-lg">
              No office location configured. Please add an office location.
            </p>
          )}
        </div>

        {/* Recent Attendance */}
        <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
          <div className="p-6 border-b">
            <h2 className="text-lg font-semibold text-gray-900">Recent Activity</h2>
          </div>
          <div className="divide-y">
            {recentAttendance.length === 0 ? (
              <p className="text-center py-8 text-gray-500">No recent attendance records</p>
            ) : (
              recentAttendance.map((record) => (
                <div key={record.id} className="p-4 hover:bg-gray-50">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-medium text-gray-900">
                        {format(new Date(record.check_in_time), 'MMM d, yyyy')}
                      </p>
                      <p className="text-sm text-gray-600">
                        {format(new Date(record.check_in_time), 'HH:mm')} - {formatDistance(record.distance_from_office)}
                      </p>
                    </div>
                    <span
                      className={`px-3 py-1 rounded-full text-sm font-medium ${
                        record.status === 'present'
                          ? 'bg-green-100 text-green-700'
                          : record.status === 'late'
                          ? 'bg-yellow-100 text-yellow-700'
                          : 'bg-red-100 text-red-700'
                      }`}
                    >
                      {record.status.replace('_', ' ')}
                    </span>
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
