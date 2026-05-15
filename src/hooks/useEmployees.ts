import { useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Profile, UserRole } from '@/types';

interface EmployeeUpdate {
  full_name?: string;
  role?: UserRole;
  department?: string;
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
        query = query.or(`full_name.ilike.%${search}%,email.ilike.%${search}%,department.ilike.%${search}%`);
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
    const newRole = currentRole === 'admin' ? 'employee' : 'admin';
    return updateEmployee(id, { role: newRole });
  }, [updateEmployee]);

  const deactivateEmployee = useCallback(async (id: string) => {
    return updateEmployee(id, { role: 'inactive' });
  }, [updateEmployee]);

  const activateEmployee = useCallback(async (id: string, originalRole: 'employee' | 'admin') => {
    return updateEmployee(id, { role: originalRole });
  }, [updateEmployee]);

  const getDepartments = useCallback(() => {
    const depts = employees
      .map((e) => e.department)
      .filter(Boolean) as string[];
    return Array.from(new Set(depts)).sort();
  }, [employees]);

  return {
    employees,
    loading,
    error,
    fetchEmployees,
    updateEmployee,
    toggleRole,
    deactivateEmployee,
    activateEmployee,
    getDepartments,
  };
}