-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User roles enum
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('employee', 'admin');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Attendance status enum
DO $$ BEGIN
  CREATE TYPE attendance_status AS ENUM ('present', 'late', 'outside_radius');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Profiles table
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  role user_role DEFAULT 'employee',
  department TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Offices table
CREATE TABLE IF NOT EXISTS offices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  geofence_radius INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance table
CREATE TABLE IF NOT EXISTS attendance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  check_in_time TIMESTAMPTZ DEFAULT NOW(),
  check_out_time TIMESTAMPTZ,
  is_valid BOOLEAN DEFAULT FALSE,
  distance_from_office DOUBLE PRECISION NOT NULL,
  status attendance_status DEFAULT 'outside_radius',
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Attendance logs table
CREATE TABLE IF NOT EXISTS attendance_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  attendance_id UUID REFERENCES attendance(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_offices_updated_at ON offices;
CREATE TRIGGER update_offices_updated_at BEFORE UPDATE ON offices
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_attendance_updated_at ON attendance;
CREATE TRIGGER update_attendance_updated_at BEFORE UPDATE ON attendance
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to validate attendance geofence (server-side)
CREATE OR REPLACE FUNCTION validate_attendance_geofence()
RETURNS TRIGGER AS $$
DECLARE
  office_record RECORD;
  calculated_distance DOUBLE PRECISION;
  R_EARTH CONSTANT DOUBLE PRECISION := 6371000;
  d_lat DOUBLE PRECISION;
  d_lon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  -- Get the first office (assuming single office setup)
  SELECT * INTO office_record FROM offices LIMIT 1;
  
  IF office_record IS NULL THEN
    NEW.is_valid := FALSE;
    NEW.status := 'outside_radius';
    RETURN NEW;
  END IF;
  
  -- Haversine formula calculation
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
    -- Determine if late (after 9 AM)
    IF EXTRACT(HOUR FROM NEW.check_in_time) >= 9 THEN
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

-- Trigger to validate geofence before insert
DROP TRIGGER IF EXISTS validate_geofence_before_insert ON attendance;
CREATE TRIGGER validate_geofence_before_insert
  BEFORE INSERT ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION validate_attendance_geofence();

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;

-- Profiles policies
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
CREATE POLICY "Admins can view all profiles" ON profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
CREATE POLICY "Admins can update all profiles" ON profiles
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Offices policies
DROP POLICY IF EXISTS "Anyone can view offices" ON offices;
CREATE POLICY "Anyone can view offices" ON offices
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Only admins can modify offices" ON offices;
CREATE POLICY "Only admins can modify offices" ON offices
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Attendance policies
DROP POLICY IF EXISTS "Users can view own attendance" ON attendance;
CREATE POLICY "Users can view own attendance" ON attendance
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own attendance" ON attendance;
CREATE POLICY "Users can insert own attendance" ON attendance
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own attendance" ON attendance;
CREATE POLICY "Users can update own attendance" ON attendance
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Admins can view all attendance" ON attendance;
CREATE POLICY "Admins can view all attendance" ON attendance
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Attendance logs policies
DROP POLICY IF EXISTS "Users can view own attendance logs" ON attendance_logs;
CREATE POLICY "Users can view own attendance logs" ON attendance_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM attendance 
      WHERE attendance.id = attendance_logs.attendance_id 
      AND attendance.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Admins can view all attendance logs" ON attendance_logs;
CREATE POLICY "Admins can view all attendance logs" ON attendance_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'employee')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
