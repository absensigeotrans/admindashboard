-- Migration 015: Fix RLS policies dari migration 100
--
-- Masalah: Migration 100_initial_schema.sql bikin policies dengan
-- inline query: EXISTS (SELECT 1 FROM profiles WHERE ...).
-- Ini menyebabkan infinite recursion karena policy profiles query profiles.
--
-- Solusi: Drop policies tersebut dan recreate pakai is_admin()
-- yang sekarang sudah aman (query auth.users, bukan profiles).

-- ============================================================
-- Drop problematic policies dari migration 100
-- ============================================================

-- Profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;

-- Offices
DROP POLICY IF EXISTS "Only admins can modify offices" ON public.offices;

-- Attendance
DROP POLICY IF EXISTS "Admins can view all attendance" ON public.attendance;

-- Attendance logs
DROP POLICY IF EXISTS "Admins can view all attendance logs" ON public.attendance_logs;

-- ============================================================
-- Recreate pakai is_admin() yang aman
-- ============================================================

-- Profiles
CREATE POLICY "Admins can view all profiles" ON public.profiles
    FOR SELECT USING (public.is_admin());

CREATE POLICY "Admins can update all profiles" ON public.profiles
    FOR ALL USING (public.is_admin());

-- Offices
CREATE POLICY "Only admins can modify offices" ON public.offices
    FOR ALL USING (public.is_admin());

-- Attendance
CREATE POLICY "Admins can view all attendance" ON public.attendance
    FOR SELECT USING (public.is_admin());

-- Attendance logs
CREATE POLICY "Admins can view all attendance logs" ON public.attendance_logs
    FOR SELECT USING (public.is_admin());
