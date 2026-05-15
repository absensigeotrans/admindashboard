'use client';

import { useEffect, useState, useCallback } from 'react';
import { useEmployees } from '@/hooks/useEmployees';
import { useOffices } from '@/hooks/useOffices';
import { supabase } from '@/lib/supabase';
import { SearchInput } from '@/components/ui/SearchInput';
import { StatsCard } from '@/components/ui/StatsCard';
import { Pagination } from '@/components/ui/Pagination';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { FormInput, FormSelect } from '@/components/ui/FormInput';
import { toast } from '@/components/ui/Toast';
import { Profile, UserRole } from '@/types';
import { Users, Building2, UserCog, Download } from 'lucide-react';

const PAGE_SIZE = 50;

export default function EmployeesPage() {
  const {
    employees, loading, fetchEmployees, updateEmployee,
    toggleRole, deactivateEmployee, activateEmployee, getDepartments,
  } = useEmployees();
  const { offices } = useOffices();

  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  // Edit modal
  const [editEmployee, setEditEmployee] = useState<Profile | null>(null);
  const [editFullName, setEditFullName] = useState('');
  const [editDepartment, setEditDepartment] = useState('');
  const [editRole, setEditRole] = useState<UserRole>('employee');
  const [saving, setSaving] = useState(false);

  // Detail modal
  const [detailEmployee, setDetailEmployee] = useState<Profile | null>(null);
  const [employeeHistory, setEmployeeHistory] = useState<unknown[]>([]);

  // Confirm modal
  const [confirmAction, setConfirmAction] = useState<{
    employee: Profile;
    action: 'deactivate' | 'activate';
    originalRole: 'employee' | 'admin';
  } | null>(null);

  const load = useCallback(async (s = search, p = page) => {
    const result = await fetchEmployees(p, PAGE_SIZE, s);
    setTotal(result.count);
  }, [fetchEmployees]);

  useEffect(() => {
    load();
  }, [load]);

  const handleSearch = (val: string) => {
    setSearch(val);
    setPage(1);
    load(val, 1);
  };

  const openEdit = (emp: Profile) => {
    setEditEmployee(emp);
    setEditFullName(emp.full_name);
    setEditDepartment(emp.department || '');
    setEditRole(emp.role === 'inactive' ? 'employee' : emp.role);
    setSaving(false);
  };

  const handleSaveEdit = async () => {
    if (!editEmployee) return;
    setSaving(true);
    const result = await updateEmployee(editEmployee.id, {
      full_name: editFullName,
      department: editDepartment || undefined,
    });
    if (result.success) {
      toast.success('Employee updated');
      setEditEmployee(null);
      load(search, page);
    } else {
      toast.error(result.error || 'Update failed');
    }
    setSaving(false);
  };

  const handleDeactivate = async () => {
    if (!confirmAction) return;
    const result = await deactivateEmployee(confirmAction.employee.id);
    if (result.success) {
      toast.success('Employee deactivated');
      setConfirmAction(null);
      load(search, page);
    } else {
      toast.error('Failed to deactivate');
    }
  };

  const handleActivate = async () => {
    if (!confirmAction) return;
    const result = await activateEmployee(confirmAction.employee.id, confirmAction.originalRole);
    if (result.success) {
      toast.success('Employee activated');
      setConfirmAction(null);
      load(search, page);
    } else {
      toast.error('Failed to activate');
    }
  };

  const openDetail = async (emp: Profile) => {
    setDetailEmployee(emp);
    const { data } = await supabase
      .from('attendance')
      .select('*')
      .eq('user_id', emp.id)
      .order('check_in_time', { ascending: false })
      .limit(20);
    setEmployeeHistory(data || []);
  };

  const handleToggleRole = async (emp: Profile) => {
    const result = await toggleRole(emp.id, emp.role);
    if (result.success) {
      toast.success(`Role changed to ${emp.role === 'admin' ? 'employee' : 'admin'}`);
      load(search, page);
    } else {
      toast.error('Failed to update role');
    }
  };

  // CSV Export
  const exportCSV = () => {
    const headers = ['Name', 'Email', 'Department', 'Role', 'Status', 'Created'];
    const rows = employees.map((e) => [
      e.full_name, e.email, e.department || '', e.role, 'active', e.created_at,
    ]);
    const csv = [headers, ...rows]
      .map((r) => r.map((c) => `"${c}"`).join(','))
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `employees_${new Date().toISOString().split('T')[0]}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('CSV exported');
  };

  const activeEmployees = employees.filter((e) => e.role !== 'inactive');
  const departments = getDepartments();

  return (
    <div className="space-y-5">
      {/* Search + Export */}
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={handleSearch}
          placeholder="Search name, email, department..."
          className="flex-1"
        />
        <Button variant="secondary" onClick={exportCSV}>
          <Download className="w-4 h-4" /> Export CSV
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard icon={<Users className="w-6 h-6" />} value={total} label="Total Employees" color="blue" />
        <StatsCard icon={<UserCog className="w-6 h-6" />} value={employees.filter(e => e.role === 'admin').length} label="Admins" color="purple" />
        <StatsCard icon={<Users className="w-6 h-6" />} value={employees.filter(e => e.role === 'employee').length} label="Employees" color="green" />
        <StatsCard icon={<Building2 className="w-6 h-6" />} value={departments.length} label="Departments" color="yellow" />
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Name</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Email</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Department</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Role</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y">
              {loading ? (
                <tr>
                  <td colSpan={5} className="px-4 py-12 text-center">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto" />
                  </td>
                </tr>
              ) : activeEmployees.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-gray-500">No employees found</td>
                </tr>
              ) : (
                activeEmployees.map((emp) => (
                  <tr key={emp.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3">
                      <button
                        onClick={() => openDetail(emp)}
                        className="flex items-center gap-3 text-left hover:text-blue-600"
                      >
                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-sm font-medium text-blue-600">
                          {emp.full_name.charAt(0).toUpperCase()}
                        </div>
                        <span className="font-medium">{emp.full_name}</span>
                      </button>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{emp.email}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{emp.department || '—'}</td>
                    <td className="px-4 py-3">
                      <button onClick={() => handleToggleRole(emp)} title="Click to toggle role">
                        <Badge variant={emp.role === 'admin' ? 'info' : 'default'}>
                          {emp.role}
                        </Badge>
                      </button>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Button size="sm" variant="ghost" onClick={() => openEdit(emp)}>
                          Edit
                        </Button>
                        {emp.role !== 'inactive' ? (
                          <Button size="sm" variant="danger" onClick={() => setConfirmAction({
                            employee: emp,
                            action: 'deactivate',
                            originalRole: emp.role === 'admin' ? 'admin' : 'employee',
                          })}>
                            Deactivate
                          </Button>
                        ) : (
                          <Button size="sm" variant="secondary" onClick={() => setConfirmAction({
                            employee: emp,
                            action: 'activate',
                            originalRole: emp.role === 'admin' ? 'admin' : 'employee',
                          })}>
                            Activate
                          </Button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Pagination */}
      <Pagination
        currentPage={page}
        totalPages={Math.ceil(total / PAGE_SIZE)}
        onPageChange={(p) => { setPage(p); load(search, p); }}
      />

      {/* Edit Modal */}
      <Modal
        isOpen={!!editEmployee}
        onClose={() => setEditEmployee(null)}
        title="Edit Employee"
        size="sm"
      >
        {editEmployee && (
          <div className="space-y-4">
            <FormInput
              label="Full Name"
              value={editFullName}
              onChange={(e) => setEditFullName(e.target.value)}
            />
            <FormInput
              label="Department"
              value={editDepartment}
              onChange={(e) => setEditDepartment(e.target.value)}
              placeholder="Leave blank to remove"
            />
            <div className="flex gap-2 pt-2">
              <Button onClick={handleSaveEdit} loading={saving} className="flex-1">
                Save Changes
              </Button>
              <Button variant="secondary" onClick={() => setEditEmployee(null)}>
                Cancel
              </Button>
            </div>
          </div>
        )}
      </Modal>

      {/* Detail Modal */}
      <Modal
        isOpen={!!detailEmployee}
        onClose={() => setDetailEmployee(null)}
        title={detailEmployee?.full_name || ''}
        size="lg"
      >
        {detailEmployee && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p className="text-gray-500">Email</p>
                <p className="font-medium">{detailEmployee.email}</p>
              </div>
              <div>
                <p className="text-gray-500">Role</p>
                <Badge variant={detailEmployee.role === 'admin' ? 'info' : 'default'}>{detailEmployee.role}</Badge>
              </div>
              <div>
                <p className="text-gray-500">Department</p>
                <p className="font-medium">{detailEmployee.department || '—'}</p>
              </div>
              <div>
                <p className="text-gray-500">Joined</p>
                <p className="font-medium">{new Date(detailEmployee.created_at).toLocaleDateString('id-ID')}</p>
              </div>
            </div>

            <div>
              <h4 className="font-semibold text-gray-900 mb-2">Recent Attendance ({employeeHistory.length})</h4>
              {employeeHistory.length === 0 ? (
                <p className="text-gray-500 text-sm">No attendance records</p>
              ) : (
                <div className="max-h-60 overflow-y-auto space-y-2">
                  {employeeHistory.map((h: unknown) => {
                    const rec = h as { id: string; check_in_time: string; status: string };
                    return (
                      <div key={rec.id} className="flex items-center justify-between py-2 border-b last:border-0">
                        <span className="text-sm">{new Date(rec.check_in_time).toLocaleString('id-ID')}</span>
                        <Badge variant={rec.status === 'present' ? 'success' : rec.status === 'late' ? 'warning' : 'danger'}>
                          {rec.status}
                        </Badge>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        )}
      </Modal>

      {/* Confirm Modal */}
      <Modal
        isOpen={!!confirmAction}
        onClose={() => setConfirmAction(null)}
        title={confirmAction?.action === 'deactivate' ? 'Deactivate Employee?' : 'Activate Employee?'}
        size="sm"
      >
        {confirmAction && (
          <div className="space-y-4">
            <p className="text-gray-600">
              {confirmAction.action === 'deactivate'
                ? `Are you sure you want to deactivate ${confirmAction.employee.full_name}? They will lose access to the system.`
                : `Reactivate ${confirmAction.employee.full_name}? They will regain access with role: ${confirmAction.originalRole}.`}
            </p>
            <div className="flex gap-2">
              <Button
                variant={confirmAction.action === 'deactivate' ? 'danger' : 'primary'}
                onClick={confirmAction.action === 'deactivate' ? handleDeactivate : handleActivate}
                className="flex-1"
              >
                {confirmAction.action === 'deactivate' ? 'Deactivate' : 'Activate'}
              </Button>
              <Button variant="secondary" onClick={() => setConfirmAction(null)}>
                Cancel
              </Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}