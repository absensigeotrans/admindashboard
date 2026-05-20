-- Migration: Add shift_type & Update Late Threshold
-- Created: 2026-05-19
-- Purpose:
--   1. Add shift_type column to profiles (morning/afternoon)
--   2. Update late threshold to 07:00 WIB (sesuai requirement)

-- 1. Add shift_type enum if not exists
DO $$ BEGIN
    CREATE TYPE shift_type_enum AS ENUM ('morning', 'afternoon');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Add shift_type column to profiles
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS shift_type shift_type_enum DEFAULT NULL;

-- 3. Update trigger validate_attendance_geofence() with 07:00 WIB late threshold
CREATE OR REPLACE FUNCTION public.validate_attendance_geofence()
RETURNS TRIGGER AS $$
DECLARE
    office_record RECORD;
    user_role TEXT;
    calculated_distance DOUBLE PRECISION;
    is_checkout BOOLEAN;
    lat DOUBLE PRECISION;
    lon DOUBLE PRECISION;
BEGIN
    -- Get user role
    SELECT role INTO user_role FROM public.profiles WHERE id = NEW.user_id;
    
    -- Driver boleh di luar radius (tetap valid)
    IF user_role = 'driver' THEN
        NEW.is_valid := true;
        NEW.status := 'present';
        RETURN NEW;
    END IF;
    
    -- Viewer & Admin tidak boleh absen
    IF user_role IN ('viewer', 'admin', 'inactive') THEN
        RAISE EXCEPTION 'Absensi ditolak: Role % tidak diizinkan untuk melakukan absensi', user_role;
    END IF;
    
    -- Juru Parkir & OB: WAJIB di dalam radius (REJECT kalau di luar)
    IF user_role IN ('juru_parkir', 'ob') THEN
        is_checkout := TG_OP = 'UPDATE' AND NEW.check_out_time IS NOT NULL AND OLD.check_out_time IS NULL;
        
        IF NEW.office_id IS NOT NULL THEN
            SELECT * INTO office_record FROM public.offices WHERE id = NEW.office_id;
        END IF;
        
        IF office_record IS NULL THEN
            SELECT * INTO office_record FROM public.offices LIMIT 1;
        END IF;
        
        IF is_checkout THEN
            lat := NEW.check_out_latitude;
            lon := NEW.check_out_longitude;
        ELSE
            lat := NEW.check_in_latitude;
            lon := NEW.check_in_longitude;
        END IF;
        
        IF office_record.id IS NOT NULL AND lat IS NOT NULL AND lon IS NOT NULL THEN
            calculated_distance := public.calculate_distance(lat, lon, office_record.latitude, office_record.longitude);
            NEW.distance_from_office := calculated_distance;
        ELSE
            calculated_distance := 0;
        END IF;
        
        IF calculated_distance > office_record.geofence_radius THEN
            RAISE EXCEPTION 'Absensi ditolak: Role % wajib absen di dalam radius kantor. Jarak Anda: %.0f meter (maksimal: % meter)', 
                user_role, calculated_distance, office_record.geofence_radius;
        END IF;
        
        NEW.is_valid := true;
        
        -- Late check: > 07:00 WIB = terlambat
        IF NOT is_checkout THEN
            IF NEW.check_in_time::time > '07:00:00'::time THEN
                NEW.status := 'late';
            ELSE
                NEW.status := 'present';
            END IF;
        ELSE
            NEW.status := 'present';
        END IF;
        
        RETURN NEW;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
