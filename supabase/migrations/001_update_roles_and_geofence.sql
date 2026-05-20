-- Migration: Update Roles & Geofence Validation
-- Created: 2026-05-19
-- Purpose: 
--   1. Add 'viewer' role to enum
--   2. Migrate all 'employee' roles to 'viewer'
--   3. Update geofence validation trigger:
--      - Driver: boleh absen di luar radius (tetap valid)
--      - Juru Parkir & OB: WAJIB di dalam radius (REJECT kalau di luar)
--      - Viewer & Admin: tidak boleh absen

-- 1. Pastikan enum 'viewer' ada (kalau belum)
DO $$ BEGIN
    ALTER TYPE user_role_enum ADD VALUE IF NOT EXISTS 'viewer';
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2. Migrate semua role 'employee' → 'viewer'
UPDATE public.profiles SET role = 'viewer' WHERE role = 'employee';

-- 3. Update trigger validate_attendance_geofence() dengan logic baru
CREATE OR REPLACE FUNCTION public.validate_attendance_geofence()
RETURNS TRIGGER AS $$
DECLARE
    office_record RECORD;
    settings_record RECORD;
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
        -- Skip validation untuk driver
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
        -- Determine if this is a checkout
        is_checkout := TG_OP = 'UPDATE' AND NEW.check_out_time IS NOT NULL AND OLD.check_out_time IS NULL;
        
        -- Get office location
        IF NEW.office_id IS NOT NULL THEN
            SELECT * INTO office_record FROM public.offices WHERE id = NEW.office_id;
        END IF;
        
        IF office_record IS NULL THEN
            SELECT * INTO office_record FROM public.offices LIMIT 1;
        END IF;
        
        -- Use correct coordinates
        IF is_checkout THEN
            lat := NEW.check_out_latitude;
            lon := NEW.check_out_longitude;
        ELSE
            lat := NEW.check_in_latitude;
            lon := NEW.check_in_longitude;
        END IF;
        
        -- Calculate distance
        IF office_record.id IS NOT NULL AND lat IS NOT NULL AND lon IS NOT NULL THEN
            calculated_distance := public.calculate_distance(lat, lon, office_record.latitude, office_record.longitude);
            NEW.distance_from_office := calculated_distance;
        ELSE
            calculated_distance := 0;
        END IF;
        
        -- REJECT kalau di luar radius
        IF calculated_distance > office_record.geofence_radius THEN
            RAISE EXCEPTION 'Absensi ditolak: Role % wajib absen di dalam radius kantor. Jarak Anda: %.0f meter (maksimal: % meter)', 
                user_role, calculated_distance, office_record.geofence_radius;
        END IF;
        
        -- Kalau di dalam radius, lanjut normal
        NEW.is_valid := true;
        
        -- Get settings untuk cek late
        SELECT * INTO settings_record FROM public.settings WHERE id = 'app_settings';
        
        -- Check if late
        IF NOT is_checkout THEN
            IF EXTRACT(HOUR FROM NEW.check_in_time) > COALESCE(settings_record.late_threshold_hour, 9)
               OR (EXTRACT(HOUR FROM NEW.check_in_time) = COALESCE(settings_record.late_threshold_hour, 9)
                   AND EXTRACT(MINUTE FROM NEW.check_in_time) >= COALESCE(settings_record.late_threshold_minute, 0))
            THEN
                NEW.status := 'late';
            ELSE
                NEW.status := 'present';
            END IF;
        ELSE
            NEW.status := 'present';
        END IF;
        
        RETURN NEW;
    END IF;
    
    -- Default fallback (untuk role lain yang belum di-handle)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
