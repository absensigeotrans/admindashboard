-- Migration: Auto checkout at 23:59:59 for missed checkouts

-- Enable pg_cron if not already enabled (Supabase usually has this enabled, but just in case)
CREATE EXTENSION IF NOT EXISTS pg_cron;

CREATE OR REPLACE FUNCTION auto_checkout_missing_attendances()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE attendance
    SET 
        -- Set check_out_time to 23:59:59 in Asia/Jakarta timezone for the day of check_in_time
        check_out_time = date_trunc('day', check_in_time AT TIME ZONE 'Asia/Jakarta') AT TIME ZONE 'Asia/Jakarta' 
                         + interval '23 hours 59 minutes 59 seconds'
    WHERE 
        check_out_time IS NULL
        -- Only process attendances where the "day" in Jakarta time is strictly before the "current day" in Jakarta time.
        AND (check_in_time AT TIME ZONE 'Asia/Jakarta')::date < (now() AT TIME ZONE 'Asia/Jakarta')::date;
END;
$$;

-- Schedule the cron job to run every hour at minute 5 to process any missed checkouts.
-- If they haven't checked out by midnight, the next hour's cron (e.g. 01:05 WIB) will catch them.
-- To avoid duplicate scheduling, we unschedule first if it exists.
DO $$
BEGIN
  PERFORM cron.unschedule('auto_checkout_missing');
EXCEPTION
  WHEN undefined_object THEN
    -- Ignore if doesn't exist
    NULL;
  WHEN OTHERS THEN
    NULL;
END;
$$;

SELECT cron.schedule(
    'auto_checkout_missing', 
    '5 * * * *', 
    'SELECT auto_checkout_missing_attendances();'
);
