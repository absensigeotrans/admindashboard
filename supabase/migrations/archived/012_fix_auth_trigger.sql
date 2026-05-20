-- Migration 012: Fix handle_new_user() trigger untuk mobile app
--
-- Masalah:
--   1. Mobile app kirim role di raw_user_meta_data (driver, juru_parkir, ob)
--   2. Trigger harus baca role dari metadata, bukan fallback ke 'admin'
--   3. Profile perlu simpan employee_id, nik, shift_type dari mobile
--
-- Perbaikan:
--   - Baca role dari metadata (mobile app sudah kirim)
--   - Fallback 'juru_parkir' untuk mobile users
--   - Simpan employee_id (NIK) dari metadata
--   - is_active = true (langsung aktif setelah register)
--
-- Note: Flutter mengirim NIK sebagai 'employee_id' di metadata

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        nik,
        employee_id,
        role,
        shift_type,
        is_active
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        NEW.raw_user_meta_data->>'employee_id',  -- NIK dari Flutter (dikirim sbg employee_id)
        NEW.raw_user_meta_data->>'employee_id',  -- employee_id di profiles
        COALESCE(NEW.raw_user_meta_data->>'role', 'juru_parkir'),
        NEW.raw_user_meta_data->>'shift_type',
        true
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
