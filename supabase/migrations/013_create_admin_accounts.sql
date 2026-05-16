-- Create 2 Admin Accounts
-- Passwords default: 'AdminPTK123!'
-- Hash pre-computed: $2b$10$tubbbUnXRmuQA6az2G4PfeXooCSP8R7LlTZhxcpwCplSkT1FiO3Pq

-- Admin 1
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, recovery_sent_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    'admin1@ptk.com',
    '$2b$10$tubbbUnXRmuQA6az2G4PfeXooCSP8R7LlTZhxcpwCplSkT1FiO3Pq',
    now(), NULL, now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin Satu","role":"admin"}',
    now(), now(),
    '', '', '', ''
);

-- Admin 2
INSERT INTO auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, recovery_sent_at, last_sign_in_at,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
) VALUES (
    '00000000-0000-0000-0000-000000000000',
    gen_random_uuid(),
    'authenticated', 'authenticated',
    'admin2@ptk.com',
    '$2b$10$tubbbUnXRmuQA6az2G4PfeXooCSP8R7LlTZhxcpwCplSkT1FiO3Pq',
    now(), NULL, now(),
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Admin Dua","role":"admin"}',
    now(), now(),
    '', '', '', ''
);

-- Update profiles untuk set full permissions
DO $$
DECLARE
    admin_id UUID;
BEGIN
    -- Admin 1
    SELECT id INTO admin_id FROM auth.users WHERE email = 'admin1@ptk.com';
    IF admin_id IS NOT NULL THEN
        UPDATE public.profiles
        SET role = 'admin', is_active = true, is_owner = true,
            can_manage_accounts = true, employee_id = 'ADM-002',
            full_name = 'Admin Satu'
        WHERE id = admin_id;
    END IF;

    -- Admin 2
    SELECT id INTO admin_id FROM auth.users WHERE email = 'admin2@ptk.com';
    IF admin_id IS NOT NULL THEN
        UPDATE public.profiles
        SET role = 'admin', is_active = true, is_owner = true,
            can_manage_accounts = true, employee_id = 'ADM-003',
            full_name = 'Admin Dua'
        WHERE id = admin_id;
    END IF;
END $$;
