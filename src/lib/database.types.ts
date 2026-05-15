export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export interface Database {
  public: {
    Tables: {
      profiles: {
        Row: {
          id: string;
          email: string;
          full_name: string;
          role: 'employee' | 'admin';
          department: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          full_name: string;
          role?: 'employee' | 'admin';
          department?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          full_name?: string;
          role?: 'employee' | 'admin';
          department?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      offices: {
        Row: {
          id: string;
          name: string;
          latitude: number;
          longitude: number;
          geofence_radius: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          latitude: number;
          longitude: number;
          geofence_radius?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          name?: string;
          latitude?: number;
          longitude?: number;
          geofence_radius?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      attendance: {
        Row: {
          id: string;
          user_id: string;
          check_in_time: string;
          check_out_time: string | null;
          is_valid: boolean;
          distance_from_office: number;
          status: 'present' | 'late' | 'outside_radius';
          latitude: number;
          longitude: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          user_id: string;
          check_in_time?: string;
          check_out_time?: string | null;
          is_valid?: boolean;
          distance_from_office: number;
          status: 'present' | 'late' | 'outside_radius';
          latitude: number;
          longitude: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          user_id?: string;
          check_in_time?: string;
          check_out_time?: string | null;
          is_valid?: boolean;
          distance_from_office?: number;
          status?: 'present' | 'late' | 'outside_radius';
          latitude?: number;
          longitude?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      attendance_logs: {
        Row: {
          id: string;
          attendance_id: string;
          action: string;
          details: Json;
          created_at: string;
        };
        Insert: {
          id?: string;
          attendance_id: string;
          action: string;
          details?: Json;
          created_at?: string;
        };
        Update: {
          id?: string;
          attendance_id?: string;
          action?: string;
          details?: Json;
          created_at?: string;
        };
      };
    };
  };
}
