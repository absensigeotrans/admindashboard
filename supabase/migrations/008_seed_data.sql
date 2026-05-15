-- Seed Offices
INSERT INTO public.offices (name, latitude, longitude, geofence_radius, address)
VALUES 
('Kantor Pusat PTK', -6.2088, 106.8456, 100, 'Jl. Medan Merdeka Timur No.1A, Jakarta Pusat');

-- Seed Shifts
INSERT INTO public.shifts (name, code, start_time, end_time, grace_period_minutes)
VALUES 
('Shift Pagi', 'SHIFT_PAGI', '08:00:00', '16:00:00', 15),
('Shift Sore', 'SHIFT_SORE', '16:00:00', '00:00:00', 15),
('Shift Malam', 'SHIFT_MALAM', '00:00:00', '08:00:00', 15),
('Non-Shifting', 'NON_SHIFTING', '08:30:00', '17:30:00', 30);
