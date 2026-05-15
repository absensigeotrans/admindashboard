'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '@/context/AuthContext';
import { useGeolocation } from '@/hooks/useGeolocation';
import { useAttendance } from '@/hooks/useAttendance';
import { useOffices } from '@/hooks/useOffices';
import { DigitalClock } from './DigitalClock';
import { DistanceIndicator } from './DistanceIndicator';
import { AttendanceButton } from './AttendanceButton';
import { Map } from './Map';
import { Toast } from './Toast';
import { calculateDistance, formatDistance } from '@/lib/utils';
import { MapPin, RefreshCw, History, LogOut } from 'lucide-react';
import Link from 'next/link';

export function AttendancePage() {
  const { user, profile, loading: authLoading, signOut } = useAuth();
  const { location, error: geoError, loading: geoLoading, requestLocation } = useGeolocation();
  const { currentOffice, fetchOffices } = useOffices();
  const { todayAttendance, loading: attendanceLoading, clockIn, clockOut, fetchTodayAttendance } = useAttendance();
  
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    fetchOffices();
    fetchTodayAttendance();
  }, [fetchOffices, fetchTodayAttendance]);

  useEffect(() => {
    if (geoError) {
      setToast({ message: geoError, type: 'error' });
    }
  }, [geoError]);

  // Calculate distance to office
  const distance = location && currentOffice
    ? calculateDistance(
        location.latitude,
        location.longitude,
        currentOffice.latitude,
        currentOffice.longitude
      )
    : null;

  const isWithinRange = distance !== null && currentOffice && distance <= currentOffice.geofence_radius;

  const handleClockIn = async () => {
    if (!location) {
      setToast({ message: 'Location required. Please enable GPS.', type: 'error' });
      return;
    }

    setActionLoading(true);
    const result = await clockIn(location.latitude, location.longitude);
    setActionLoading(false);

    if (result.success) {
      setToast({ message: 'Clocked in successfully!', type: 'success' });
    } else {
      setToast({ message: result.error || 'Failed to clock in', type: 'error' });
    }
  };

  const handleClockOut = async () => {
    if (!todayAttendance) return;

    setActionLoading(true);
    const result = await clockOut(todayAttendance.id);
    setActionLoading(false);

    if (result.success) {
      setToast({ message: 'Clocked out successfully!', type: 'success' });
    } else {
      setToast({ message: result.error || 'Failed to clock out', type: 'error' });
    }
  };

  const handleSignOut = async () => {
    await signOut();
    window.location.href = '/login';
  };

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!user) {
    if (typeof window !== 'undefined') {
      window.location.href = '/login';
    }
    return null;
  }

  const hasCheckedIn = todayAttendance && !todayAttendance.check_out_time;
  const hasCheckedOut = todayAttendance?.check_out_time;

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">GeoAttend Pro</h1>
            <p className="text-sm text-gray-500">Pertamina Trans Kontinental</p>
          </div>
          <div className="flex items-center gap-3">
            {profile?.role === 'admin' && (
              <Link
                href="/admin"
                className="px-3 py-2 text-sm font-medium text-gray-700 hover:text-blue-600 transition-colors"
              >
                Admin
              </Link>
            )}
            <Link
              href="/history"
              className="p-2 text-gray-600 hover:text-blue-600 transition-colors"
              title="Attendance History"
            >
              <History className="w-5 h-5" />
            </Link>
            <button
              onClick={handleSignOut}
              className="p-2 text-gray-600 hover:text-red-600 transition-colors"
              title="Sign Out"
            >
              <LogOut className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 py-6">
        {/* Welcome */}
        <div className="mb-6">
          <h2 className="text-lg font-semibold text-gray-900">
            Welcome, {profile?.full_name || user.email}
          </h2>
          <p className="text-sm text-gray-500">{profile?.department || 'Employee'}</p>
        </div>

        {/* Digital Clock */}
        <div className="bg-white rounded-xl shadow-sm border p-6 mb-6">
          <DigitalClock />
        </div>

        {/* Location Status */}
        <div className="bg-white rounded-xl shadow-sm border p-6 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-gray-900 flex items-center gap-2">
              <MapPin className="w-5 h-5" />
              Location Status
            </h3>
            <button
              onClick={requestLocation}
              disabled={geoLoading}
              className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-blue-600 hover:bg-blue-50 rounded-lg transition-colors disabled:opacity-50"
            >
              <RefreshCw className={`w-4 h-4 ${geoLoading ? 'animate-spin' : ''}`} />
              Refresh Location
            </button>
          </div>

          {currentOffice && (
            <div className="space-y-4">
              <p className="text-sm text-gray-600">
                Office: <span className="font-medium">{currentOffice.name}</span>
                <br />
                Geofence Radius: {formatDistance(currentOffice.geofence_radius)}
              </p>

              <DistanceIndicator
                distance={distance}
                radius={currentOffice.geofence_radius}
              />

              {/* Map */}
              <div className="mt-4">
                <Map
                  office={currentOffice}
                  userLocation={location}
                  height="300px"
                />
              </div>
            </div>
          )}

          {!currentOffice && (
            <p className="text-yellow-600 bg-yellow-50 p-3 rounded-lg">
              No office location configured. Please contact admin.
            </p>
          )}
        </div>

        {/* Attendance Actions */}
        <div className="bg-white rounded-xl shadow-sm border p-6">
          <h3 className="font-semibold text-gray-900 mb-4">Attendance</h3>

          {todayAttendance && (
            <div className="mb-4 p-3 bg-gray-50 rounded-lg">
              <p className="text-sm text-gray-600">
                <span className="font-medium">Check In:</span>{' '}
                {new Date(todayAttendance.check_in_time).toLocaleTimeString()}
              </p>
              {todayAttendance.check_out_time && (
                <p className="text-sm text-gray-600 mt-1">
                  <span className="font-medium">Check Out:</span>{' '}
                  {new Date(todayAttendance.check_out_time).toLocaleTimeString()}
                </p>
              )}
              <p className="text-sm text-gray-600 mt-1">
                <span className="font-medium">Status:</span>{' '}
                <span className={
                  todayAttendance.status === 'present' ? 'text-green-600' :
                  todayAttendance.status === 'late' ? 'text-yellow-600' :
                  'text-red-600'
                }>
                  {todayAttendance.status.replace('_', ' ')}
                </span>
              </p>
              <p className="text-sm text-gray-600 mt-1">
                <span className="font-medium">Distance:</span>{' '}
                {formatDistance(todayAttendance.distance_from_office)}
              </p>
            </div>
          )}

          <div className="space-y-3">
            {!hasCheckedIn && !hasCheckedOut && (
              <AttendanceButton
                type="in"
                disabled={!isWithinRange || actionLoading}
                loading={actionLoading}
                onClick={handleClockIn}
              />
            )}

            {hasCheckedIn && (
              <AttendanceButton
                type="out"
                disabled={actionLoading}
                loading={actionLoading}
                onClick={handleClockOut}
              />
            )}

            {hasCheckedOut && (
              <div className="p-4 bg-green-50 border border-green-200 rounded-xl text-center">
                <p className="text-green-700 font-medium">
                  Attendance completed for today!
                </p>
                <p className="text-sm text-green-600 mt-1">
                  See you tomorrow!
                </p>
              </div>
            )}
          </div>

          {!location && !geoLoading && (
            <p className="text-sm text-gray-500 text-center mt-4">
              Please allow location access to clock in/out
            </p>
          )}
        </div>
      </main>

      {/* Toast */}
      {toast && (
        <Toast
          message={toast.message}
          type={toast.type}
          onClose={() => setToast(null)}
        />
      )}
    </div>
  );
}
