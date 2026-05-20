-- Migration 011: Fix schema mismatches between Flutter app and database
-- 
-- Issues fixed:
--   1. handle_new_user() trigger doesn't read employee_id, shift_type from metadata
--   2. leave_requests missing total_days column
--   3. leave_requests admin_notes (plural) vs admin_note (singular)
--   4. leave_requests approved_at vs responded_at
--   5. leave_requests status check constraint missing 'cancelled'
--   6. leave_requests leave_type check constraint incompatible with Flutter values

-- ============================================================
-- FIX 1: Update handle_new_user() trigger to read metadata
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id, email, full_name, employee_id, role, shift_type, is_active
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.raw_user_meta_data->>'employee_id',
        COALESCE(NEW.raw_user_meta_data->>'role', 'juru_parkir'),
        NEW.raw_user_meta_data->>'shift_type',
        false
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- FIX 2-5: Fix leave_requests table
-- ============================================================

-- Add total_days column
ALTER TABLE public.leave_requests
  ADD COLUMN IF NOT EXISTS total_days INTEGER DEFAULT 1;

-- Add admin_note column (singular, as used by Flutter code)
ALTER TABLE public.leave_requests
  ADD COLUMN IF NOT EXISTS admin_note TEXT;

-- Add responded_at column (as used by Flutter code)
ALTER TABLE public.leave_requests
  ADD COLUMN IF NOT EXISTS responded_at TIMESTAMPTZ;

-- Drop old check constraints so we can recreate them
ALTER TABLE public.leave_requests
  DROP CONSTRAINT IF EXISTS leave_requests_status_check;

ALTER TABLE public.leave_requests
  DROP CONSTRAINT IF EXISTS leave_requests_leave_type_check;

-- Re-add with updated values
ALTER TABLE public.leave_requests
  ADD CONSTRAINT leave_requests_status_check
  CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled'));

ALTER TABLE public.leave_requests
  ADD CONSTRAINT leave_requests_leave_type_check
  CHECK (leave_type IN ('cuti_tahunan', 'cuti_sakit', 'cuti_darurat', 'izin_tidak_hadir', 'cuti', 'izin', 'sakit', 'annual', 'sick', 'emergency', 'unpaid'));
