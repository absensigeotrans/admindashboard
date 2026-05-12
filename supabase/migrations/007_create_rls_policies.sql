-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leave_requests ENABLE ROW LEVEL SECURITY;

-- Helper Functions for Policies
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND (role = 'admin' OR is_owner = true) AND is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles Policies
CREATE POLICY "Profiles are viewable by own user" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Profiles are viewable by admins" ON public.profiles
    FOR SELECT USING (public.is_admin());

-- Attendance Policies
CREATE POLICY "Attendance is viewable by own user" ON public.attendance
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Attendance is insertable by own user" ON public.attendance
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Attendance is viewable by admins" ON public.attendance
    FOR SELECT USING (public.is_admin());
