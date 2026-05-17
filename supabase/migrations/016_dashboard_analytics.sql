-- Migration 016: Dashboard Analytics Function
-- Returns aggregated attendance data for chart visualizations
-- Usage: SELECT * FROM get_dashboard_analytics('2026-05-01', '2026-05-17');

CREATE OR REPLACE FUNCTION public.get_dashboard_analytics(start_date DATE, end_date DATE)
RETURNS JSON
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  result JSON;
BEGIN
  WITH status_dist AS (
    SELECT
      COALESCE(SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END), 0) AS present,
      COALESCE(SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END), 0) AS late,
      COALESCE(SUM(CASE WHEN status = 'outside_radius' THEN 1 ELSE 0 END), 0) AS outside
    FROM attendance
    WHERE check_in_time >= start_date
      AND check_in_time < (end_date + INTERVAL '1 day')
  ),
  daily_attendance AS (
    SELECT
      check_in_time::DATE AS date,
      COUNT(*) AS total,
      COALESCE(SUM(CASE WHEN status = 'present' THEN 1 ELSE 0 END), 0) AS present,
      COALESCE(SUM(CASE WHEN status = 'late' THEN 1 ELSE 0 END), 0) AS late,
      COALESCE(SUM(CASE WHEN status = 'outside_radius' THEN 1 ELSE 0 END), 0) AS outside
    FROM attendance
    WHERE check_in_time >= start_date
      AND check_in_time < (end_date + INTERVAL '1 day')
    GROUP BY check_in_time::DATE
    ORDER BY check_in_time::DATE
  ),
  late_trend AS (
    SELECT
      check_in_time::DATE AS date,
      COUNT(*) AS late_count,
      COALESCE(
        AVG(
          EXTRACT(EPOCH FROM (check_in_time::TIME - INTERVAL '9 hours')) / 60
        ) FILTER (WHERE check_in_time::TIME > '09:00:00'),
        0
      )::INTEGER AS avg_late_minutes
    FROM attendance
    WHERE status = 'late'
      AND check_in_time >= start_date
      AND check_in_time < (end_date + INTERVAL '1 day')
    GROUP BY check_in_time::DATE
    ORDER BY check_in_time::DATE
  )
  SELECT JSON_BUILD_OBJECT(
    'statusDistribution', (
      SELECT JSON_BUILD_OBJECT(
        'present', present,
        'late', late,
        'outside', outside
      ) FROM status_dist
    ),
    'dailyAttendance', (
      SELECT COALESCE(JSON_AGG(
        JSON_BUILD_OBJECT(
          'date', date,
          'total', total,
          'present', present,
          'late', late,
          'outside', outside
        ) ORDER BY date
      ), '[]'::JSON) FROM daily_attendance
    ),
    'lateTrend', (
      SELECT COALESCE(JSON_AGG(
        JSON_BUILD_OBJECT(
          'date', date,
          'lateCount', late_count,
          'avgLateMinutes', avg_late_minutes
        ) ORDER BY date
      ), '[]'::JSON) FROM late_trend
    )
  ) INTO result;

  RETURN result;
END;
$$;
