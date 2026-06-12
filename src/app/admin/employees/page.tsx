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
import { Profile, UserRole, ShiftType } from '@/types';
import { getWIBDate, formatWIBDateDisplay } from '@/lib/timezone';
import { Users, Building2, UserCog, Download, Clock, UserPlus, Trash2, Eye, EyeOff } from 'lucide-react';

const PAGE_SIZE = 50;

export default function EmployeesPage() {
  const {
    employees, setEmployees, loading, fetchEmployees, updateEmployee,
    toggleRole, deactivateEmployee, activateEmployee, createEmployee,
    deleteEmployee,
  } = useEmployees();
  const { offices } = useOffices();

  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);

  // Edit modal
  const [editEmployee, setEditEmployee] = useState<Profile | null>(null);
  const [editFullName, setEditFullName] = useState('');
  const [editRole, setEditRole] = useState<UserRole>('viewer');
  const [editShift, setEditShift] = useState<ShiftType | ''>('');
  const [editPassword, setEditPassword] = useState('');
  const [saving, setSaving] = useState(false);
  
  const [showEditPassword, setShowEditPassword] = useState(false);
  const [showDetailPassword, setShowDetailPassword] = useState(false);
  
  // Delete confirm modal
  const [deleteConfirmEmployee, setDeleteConfirmEmployee] = useState<Profile | null>(null);

  // Detail modal
  const [detailEmployee, setDetailEmployee] = useState<Profile | null>(null);
  const [employeeHistory, setEmployeeHistory] = useState<unknown[]>([]);

  // Confirm modal
  const [confirmAction, setConfirmAction] = useState<{
    employee: Profile;
    action: 'deactivate' | 'activate';
    originalRole: UserRole;
  } | null>(null);

  // Add Employee modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [addFullName, setAddFullName] = useState('');
  const [addEmail, setAddEmail] = useState('');
  const [addPassword, setAddPassword] = useState('');
  const [addEmployeeId, setAddEmployeeId] = useState('');
  const [addRole, setAddRole] = useState<UserRole>('viewer');
  const [addShift, setAddShift] = useState<ShiftType | ''>('');
  const [addErrors, setAddErrors] = useState<Record<string, string>>({});

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
    setShowEditPassword(false);
    setEditEmployee(emp);
    setEditFullName(emp.full_name);
    // Convert old 'employee' role to 'viewer' (for backward compatibility)
    const currentRole = (emp.role as string) === 'employee' ? 'viewer' : emp.role;
    setEditRole(currentRole === 'inactive' ? 'viewer' : currentRole as UserRole);
    setEditShift(emp.shift_type || '');
    setEditPassword('');
    setSaving(false);
  };

  const handleSaveEdit = async () => {
    if (!editEmployee) return;

    // Optimistic update - langsung update UI tanpa loading
    const previousEmployees = [...employees];
    const updatedEmployee = {
      ...editEmployee,
      full_name: editFullName,
      role: editRole,
      shift_type: editShift || null,
      registered_password: editPassword || editEmployee.registered_password,
    };

    // Update state immediately
    setEmployees((prev) =>
      prev.map((e) => (e.id === editEmployee.id ? updatedEmployee : e))
    );
    setEditEmployee(null);

    // Send to server (fire and forget)
    const result = await updateEmployee(editEmployee.id, {
      full_name: editFullName,
      role: editRole,
      shift_type: editShift || null,
      password: editPassword || undefined,
    });

    if (result.success) {
      toast.success('Employee updated');
    } else {
      // Revert on failure
      setEmployees(previousEmployees);
      toast.error(result.error || 'Update failed');
    }
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
    setShowDetailPassword(false);
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
      const newRole = emp.role === 'admin' ? 'viewer' : 'admin';
      toast.success(`Role changed to ${newRole}`);
      load(search, page);
    } else {
      toast.error('Failed to update role');
    }
  };

  // Open add modal
  const openAddModal = () => {
    setAddFullName('');
    setAddEmail('');
    setAddPassword('');
    setAddEmployeeId('');
    setAddRole('viewer');
    setAddShift('');
    setAddErrors({});
    setShowAddModal(true);
  };

  // Validate add form
  const validateAddForm = (): boolean => {
    const errors: Record<string, string> = {};
    if (!addFullName.trim()) errors.full_name = 'Nama lengkap wajib diisi';
    if (!addEmail.trim()) errors.email = 'Email wajib diisi';
    else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(addEmail)) errors.email = 'Format email tidak valid';
    if (!addPassword) errors.password = 'Password wajib diisi';
    else if (addPassword.length < 8) errors.password = 'Password minimal 8 karakter';
    setAddErrors(errors);
    return Object.keys(errors).length === 0;
  };

  // Handle add employee
  const handleAddEmployee = async () => {
    if (!validateAddForm()) return;
    setSaving(true);
    const result = await createEmployee({
      email: addEmail,
      password: addPassword,
      full_name: addFullName,
      employee_id: addEmployeeId || undefined,
      role: addRole,
      shift_type: addShift || undefined,
    });
    setSaving(false);
    if (result.success) {
      toast.success(result.message || 'Karyawan berhasil ditambahkan');
      setShowAddModal(false);
      load(search, page);
    } else {
      toast.error(result.error || 'Gagal menambahkan karyawan');
    }
  };

  // Handle delete employee
  const handleDeleteEmployee = async () => {
    if (!deleteConfirmEmployee) return;
    setSaving(true);
    const result = await deleteEmployee(deleteConfirmEmployee.id);
    setSaving(false);
    if (result.success) {
      toast.success(result.message || 'Karyawan berhasil dihapus');
      setDeleteConfirmEmployee(null);
      load(search, page);
    } else {
      toast.error(result.error || 'Gagal menghapus karyawan');
    }
  };

  // CSV Export
  const exportCSV = () => {
    const headers = ['Name', 'Email', 'Role', 'Shift', 'Status', 'Created'];
    const rows = employees.map((e) => {
      const activeShift = e.today_shift_type || e.shift_type;
      return [
        e.full_name, e.email, e.role, 
        activeShift === 'morning' ? 'Pagi' : activeShift === 'afternoon' ? 'Siang' : activeShift === 'full_time' ? 'Full Time' : activeShift === 'non_shifting' ? 'Non-Shifting' : '—',
        'active', e.created_at,
      ];
    });
    const csv = [headers, ...rows]
      .map((r) => r.map((c) => `"${c}"`).join(','))
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `employees_${getWIBDate()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('CSV exported');
  };

  const activeEmployees = employees.filter((e) => e.role !== 'inactive' && e.role !== 'admin');

  return (
    <div className="space-y-5">
      {/* Search + Export */}
      <div className="flex flex-col sm:flex-row gap-3">
        <SearchInput
          value={search}
          onChange={handleSearch}
          placeholder="Search name, email..."
          className="flex-1"
        />
        <Button variant="secondary" onClick={exportCSV}>
          <Download className="w-4 h-4" /> Export CSV
        </Button>
        <Button variant="primary" onClick={openAddModal}>
          <UserPlus className="w-4 h-4" /> Tambah Karyawan
        </Button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
        <StatsCard icon={<UserCog className="w-6 h-6" />} value={employees.filter(e => e.role === 'viewer').length} label="Viewers" color="gray" />
        <StatsCard icon={<Users className="w-6 h-6" />} value={employees.filter(e => e.role === 'driver_bebas' || e.role === 'driver_kantor').length} label="Drivers" color="blue" />
        <StatsCard icon={<Users className="w-6 h-6" />} value={employees.filter(e => e.role === 'juru_parkir').length} label="Juru Parkir" color="green" />
        <StatsCard icon={<Users className="w-6 h-6" />} value={employees.filter(e => e.role === 'ob').length} label="OB" color="orange" />
        <StatsCard icon={<Clock className="w-6 h-6" />} value={activeEmployees.length} label="Total Active" color="purple" />
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead className="bg-gray-50 border-b">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Name</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Email</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Role</th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-600">Shift</th>
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
                        <span className="font-medium text-gray-900">{emp.full_name}</span>
                      </button>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{emp.email}</td>
                    <td className="px-4 py-3">
                      <Badge variant={
                        emp.role === 'admin' ? 'info' :
                        emp.role === 'viewer' ? 'default' :
                        emp.role === 'driver_bebas' || emp.role === 'driver_kantor' ? 'success' :
                        emp.role === 'juru_parkir' ? 'success' :
                        emp.role === 'ob' ? 'warning' :
                        emp.role === 'inactive' ? 'danger' : 'default'
                      }>
                        {emp.role === 'juru_parkir' ? 'Juru Parkir' : 
                         emp.role === 'ob' ? 'OB' : 
                         emp.role === 'viewer' ? 'Viewer' : 
                         emp.role === 'admin' ? 'Admin' :
                         emp.role}
                      </Badge>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <span className={`inline-block px-2.5 py-0.5 rounded-full text-xs font-semibold ${
                          (emp.today_shift_type || emp.shift_type) === 'morning'
                            ? 'bg-blue-100 text-blue-700'
                            : (emp.today_shift_type || emp.shift_type) === 'afternoon'
                            ? 'bg-orange-100 text-orange-700'
                            : (emp.today_shift_type || emp.shift_type) === 'full_time'
                            ? 'bg-purple-100 text-purple-700'
                            : 'bg-gray-100 text-gray-500'
                        }`}>
                          {(emp.today_shift_type || emp.shift_type) === 'morning' ? 'Pagi' :
                           (emp.today_shift_type || emp.shift_type) === 'afternoon' ? 'Siang' :
                           (emp.today_shift_type || emp.shift_type) === 'full_time' ? 'Full Time' :
                           (emp.today_shift_type || emp.shift_type) === 'non_shifting' ? 'Non-Shifting' :
                           '—'}
                        </span>
                        {emp.today_shift_type && (
                          <span className="text-[10px] font-bold text-green-600 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded leading-none">
                            Hari Ini
                          </span>
                        )}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Button size="sm" variant="ghost" onClick={() => openEdit(emp)}>
                          Edit
                        </Button>
                        <Button size="sm" variant="danger" className="text-xs py-1 px-2.5" onClick={() => setDeleteConfirmEmployee(emp)}>
                          <Trash2 className="w-3.5 h-3.5" /> Hapus
                        </Button>
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
            <FormSelect
              label="Role"
              value={editRole}
              onChange={(e) => setEditRole(e.target.value as UserRole)}
              options={[
                { value: 'juru_parkir', label: 'Juru Parkir' },
                  { value: 'driver_bebas', label: 'Driver (Bebas)' },
                  { value: 'driver_kantor', label: 'Driver (Kantor)' },
                { value: 'ob', label: 'OB' },
                { value: 'viewer', label: 'Viewer' },
                { value: 'inactive', label: 'Inactive' },
              ]}
            />
            <FormSelect
              label="Shift"
              value={editShift}
              onChange={(e) => setEditShift(e.target.value as ShiftType | '')}
              options={[
                { value: '', label: '—' },
                { value: 'non_shifting', label: 'Non-Shifting' },
                { value: 'full_time', label: 'Full Time (07:00-16:00)' },
                { value: 'morning', label: 'Pagi (06:00-14:00)' },
                { value: 'afternoon', label: 'Siang (10:00-18:00)' },
              ]}
            />
            <div className="space-y-1.5">
              <label className="block text-sm font-medium text-gray-700">Password Terdaftar</label>
              <div className="flex items-center gap-2 px-3 py-2 bg-gray-50 border rounded-lg text-sm text-gray-905 font-mono select-all">
                <span>{showEditPassword ? (editEmployee as any).registered_password || '—' : '••••••••'}</span>
                {(editEmployee as any).registered_password && (
                  <button
                    type="button"
                    onClick={() => setShowEditPassword(!showEditPassword)}
                    className="ml-auto p-1 text-gray-400 hover:text-gray-600 rounded"
                  >
                    {showEditPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                )}
              </div>
            </div>
            <FormInput
              label="Ganti Password Baru (Opsional)"
              type="password"
              value={editPassword}
              onChange={(e) => setEditPassword(e.target.value)}
              placeholder="Masukkan password baru untuk mengganti"
            />
            <div className="flex gap-2 pt-2">
              <Button onClick={handleSaveEdit} className="flex-1">
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
                <p className="font-medium text-gray-900">{detailEmployee.email}</p>
              </div>
              <div>
                <p className="text-gray-500">Password Terdaftar</p>
                <div className="flex items-center gap-2 mt-0.5">
                  <span className="font-medium text-gray-900 font-mono">
                    {showDetailPassword ? (detailEmployee as any).registered_password || '—' : '••••••••'}
                  </span>
                  {(detailEmployee as any).registered_password && (
                    <button
                      onClick={() => setShowDetailPassword(!showDetailPassword)}
                      className="p-1 text-gray-400 hover:text-gray-600 rounded"
                    >
                      {showDetailPassword ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                    </button>
                  )}
                </div>
              </div>
              <div>
                <p className="text-gray-500">Role</p>
                <Badge variant={
                  detailEmployee.role === 'admin' ? 'info' :
                  detailEmployee.role === 'viewer' ? 'default' :
                  detailEmployee.role === 'driver_bebas' || detailEmployee.role === 'driver_kantor' ? 'success' :
                  detailEmployee.role === 'juru_parkir' ? 'success' :
                  detailEmployee.role === 'ob' ? 'warning' :
                  detailEmployee.role === 'inactive' ? 'danger' : 'default'
                }>
                  {detailEmployee.role === 'juru_parkir' ? 'Juru Parkir' : 
                   detailEmployee.role === 'ob' ? 'OB' : 
                   detailEmployee.role === 'viewer' ? 'Viewer' : 
                   detailEmployee.role === 'admin' ? 'Admin' :
                   detailEmployee.role}
                </Badge>
              </div>
              <div>
                <p className="text-gray-500">Shift</p>
                <div className="flex items-center gap-1.5 font-medium mt-0.5">
                  <span>
                    {detailEmployee.today_shift_type ? (
                      detailEmployee.today_shift_type === 'morning' ? 'Pagi (06:00-14:00)' :
                      detailEmployee.today_shift_type === 'afternoon' ? 'Siang (10:00-18:00)' :
                      detailEmployee.today_shift_type === 'full_time' ? 'Full Time (07:00-16:00)' : '—'
                    ) : (
                      detailEmployee.shift_type === 'morning' ? 'Pagi (06:00-14:00)' :
                      detailEmployee.shift_type === 'afternoon' ? 'Siang (10:00-18:00)' :
                      detailEmployee.shift_type === 'full_time' ? 'Full Time (07:00-16:00)' :
                      detailEmployee.shift_type === 'non_shifting' ? 'Non-Shifting' :
                      '—'
                    )}
                  </span>
                  {detailEmployee.today_shift_type && (
                    <span className="text-[10px] font-bold text-green-600 bg-green-50 border border-green-200 px-1.5 py-0.5 rounded leading-none">
                      Hari Ini
                    </span>
                  )}
                </div>
              </div>
              <div>
                <p className="text-gray-500">Joined</p>
                <p className="font-medium text-gray-600">{formatWIBDateDisplay(detailEmployee.created_at)}</p>
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


      {/* Add Employee Modal */}
      <Modal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        title="Tambah Karyawan Baru"
        size="md"
      >
        <div className="space-y-4">
          <FormInput
            label="Nama Lengkap *"
            value={addFullName}
            onChange={(e) => setAddFullName(e.target.value)}
            error={addErrors.full_name}
            placeholder="Masukkan nama lengkap"
          />
          <FormInput
            label="Email *"
            type="email"
            value={addEmail}
            onChange={(e) => setAddEmail(e.target.value)}
            error={addErrors.email}
            placeholder="email@contoh.com"
          />
          <FormInput
            label="Password *"
            type="password"
            value={addPassword}
            onChange={(e) => setAddPassword(e.target.value)}
            error={addErrors.password}
            placeholder="Minimal 8 karakter"
          />
          <FormInput
            label="Employee ID"
            value={addEmployeeId}
            onChange={(e) => setAddEmployeeId(e.target.value)}
            placeholder="ID Karyawan"
          />
          <FormSelect
            label="Role *"
            value={addRole}
            onChange={(e) => setAddRole(e.target.value as UserRole)}
            options={[
              { value: 'juru_parkir', label: 'Juru Parkir' },
              { value: 'driver_bebas', label: 'Driver (Bebas)' },
              { value: 'driver_kantor', label: 'Driver (Kantor)' },
              { value: 'ob', label: 'OB' },
              { value: 'viewer', label: 'Viewer' },
            ]}
          />
          <FormSelect
            label="Shift"
            value={addShift}
            onChange={(e) => setAddShift(e.target.value as ShiftType | '')}
            options={[
              { value: '', label: '—' },
              { value: 'non_shifting', label: 'Non-Shifting' },
              { value: 'full_time', label: 'Full Time (07:00-16:00)' },
              { value: 'morning', label: 'Pagi (06:00-14:00)' },
              { value: 'afternoon', label: 'Siang (10:00-18:00)' },
            ]}
          />
          <div className="flex gap-2 pt-2">
            <Button onClick={handleAddEmployee} loading={saving} className="flex-1">
              <UserPlus className="w-4 h-4" /> Tambah Karyawan
            </Button>
            <Button variant="secondary" onClick={() => setShowAddModal(false)} disabled={saving}>
              Batal
            </Button>
          </div>
        </div>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={!!deleteConfirmEmployee}
        onClose={() => setDeleteConfirmEmployee(null)}
        title="Hapus Akun Karyawan"
        size="sm"
      >
        {deleteConfirmEmployee && (
          <div className="space-y-4">
            <div className="bg-red-50 text-red-800 p-3 rounded-lg text-sm border border-red-200">
              <p className="font-semibold">⚠️ Peringatan Kritis:</p>
              <p className="mt-1">
                Menghapus karyawan <strong>{deleteConfirmEmployee.full_name}</strong> ({deleteConfirmEmployee.email}) akan menghapus akun tersebut dari database <strong>secara permanen</strong>.
              </p>
              <p className="mt-1">
                Seluruh data riwayat kehadiran, durasi lembur, serta pengajuan cuti yang terkait akan dihapus bersih (CASCADE DELETE) dan tidak dapat dikembalikan.
              </p>
            </div>
            <p className="text-gray-600 text-sm">
              Apakah Anda yakin ingin melanjutkan tindakan ini?
            </p>
            <div className="flex gap-2 pt-2">
              <Button variant="danger" onClick={handleDeleteEmployee} loading={saving} className="flex-1">
                <Trash2 className="w-4 h-4" /> Ya, Hapus Akun
              </Button>
              <Button variant="secondary" onClick={() => setDeleteConfirmEmployee(null)} disabled={saving}>
                Batal
              </Button>
            </div>
          </div>
        )}
      </Modal>

    </div>
  );
}