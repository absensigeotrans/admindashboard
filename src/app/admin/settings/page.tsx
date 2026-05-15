'use client';

import { useEffect, useState } from 'react';
import { useAdminSettings } from '@/hooks/useAdminSettings';
import { Button } from '@/components/ui/Button';
import { FormInput } from '@/components/ui/FormInput';
import { toast } from '@/components/ui/Toast';
import { Settings, Clock, MapPin, Database, CheckCircle, AlertCircle } from 'lucide-react';

export default function SettingsPage() {
  const { settings, loading, synced, syncFromDB, updateSettings, resetSettings } = useAdminSettings();

  const [hour, setHour] = useState(settings.late_threshold_hour.toString());
  const [minute, setMinute] = useState(settings.late_threshold_minute.toString());
  const [radius, setRadius] = useState(settings.default_geofence_radius.toString());
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setHour(settings.late_threshold_hour.toString());
    setMinute(settings.late_threshold_minute.toString());
    setRadius(settings.default_geofence_radius.toString());
  }, [settings]);

  useEffect(() => {
    syncFromDB();
  }, [syncFromDB]);

  const handleSave = async () => {
    setSaving(true);
    await updateSettings({
      late_threshold_hour: parseInt(hour) || 9,
      late_threshold_minute: parseInt(minute) || 0,
      default_geofence_radius: parseInt(radius) || 100,
    });
    setSaving(false);
    toast.success('Settings saved' + (synced ? ' (synced to DB)' : ' (local only)'));
  };

  return (
    <div className="space-y-6 max-w-2xl">
      {/* Sync Status */}
      <div className={`flex items-center gap-2 px-4 py-3 rounded-xl border text-sm ${
        synced ? 'bg-green-50 border-green-200 text-green-700' : 'bg-yellow-50 border-yellow-200 text-yellow-700'
      }`}>
        {synced ? <CheckCircle className="w-4 h-4" /> : <AlertCircle className="w-4 h-4" />}
        <span>
          {synced
            ? 'Settings synced with database. Changes will apply to new attendance records.'
            : 'Settings stored locally only. Database table may not exist yet. Run migration 002 first.'}
        </span>
      </div>

      {/* Late Threshold */}
      <div className="bg-white rounded-xl shadow-sm border p-6 space-y-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Clock className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">Late Threshold</h3>
            <p className="text-sm text-gray-500">Employees checking in after this time are marked as "late"</p>
          </div>
        </div>

        <div className="flex items-center gap-3 pl-12">
          <div className="flex items-center gap-2">
            <label className="text-sm font-medium text-gray-700">Time:</label>
            <select
              value={hour}
              onChange={(e) => setHour(e.target.value)}
              className="px-3 py-2 border rounded-lg text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              {Array.from({ length: 24 }, (_, i) => (
                <option key={i} value={i}>{i.toString().padStart(2, '0')}</option>
              ))}
            </select>
            <span className="text-gray-500 font-medium">:</span>
            <select
              value={minute}
              onChange={(e) => setMinute(e.target.value)}
              className="px-3 py-2 border rounded-lg text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="0">00</option>
              <option value="15">15</option>
              <option value="30">30</option>
              <option value="45">45</option>
            </select>
          </div>
          <span className="text-gray-500 text-sm">
            ({parseInt(hour).toString().padStart(2, '0')}:{parseInt(minute).toString().padStart(2, '0')} = late)
          </span>
        </div>
      </div>

      {/* Default Geofence Radius */}
      <div className="bg-white rounded-xl shadow-sm border p-6 space-y-4">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-purple-100 rounded-lg">
            <MapPin className="w-5 h-5 text-purple-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">Default Geofence Radius</h3>
            <p className="text-sm text-gray-500">Default radius for new office locations (in meters)</p>
          </div>
        </div>

        <div className="pl-12">
          <FormInput
            label=""
            type="number"
            min="10"
            max="10000"
            value={radius}
            onChange={(e) => setRadius(e.target.value)}
            hint="Must be between 10 and 10000 meters"
            className="max-w-xs"
          />
        </div>
      </div>

      {/* System Info */}
      <div className="bg-white rounded-xl shadow-sm border p-6 space-y-3">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-gray-100 rounded-lg">
            <Database className="w-5 h-5 text-gray-600" />
          </div>
          <div>
            <h3 className="font-semibold text-gray-900">System Information</h3>
            <p className="text-sm text-gray-500">Database connection details</p>
          </div>
        </div>

        <div className="pl-12 space-y-2 text-sm">
          <div className="flex gap-4">
            <span className="text-gray-500">Supabase Project:</span>
            <span className="font-mono text-gray-700">yoykktgggvvoigrbtvhq</span>
          </div>
          <div className="flex gap-4">
            <span className="text-gray-500">App Version:</span>
            <span className="font-mono text-gray-700">1.0.0</span>
          </div>
          <div className="flex gap-4">
            <span className="text-gray-500">Settings Table:</span>
            <span className={synced ? 'text-green-600 font-medium' : 'text-yellow-600 font-medium'}>
              {synced ? 'Connected' : 'Not found (run migration 002)'}
            </span>
          </div>
        </div>
      </div>

      {/* Save Button */}
      <div className="flex gap-3">
        <Button onClick={handleSave} loading={saving} className="flex-1">
          <Settings className="w-4 h-4" /> Save Settings
        </Button>
        <Button variant="ghost" onClick={resetSettings}>
          Reset to Defaults
        </Button>
      </div>

      {/* Migration Guide */}
      {!synced && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl p-5 text-sm text-blue-800 space-y-2">
          <h4 className="font-semibold">Required: Run Database Migration</h4>
          <p>To enable settings sync with the database, run the following in your Supabase SQL editor:</p>
          <pre className="bg-white border rounded-lg p-3 text-xs overflow-x-auto mt-2">
{`-- supabase/migrations/002_admin_settings.sql
CREATE TABLE IF NOT EXISTS settings (
  id TEXT PRIMARY KEY DEFAULT 'app_settings',
  late_threshold_hour INTEGER DEFAULT 9,
  late_threshold_minute INTEGER DEFAULT 0,
  default_geofence_radius INTEGER DEFAULT 100,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO settings (id) VALUES ('app_settings') ON CONFLICT DO NOTHING;

ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admins can manage settings" ON settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Update the trigger to read from settings
CREATE OR REPLACE FUNCTION validate_attendance_geofence()
RETURNS TRIGGER AS $$
DECLARE
  office_record RECORD;
  settings_record RECORD;
  calculated_distance DOUBLE PRECISION;
  R_EARTH CONSTANT DOUBLE PRECISION := 6371000;
  d_lat DOUBLE PRECISION;
  d_lon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  SELECT * INTO office_record FROM offices LIMIT 1;
  SELECT * INTO settings_record FROM settings WHERE id = 'app_settings';

  IF office_record IS NULL THEN
    NEW.is_valid := FALSE;
    NEW.status := 'outside_radius';
    RETURN NEW;
  END IF;

  d_lat := RADIANS(NEW.latitude - office_record.latitude);
  d_lon := RADIANS(NEW.longitude - office_record.longitude);
  a := SIN(d_lat/2) * SIN(d_lat/2) +
       COS(RADIANS(office_record.latitude)) * COS(RADIANS(NEW.latitude)) *
       SIN(d_lon/2) * SIN(d_lon/2);
  c := 2 * ATAN2(SQRT(a), SQRT(1-a));
  calculated_distance := R_EARTH * c;
  NEW.distance_from_office := calculated_distance;

  IF calculated_distance <= office_record.geofence_radius THEN
    NEW.is_valid := TRUE;
    -- Use settings threshold
    IF EXTRACT(HOUR FROM NEW.check_in_time) > settings_record.late_threshold_hour
       OR (EXTRACT(HOUR FROM NEW.check_in_time) = settings_record.late_threshold_hour
           AND EXTRACT(MINUTE FROM NEW.check_in_time) >= settings_record.late_threshold_minute)
    THEN
      NEW.status := 'late';
    ELSE
      NEW.status := 'present';
    END IF;
  ELSE
    NEW.is_valid := FALSE;
    NEW.status := 'outside_radius';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;`}
          </pre>
        </div>
      )}
    </div>
  );
}