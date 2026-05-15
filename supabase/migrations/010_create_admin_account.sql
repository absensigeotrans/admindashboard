-- Create Admin User in Auth Schema
-- Password default: 'AdminPTK123!' (Ganti segera setelah login pertama kali)
-- Hash generated for 'AdminPTK123!'
INSERT INTO auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated',
    'authenticated',
    'admin.ptk@gmail.com',
    crypt('AdminPTK123!', gen_salt('bf')),
    now(),
    NULL,
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Super Admin PTK"}',
    now(),
    now(),
    '',
    '',
    '',
    ''
) RETURNING id;

-- Note: The trigger on_auth_user_created will automatically create the profile.
-- However, we need to UPDATE it to give full control (is_owner, is_active, etc.)

-- Use a DO block to ensure the update happens after the insert trigger
DO $$
DECLARE
    admin_id UUID;
BEGIN
    SELECT id INTO admin_id FROM auth.users WHERE email = 'admin.ptk@gmail.com';
    
    UPDATE public.profiles 
    SET 
        role = 'admin',
        is_active = true,
        is_owner = true,
        can_manage_accounts = true,
        employee_id = 'ADM-001',
        full_name = 'Super Admin PTK'
    WHERE id = admin_id;
END $$;
