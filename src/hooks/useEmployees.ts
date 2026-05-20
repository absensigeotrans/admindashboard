import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Profile, UserRole, ShiftType } from '@/types';

interface EmployeeUpdate {
  full_name?: string;
  role?: UserRole;
  shift_type?: ShiftType | null;
}

interface CreateEmployeeData {
  email: string;
  password: string;
  full_name: string;
  nik?: string;
  employee_id?: string;
  role: UserRole;
  shift_type?: ShiftType | null;
}

export function useEmployees() {
  const [employees, setEmployees] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchEmployees = useCallback(async (page = 1, limit = 50, search = '') => {
    setLoading(true);
    setError(null);
    try {
      let query = supabase
        .from('profiles')
        .select('*', { count: 'exact' })
        .order('created_at', { ascending: false })
        .range((page - 1) * limit, page * limit - 1);

      if (search) {
        query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%`);
      }

      const { data, error: fetchError, count } = await query;
      if (fetchError) throw fetchError;

      setEmployees((data as Profile[]) || []);
      return { data: data as Profile[], count: count || 0 };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to fetch employees';
      setError(msg);
      return { data: [], count: 0 };
    } finally {
      setLoading(false);
    }
  }, []);

  const updateEmployee = useCallback(async (id: string, updates: EmployeeUpdate) => {
    setLoading(true);
    try {
      const { error: updateError } = await supabase
        .from('profiles')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', id);
      if (updateError) throw updateError;

      setEmployees((prev) =>
        prev.map((e) => (e.id === id ? { ...e, ...updates } : e))
      );
      return { success: true };
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Failed to update employee';
      setError(msg);
      return { success: false, error: msg };
    } finally {
      setLoading(false);
    }
  }, []);

  const toggleRole = useCallback(async (id: string, currentRole: UserRole) => {
    const newRole = currentRole === 'admin' ? 'viewer' : 'admin';
    return updateEmployee(id, { role: newRole });
  }, [updateEmployee]);

  const deactivateEmployee = useCallback(async (id: string) => {
    return updateEmployee(id, { role: 'inactive' });
  }, [updateEmployee]);

  const activateEmployee = useCallback(async (id: string, originalRole: UserRole) => {
    return updateEmployee(id, { role: originalRole });
  }, [updateEmployee]);

  // Create a new employee manually (admin function)
  const createEmployee = useCallback(async (data: CreateEmployeeData) => {
    setLoading(true);
    setError(null);
    try {
      // 1. Check if email already exists
      const { data: existingUser } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', data.email.toLowerCase())
        .maybeSingle();

      if (existingUser) {
        return { success: false, error: 'Email sudah digunakan oleh pengguna lain' };
      }

      // 2. Create auth user
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: data.email.toLowerCase(),
        password: data.password,
        email_confirm: true,
        user_metadata: {
          full_name: data.full_name,
        },
      });

      if (authError) {
        console.error('Auth create error:', authError);
        return { success: false, error: authError.message };
      }

      if (!authData.user) {
        return { success: false, error: 'Gagal membuat user' };
      }

      // 3. Create profile
      const { error: profileError } = await supabase.from('profiles').insert({
        id: authData.user.id,
        email: data.email.toLowerCase(),
        full_name: data.full_name,
        role: data.role,
        shift_type: data.shift_type || null,
        nik: data.nik || null,
        employee_id: data.employee_id || null,
      });

      if (profileError) {
        console.error('Profile create error:', profileError);
        // Try to clean up the auth user
        await supabase.auth.admin.deleteUser(authData.user.id);
        return { success: false, error: profileError.message };
      }

      // Refresh employee list
      await fetchEmployees();

      return { success: true, message: `Karyawan ${data.full_name} berhasil dibuat` };
    } catch (err: any) {
      const msg = err?.message || 'Failed to create employee';
      setError(msg);
      return { success: false, error: msg };
    } finally {
      setLoading(false);
    }
  }, [fetchEmployees]);

  return {
    employees,
    loading,
    error,
    fetchEmployees,
    updateEmployee,
    toggleRole,
    deactivateEmployee,
    activateEmployee,
    createEmployee,
  };
}