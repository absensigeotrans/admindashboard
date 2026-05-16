-- Migration 014: Fix RLS infinite recursion
--
-- Masalah: is_admin() query public.profiles dari dalam policy profiles,
-- menyebabkan infinite recursion di PostgreSQL. Akibatnya semua operasi
-- SELECT/UPDATE/DELETE ke tabel profiles gagal.
--
-- Solusi: is_admin() query auth.users.raw_user_meta_data saja,
-- bukan public.profiles. Data role sudah terisi di metadata dari trigger signup.
--
-- Juga update metadata admin lama yang belum punya role di metadata-nya.

-- ============================================================
-- Fix: is_admin() pakai auth.users (no RLS recursion)
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM auth.users
        WHERE id = auth.uid()
        AND raw_user_meta_data->>'role' = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- Update metadata admin seed accounts yang belum punya role
-- - admin.ptk@gmail.com (seed migration 010) => metadata tanpa 'role'
-- - admin1@gmail.com (signup via API)        => metadata sudah 'role':'admin'
-- - admin1@ptk.com, admin2@ptk.com (seed 013) => metadata sudah 'role':'admin'
-- ============================================================
UPDATE auth.users
SET raw_user_meta_data = 
    COALESCE(raw_user_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
WHERE (
    raw_user_meta_data->>'role' IS NULL 
    OR raw_user_meta_data->>'role' != 'admin'
)
AND id IN (
    SELECT id FROM public.profiles WHERE role = 'admin'
);
