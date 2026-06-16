-- Migration: admin_insert_attendance
-- Adds an RLS policy allowing admins to insert new attendance records manually.

CREATE POLICY "attendance_insert_admin" ON public.attendance
FOR INSERT WITH CHECK (public.is_admin());
