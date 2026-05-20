-- Migration 011: Create Settings Table
--
-- This table stores global geofencing configuration and office settings.
-- Required by the validate_attendance_geofence() trigger function.

CREATE TABLE IF NOT EXISTS public.settings (
  id TEXT PRIMARY KEY DEFAULT 'app_settings',
  office_name TEXT NOT NULL DEFAULT 'Kantor Pusat Pertamina',
  latitude DOUBLE PRECISION NOT NULL DEFAULT -6.2297,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 106.8295,
  radius_meters INTEGER NOT NULL DEFAULT 100,
  late_threshold_hour INTEGER NOT NULL DEFAULT 9,
  late_threshold_minute INTEGER NOT NULL DEFAULT 0,
  default_geofence_radius INTEGER NOT NULL DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed data
INSERT INTO public.settings (id, office_name, latitude, longitude, radius_meters)
VALUES (
  'app_settings',
  'Kantor Pusat Pertamina',
  -6.2297,
  106.8295,
  100
) ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- Anyone can read settings
CREATE POLICY "Anyone can view settings" ON public.settings
  FOR SELECT TO authenticated USING (true);

-- Only admins can manage settings
CREATE POLICY "Admins can manage settings" ON public.settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Trigger for updated_at
DROP TRIGGER IF EXISTS update_settings_updated_at ON public.settings;
CREATE TRIGGER update_settings_updated_at BEFORE UPDATE ON public.settings
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
