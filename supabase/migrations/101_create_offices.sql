CREATE TABLE IF NOT EXISTS public.offices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    geofence_radius INTEGER DEFAULT 100,
    address TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.offices ADD COLUMN IF NOT EXISTS address TEXT;
ALTER TABLE public.offices ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
