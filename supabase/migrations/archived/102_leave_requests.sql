-- Migration 003: Leave Requests Table
-- Enables admin to manage employee leave requests via web panel

DO $$ BEGIN
  CREATE TYPE leave_type AS ENUM ('annual', 'sick', 'emergency', 'unpaid');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS leave_requests (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  type leave_type NOT NULL DEFAULT 'annual',
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  reason TEXT NOT NULL DEFAULT '',
  status leave_status NOT NULL DEFAULT 'pending',
  processed_by UUID REFERENCES profiles(id),
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE leave_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own leave requests" ON leave_requests;
CREATE POLICY "Users can view own leave requests" ON leave_requests
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert own leave requests" ON leave_requests;
CREATE POLICY "Users can insert own leave requests" ON leave_requests
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can cancel own pending leave requests" ON leave_requests;
CREATE POLICY "Users can cancel own pending leave requests" ON leave_requests
  FOR UPDATE USING (user_id = auth.uid() AND status = 'pending')
  WITH CHECK (user_id = auth.uid() AND status = 'cancelled');

DROP POLICY IF EXISTS "Admins can view all leave requests" ON leave_requests;
CREATE POLICY "Admins can view all leave requests" ON leave_requests
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "Admins can manage all leave requests" ON leave_requests;
CREATE POLICY "Admins can manage all leave requests" ON leave_requests
  FOR ALL USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP TRIGGER IF EXISTS update_leave_requests_updated_at ON leave_requests;
CREATE TRIGGER update_leave_requests_updated_at BEFORE UPDATE ON leave_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
