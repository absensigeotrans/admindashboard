-- Add status column and type to attendance table
-- This migration fixes the mismatch between 005_create_attendance.sql (has status)
-- and 100_initial_schema.sql (missing status column)

-- Create attendance_status enum type if not exists
DO $$ BEGIN
  CREATE TYPE attendance_status AS ENUM ('present', 'late', 'outside_radius');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add status column to attendance table if not exists
DO $$ BEGIN
  ALTER TABLE public.attendance ADD COLUMN status attendance_status DEFAULT 'outside_radius';
EXCEPTION WHEN duplicate_column THEN NULL;
END $$;

-- Recreate the validate_attendance_geofence function
CREATE OR REPLACE FUNCTION public.validate_attendance_geofence()
RETURNS TRIGGER AS $$
DECLARE
  office_record RECORD;
  calculated_distance DOUBLE PRECISION;
  R_EARTH CONSTANT DOUBLE PRECISION := 6371000;
  d_lat DOUBLE PRECISION;
  d_lon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
  lat DOUBLE PRECISION;
  lon DOUBLE PRECISION;
  is_checkout BOOLEAN;
BEGIN
  -- Determine if this is a checkout (UPDATE with check_out_time being set)
  is_checkout := TG_OP = 'UPDATE' AND NEW.check_out_time IS NOT NULL AND OLD.check_out_time IS NULL;

  -- Get the first office (assuming single office setup)
  SELECT * INTO office_record FROM offices LIMIT 1;

  IF office_record IS NULL THEN
    IF NOT is_checkout THEN
      NEW.is_valid := FALSE;
      NEW.status := 'outside_radius';
    END IF;
    RETURN NEW;
  END IF;

  -- Use correct columns based on check-in vs check-out
  IF is_checkout THEN
    lat := NEW.check_out_latitude;
    lon := NEW.check_out_longitude;
  ELSE
    lat := NEW.check_in_latitude;
    lon := NEW.check_in_longitude;
  END IF;

  -- Skip validation if coordinates are null
  IF lat IS NULL OR lon IS NULL THEN
    IF NOT is_checkout THEN
      NEW.status := 'outside_radius';
    END IF;
    RETURN NEW;
  END IF;

  -- Haversine formula calculation
  d_lat := RADIANS(lat - office_record.latitude);
  d_lon := RADIANS(lon - office_record.longitude);
  a := SIN(d_lat/2) * SIN(d_lat/2) +
       COS(RADIANS(office_record.latitude)) * COS(RADIANS(lat)) *
       SIN(d_lon/2) * SIN(d_lon/2);
  c := 2 * ATAN2(SQRT(a), SQRT(1-a));
  calculated_distance := R_EARTH * c;

  NEW.distance_from_office := calculated_distance;

  IF calculated_distance <= office_record.geofence_radius THEN
    NEW.is_valid := TRUE;
    IF is_checkout THEN
      NEW.status := 'present';
    ELSIF EXTRACT(HOUR FROM NEW.check_in_time) >= 9 THEN
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

-- Drop and recreate trigger for both INSERT and UPDATE
DROP TRIGGER IF EXISTS validate_geofence_before_insert ON attendance;
CREATE TRIGGER validate_geofence_before_insert
  BEFORE INSERT OR UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_attendance_geofence();