-- Add updated_at column to attendance table
-- This fixes the error: record "new" has no field "updated_at"

-- Add updated_at column if not exists
ALTER TABLE public.attendance
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Recreate the update_updated_at_column function with NULL handling
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.updated_at IS NULL THEN
    NEW.updated_at = NOW();
  ELSE
    NEW.updated_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Ensure the trigger exists for attendance
DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
CREATE TRIGGER update_attendance_updated_at
  BEFORE UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();