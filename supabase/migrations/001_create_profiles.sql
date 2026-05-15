-- Create profiles table
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    employee_id TEXT UNIQUE,
    nik TEXT,
    email TEXT,
    role TEXT DEFAULT 'juru_parkir' CHECK (role IN ('driver', 'juru_parkir', 'ob', 'admin', 'viewer')),
    device_id TEXT,
    shift_type TEXT DEFAULT 'non_shifting' CHECK (shift_type IN ('shifting', 'non_shifting')),
    is_active BOOLEAN DEFAULT false,
    is_owner BOOLEAN DEFAULT false,
    is_viewer BOOLEAN DEFAULT false,
    can_manage_accounts BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trigger to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, is_active)
    VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', 'juru_parkir', false);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
