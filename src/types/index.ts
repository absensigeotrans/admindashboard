export type UserRole = 'employee' | 'admin' | 'driver' | 'inactive';

export type AttendanceStatus = 'present' | 'late' | 'outside_radius';

export interface Profile {
  id: string;
  email: string;
  full_name: string;
  role: UserRole;
  department: string | null;
  created_at: string;
  updated_at: string;
}

export interface Office {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  geofence_radius: number;
  created_at: string;
  updated_at: string;
}

export interface Attendance {
  id: string;
  user_id: string;
  check_in_time: string;
  check_out_time: string | null;
  check_in_latitude: number;
  check_in_longitude: number;
  check_out_latitude?: number | null;
  check_out_longitude?: number | null;
  is_valid: boolean;
  is_mocked: boolean;
  distance_from_office: number;
  status: AttendanceStatus;
  created_at: string;
  updated_at: string;
}

export interface AttendanceLog {
  id: string;
  attendance_id: string;
  action: string;
  details: Record<string, unknown>;
  created_at: string;
}

export interface AttendanceWithUser extends Attendance {
  user: {
    full_name: string;
    email: string;
    department: string | null;
  };
}

export interface Location {
  latitude: number;
  longitude: number;
  accuracy?: number;
}
