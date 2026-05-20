-- Migration 002: Admin Settings Table
-- Adds a configurable settings table so admin can adjust late threshold & default geofence radius

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

-- Update the validate_attendance_geofence trigger to read from settings
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
$$ LANGUAGE plpgsql;
