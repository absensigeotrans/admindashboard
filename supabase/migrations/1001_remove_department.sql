-- Migration: Remove department column from profiles
ALTER TABLE public.profiles DROP COLUMN IF EXISTS department;
