'use client';

import { useState, useCallback, useEffect, useMemo } from 'react';
import { useReports } from '@/hooks/useReports';
import { useAuth } from '@/context/AuthContext';
import { SearchInput } from '@/components/ui/SearchInput';
import { DateRangePicker } from '@/components/ui/DateRangePicker';
import { Pagination } from '@/components/ui/Pagination';
import { StatsCard } from '@/components/ui/StatsCard';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Table } from '@/components/ui/Table';
import { toast } from '@/components/ui/Toast';
import { Attendance, AttendanceStatus, ShiftType } from '@/types';
import { format } from 'date-fns';
import { formatDistance } from '@/lib/utils';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { Download, FileText, CheckCircle, Clock, XCircle, FileDown, AlertTriangle, Database, Sun, Sunset, Trash2, Calendar } from 'lucide-react';

const PAGE_SIZE = 50;

export default function ReportsPage() {
  const { profile } = useAuth();
  const { records, loading, fetchReportWithUsers, getStats, error, getShiftLabel, deleteByDate } = useReports();

  const [from, setFrom] = useState(() => {
    const d = new Date(); d.setDate(d.getDate() - 30);
    return d.toISOString().split('T')[0];
  });
  const [to, setTo] = useState(() => new Date().toISOString().split('T')[0]);
  const [status, setStatus] = useState<AttendanceStatus | ''>('');
  const [mockFilter, setMockFilter] = useState<string>('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [stats, setStats] = useState({ total: 0, present: 0, late: 0, outside: 0, suspicious: 0, avgDistance: 0 });
  const [exportLoading, setExportLoading] = useState(false);
  // Sorting state
  const [sortKey, setSortKey] = useState<string>('date');
  const [sortDir, setSortDir] = useState<'asc' | 'desc'>('desc');
  // Delete modal state
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteDate, setDeleteDate] = useState('');
  const [deleting, setDeleting] = useState(false);

  const load = useCallback(async (f = from, t = to, s = status, p = page, q = search) => {
    // Driver role doesn't use geofencing, so exclude 'outside_radius' status
    const isDriver = profile?.role === 'driver';
    const result = await fetchReportWithUsers({
      from: f,
      to: t,
      status: s || undefined,
      search: q || undefined,
      excludeOutsideRadius: isDriver,
    }, p, PAGE_SIZE);
    setTotal(result.count);
  }, [fetchReportWithUsers, page, profile?.role]);

  useEffect(() => { load(); }, [load]);

  // Compute filtered records
  const filteredRecords = useMemo(() => {
    let recs = mockFilter === 'suspicious'
      ? records.filter((r) => r.is_mocked)
      : records;

    // Apply sorting
    recs = [...recs].sort((a, b) => {
      let cmp = 0;
      switch (sortKey) {
        case 'date':
          cmp = new Date(a.check_in_time).getTime() - new Date(b.check_in_time).getTime();
          break;
        case 'time':
          cmp = new Date(a.check_in_time).getTime() - new Date(b.check_in_time).getTime();
          break;
        case 'check_out':
          const aOut = a.check_out_time ? new Date(a.check_out_time).getTime() : 0;
          const bOut = b.check_out_time ? new Date(b.check_out_time).getTime() : 0;
          cmp = aOut - bOut;
          break;
        case 'distance':
          cmp = (a.distance_from_office || 0) - (b.distance_from_office || 0);
          break;
        default:
          cmp = 0;
      }
      return sortDir === 'asc' ? cmp : -cmp;
    });

    return recs;
  }, [records, mockFilter, sortKey, sortDir]);

  // Update stats when filtered records change
  useEffect(() => {
    const computed = getStats(filteredRecords);
    setStats(computed);
  }, [filteredRecords, getStats]);

  const handleFilter = () => {
    setPage(1);
    load(from, to, status, 1, search);
  };

  const handleReset = () => {
    setFrom(new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0]);
    setTo(new Date().toISOString().split('T')[0]);
    setStatus('');
    setMockFilter('');
    setSearch('');
    setPage(1);
    setSortKey('date');
    setSortDir('desc');
    load(new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0], new Date().toISOString().split('T')[0], '', 1, '');
  };

  // Handle sort
  const handleSort = (key: string) => {
    if (sortKey === key) {
      setSortDir((d) => d === 'asc' ? 'desc' : 'asc');
    } else {
      setSortKey(key);
      setSortDir('desc');
    }
  };

  // CSV Export of currently displayed records
  const exportCSV = () => {
    const headers = ['Employee', 'Date', 'Check-in Time', 'Check-out Time', 'Status', 'Shift', 'Distance', 'Lat', 'Lng', 'Suspicious'];
    const rows = filteredRecords.map((r: any) => [
      r.profiles?.full_name || '',
      format(new Date(r.check_in_time), 'yyyy-MM-dd'),
      format(new Date(r.check_in_time), 'HH:mm:ss'),
      r.check_out_time ? format(new Date(r.check_out_time), 'HH:mm:ss') : '',
      r.status,
      getShiftLabel(r.shift_type),
      (r.distance_from_office || 0).toFixed(2) + 'm',
      r.check_in_latitude || '',
      r.check_in_longitude || '',
      r.is_mocked ? 'YES' : 'NO',
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `attendance_report_${from}_to_${to}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success(`Exported ${filteredRecords.length} records`);
  };

  const exportPDF = () => {
    const doc = new jsPDF('landscape');
    const title = `Attendance Report (${from} to ${to})`;
    doc.setFontSize(16);
    doc.text(title, 14, 16);
    doc.setFontSize(10);
    doc.text(`Generated: ${new Date().toLocaleString('id-ID')}`, 14, 23);
    doc.text(`Total: ${stats.total} | Present: ${stats.present} | Late: ${stats.late} | Outside: ${stats.outside} | Avg: ${formatDistance(stats.avgDistance)}`, 14, 30);

    const headers = [['Employee', 'Date', 'Check-in', 'Check-out', 'Status', 'Shift', 'Distance', 'Coordinates', 'Suspicious']];
    const rows = filteredRecords.map((r: any) => [
      r.profiles?.full_name || '—',
      format(new Date(r.check_in_time), 'dd MMM yyyy'),
      format(new Date(r.check_in_time), 'HH:mm'),
      r.check_out_time ? format(new Date(r.check_out_time), 'HH:mm') : '—',
      r.status.replace('_', ' '),
      getShiftLabel(r.shift_type),
      formatDistance(r.distance_from_office || 0),
      `${r.check_in_latitude?.toFixed(4) || '-'}, ${r.check_in_longitude?.toFixed(4) || '-'}`,
      r.is_mocked ? 'YES' : 'NO',
    ]);

    autoTable(doc, {
      head: headers,
      body: rows,
      startY: 36,
      styles: { fontSize: 8 },
      headStyles: { fillColor: [37, 99, 235] },
      alternateRowStyles: { fillColor: [245, 247, 250] },
    });

    doc.save(`attendance_report_${from}_to_${to}.pdf`);
    toast.success(`Exported ${filteredRecords.length} records`);
  };

  // Open delete modal
  const openDeleteModal = () => {
    setDeleteDate(new Date().toISOString().split('T')[0]);
    setShowDeleteModal(true);
  };

  // Handle delete by date
  const handleDeleteByDate = async () => {
    if (!deleteDate) {
      toast.error('Pilih tanggal terlebih dahulu');
      return;
    }
    setDeleting(true);
    const result = await deleteByDate(deleteDate);
    setDeleting(false);

    if (result.success) {
      setShowDeleteModal(false);
      // Refresh data
      load(from, to, status, 1, search);
      // Show success with count
      if (result.count === 0) {
        toast.warning('Tidak ada data kehadiran untuk tanggal tersebut');
      } else {
        toast.success(result.message || `Berhasil menghapus ${result.count} data`);
      }
    } else {
      toast.error(result.error || 'Gagal menghapus data');
    }
  };

  const columns = [
    {
      key: 'user',
      header: 'Employee',
      render: (row: any) => (
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center text-xs font-semibold">
            {(row.profiles?.full_name || '?').charAt(0).toUpperCase()}
          </div>
          <span className="font-medium text-gray-900">{row.profiles?.full_name ?? '—'}</span>
        </div>
      ),
    },
    {
      key: 'date',
      header: 'Date',
      sortable: true,
      render: (row: any) => format(new Date(row.check_in_time), 'dd MMM yyyy'),
    },
    {
      key: 'time',
      header: 'Check-in',
      sortable: true,
      render: (row: any) => format(new Date(row.check_in_time), 'HH:mm'),
    },
    {
      key: 'check_out',
      header: 'Check-out',
      sortable: true,
      render: (row: any) => row.check_out_time ? format(new Date(row.check_out_time), 'HH:mm') : '—',
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: any) => (
        <div className="flex items-center gap-2">
          <Badge variant={row.status === 'present' ? 'success' : row.status === 'late' ? 'warning' : 'danger'}>
            {row.status.replace('_', ' ')}
          </Badge>
          {row.is_mocked && (
            <Badge variant="danger">Suspicious</Badge>
          )}
        </div>
      ),
    },
    {
      key: 'shift',
      header: 'Shift',
      render: (row: any) => {
        const shiftLabel = getShiftLabel(row.shift_type);
        if (!row.shift_type) return <span className="text-gray-400 text-xs">—</span>;
        return (
          <div className="flex items-center gap-1">
            {row.shift_type === 'morning' ? (
              <Sun className="w-3 h-3 text-yellow-600" />
            ) : (
              <Sunset className="w-3 h-3 text-orange-500" />
            )}
            <span className={`text-xs font-medium ${row.shift_type === 'morning' ? 'text-yellow-700' : 'text-orange-700'}`}>
              {shiftLabel}
            </span>
          </div>
        );
      },
    },
    {
      key: 'distance',
      header: 'Distance',
      sortable: true,
      render: (row: any) => formatDistance(row.distance_from_office || 0),
    },
    {
      key: 'location',
      header: 'Location',
      render: (row: any) => (
        <span className="text-xs text-gray-500">
          {row.check_in_latitude?.toFixed(4) ?? '-'}, {row.check_in_longitude?.toFixed(4) ?? '-'}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-5">
      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm border p-5">
        <div className="flex flex-col lg:flex-row gap-3 items-end">
          {/* Search Input */}
          <div className="w-full lg:w-64">
            <label className="block text-xs font-medium text-gray-500 mb-1">Search Employee</label>
            <SearchInput
              value={search}
              onChange={setSearch}
              placeholder="Search name..."
            />
          </div>
          {/* Date Range */}
          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-500 mb-1">Date Range</label>
            <DateRangePicker from={from} to={to} onFromChange={setFrom} onToChange={setTo} />
          </div>
          {/* Status Filter */}
          <div className="w-full lg:w-48">
            <label className="block text-xs font-medium text-gray-500 mb-1">Status</label>
            <select
              value={status}
              onChange={(e) => setStatus(e.target.value as AttendanceStatus | '')}
              className="w-full px-3 py-2.5 border rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">All Status</option>
              <option value="present">Present</option>
              <option value="late">Late</option>
            </select>
          </div>
          {/* Location Anomaly Filter */}
          <div className="w-full lg:w-48">
            <label className="block text-xs font-medium text-gray-500 mb-1">Kejanggalan Lokasi</label>
            <select
              value={mockFilter}
              onChange={(e) => { setMockFilter(e.target.value); setPage(1); }}
              className="w-full px-3 py-2.5 border rounded-xl text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">Semua Records</option>
              <option value="suspicious">Hanya Kejanggalan</option>
            </select>
          </div>
          {/* Action Buttons */}
          <div className="flex gap-2">
            <Button onClick={handleFilter}>Apply Filters</Button>
            <Button variant="ghost" onClick={handleReset}>Reset</Button>
          </div>
        </div>
        {/* Export Buttons Row */}
        <div className="flex gap-2 mt-3 pt-3 border-t flex-wrap">
          <Button variant="secondary" onClick={exportCSV}>
            <Download className="w-4 h-4" /> Export CSV ({filteredRecords.length})
          </Button>
          <Button variant="secondary" onClick={exportPDF}>
            <FileDown className="w-4 h-4" /> Export PDF ({filteredRecords.length})
          </Button>
          {filteredRecords.length > 1000 && (
            <span className="flex items-center gap-1 text-xs text-yellow-600 ml-2">
              <AlertTriangle className="w-3 h-3" />
              Large export ({filteredRecords.length} records)
            </span>
          )}
          {/* Delete Button */}
          <div className="ml-auto">
            <Button variant="danger" onClick={openDeleteModal}>
              <Trash2 className="w-4 h-4" /> Hapus Data
            </Button>
          </div>
        </div>
      </div>

      {/* Error display */}
      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-xl text-sm">
          {error}
        </div>
      )}

      {/* Summary Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard icon={<FileText className="w-5 h-5" />} value={stats.total} label="Total Records" color="blue" />
        <StatsCard icon={<CheckCircle className="w-5 h-5" />} value={stats.present} label="Present" color="green" />
        <StatsCard icon={<Clock className="w-5 h-5" />} value={stats.late} label="Late" color="yellow" />
        <StatsCard icon={<AlertTriangle className="w-5 h-5" />} value={stats.suspicious} label="Kejanggalan" color="red" />
      </div>

      {/* Table with Sort Handler */}
      <Table
        columns={columns}
        data={filteredRecords}
        loading={loading}
        emptyText="No attendance records found for the selected filters"
        sortKey={sortKey}
        sortDir={sortDir}
        onSort={handleSort}
      />

      {/* Pagination */}
      <Pagination
        currentPage={page}
        totalPages={Math.ceil(total / PAGE_SIZE)}
        onPageChange={(p) => { setPage(p); load(from, to, status, p, search); }}
      />

      {/* Delete Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
            <div className="bg-red-600 px-6 py-4 flex items-center gap-3">
              <Trash2 className="w-5 h-5 text-white" />
              <h3 className="text-lg font-semibold text-white">Hapus Data Kehadiran</h3>
            </div>
            <div className="p-6">
              <div className="flex items-start gap-4 mb-6">
                <div className="w-12 h-12 rounded-full bg-red-100 flex items-center justify-center flex-shrink-0">
                  <AlertTriangle className="w-6 h-6 text-red-600" />
                </div>
                <div>
                  <h4 className="font-semibold text-gray-900 mb-1">Peringatan! Aksi ini tidak dapat dibatalkan.</h4>
                  <p className="text-sm text-gray-600">
                    Semua data kehadiran pada tanggal yang dipilih akan dihapus secara permanen.
                  </p>
                </div>
              </div>

              <div className="mb-6">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  <Calendar className="w-4 h-4 inline mr-1" />
                  Pilih Tanggal
                </label>
                <input
                  type="date"
                  value={deleteDate}
                  onChange={(e) => setDeleteDate(e.target.value)}
                  className="w-full px-4 py-3 border border-gray-300 rounded-xl focus:outline-none focus:ring-2 focus:ring-red-500 focus:border-red-500"
                  max={new Date().toISOString().split('T')[0]}
                />
              </div>

              {deleteDate && (
                <div className="bg-yellow-50 border border-yellow-200 rounded-xl p-4 mb-6">
                  <p className="text-sm text-yellow-800">
                    <strong>Catatan:</strong> Data kehadiran untuk tanggal{' '}
                    <strong>{format(new Date(deleteDate + 'T00:00:00'), 'dd MMMM yyyy')}</strong>{' '}
                    akan dihapus secara permanen.
                  </p>
                </div>
              )}

              <div className="flex gap-3">
                <Button
                  variant="ghost"
                  onClick={() => setShowDeleteModal(false)}
                  className="flex-1"
                  disabled={deleting}
                >
                  Batal
                </Button>
                <Button
                  variant="danger"
                  onClick={handleDeleteByDate}
                  className="flex-1"
                  disabled={!deleteDate || deleting}
                >
                  {deleting ? (
                    <span className="flex items-center gap-2">
                      <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Menghapus...
                    </span>
                  ) : (
                    <>
                      <Trash2 className="w-4 h-4" />
                      Hapus Permanen
                    </>
                  )}
                </Button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}