-- Haversine Calculation
CREATE OR REPLACE FUNCTION public.calculate_distance(lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION, lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION)
RETURNS DOUBLE PRECISION AS $$
DECLARE
    R DOUBLE PRECISION := 6371000; -- Earth radius in meters
    dLat DOUBLE PRECISION;
    dLon DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    dLat := radians(lat2 - lat1);
    dLon := radians(lon2 - lon1);
    a := sin(dLat/2) * sin(dLat/2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon/2) * sin(dLon/2);
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    RETURN R * c;
END;
$$ LANGUAGE plpgsql;

-- Check Geofence
CREATE OR REPLACE FUNCTION public.is_within_geofence(user_lat DOUBLE PRECISION, user_lon DOUBLE PRECISION, office_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    office_lat DOUBLE PRECISION;
    office_lon DOUBLE PRECISION;
    radius INTEGER;
    distance DOUBLE PRECISION;
BEGIN
    SELECT latitude, longitude, geofence_radius INTO office_lat, office_lon, radius
    FROM public.offices WHERE id = office_id;
    
    distance := public.calculate_distance(user_lat, user_lon, office_lat, office_lon);
    RETURN distance <= radius;
END;
$$ LANGUAGE plpgsql;
