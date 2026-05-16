-- Migration 012: Fix handle_new_user() trigger untuk web admin
--
-- Masalah:
--   1. Migration 100_initial_schema.sql overwrite trigger dengan default role='employee'
--      yang melanggar CHECK CONSTRAINT role IN ('driver','juru_parkir','ob','admin','viewer')
--   2. Web admin panel hanya untuk admin, bukan untuk juru_parkir/driver/ob
--   3. Cast ::user_role tidak kompatibel dengan kolom role bertipe TEXT
--
-- Perbaikan:
--   - Default role = 'admin' (karena web khusus admin)
--   - is_active = true (akun admin langsung aktif)
--   - Tidak pakai ::user_role cast, pakai TEXT langsung
--   - Pakai COALESCE untuk fallback dari metadata

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, is_active)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
        COALESCE(NEW.raw_user_meta_data->>'role', 'admin'),
        true
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
