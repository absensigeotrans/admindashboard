CREATE TABLE IF NOT EXISTS public.user_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES public.shifts(id) ON DELETE SET NULL,
    office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
    effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
