'use client';

import { useState, useCallback, useEffect } from 'react';
import { useReports } from '@/hooks/useReports';
import { SearchInput } from '@/components/ui/SearchInput';
import { DateRangePicker } from '@/components/ui/DateRangePicker';
import { Pagination } from '@/components/ui/Pagination';
import { StatsCard } from '@/components/ui/StatsCard';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Table } from '@/components/ui/Table';
import { toast } from '@/components/ui/Toast';
import { Attendance, AttendanceStatus } from '@/types';
import { format } from 'date-fns';
import { formatDistance } from '@/lib/utils';
import jsPDF from 'jspdf';
import autoTable from 'jspdf-autotable';
import { Download, FileText, CheckCircle, Clock, XCircle, FileDown } from 'lucide-react';

const PAGE_SIZE = 50;

export default function ReportsPage() {
  const { records, loading, fetchReportWithUsers, getStats } = useReports();

  const [from, setFrom] = useState(() => {
    const d = new Date(); d.setDate(d.getDate() - 30);
    return d.toISOString().split('T')[0];
  });
  const [to, setTo] = useState(() => new Date().toISOString().split('T')[0]);
  const [status, setStatus] = useState<AttendanceStatus | ''>('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [stats, setStats] = useState({ total: 0, present: 0, late: 0, outside: 0, avgDistance: 0 });

  const load = useCallback(async (f = from, t = to, s = status, p = page) => {
    const result = await fetchReportWithUsers({ from: f, to: t, status: s || undefined }, p, PAGE_SIZE);
    setTotal(result.count);
    const computed = getStats(result.data);
    setStats(computed);
  }, [fetchReportWithUsers, getStats, page]);

  useEffect(() => { load(); }, [load]);

  const handleFilter = () => {
    setPage(1);
    load(from, to, status, 1);
  };

  const handleReset = () => {
    setFrom(new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0]);
    setTo(new Date().toISOString().split('T')[0]);
    setStatus('');
    setSearch('');
    setPage(1);
    load(new Date(Date.now() - 30 * 86400000).toISOString().split('T')[0], new Date().toISOString().split('T')[0], '', 1);
  };

  // CSV Export of filtered records
  const exportCSV = () => {
    const headers = ['Date', 'Check-in Time', 'Check-out Time', 'Status', 'Distance', 'Lat', 'Lng'];
    const rows = records.map((r) => [
      format(new Date(r.check_in_time), 'yyyy-MM-dd'),
      format(new Date(r.check_in_time), 'HH:mm:ss'),
      r.check_out_time ? format(new Date(r.check_out_time), 'HH:mm:ss') : '',
      r.status,
      r.distance_from_office.toFixed(2) + 'm',
      r.latitude,
      r.longitude,
    ]);
    const csv = [headers, ...rows].map((r) => r.map((c) => `"${c}"`).join(',')).join('\n');
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `attendance_report_${from}_to_${to}.csv`;
    a.click();
    URL.revokeObjectURL(url);
    toast.success('Report exported');
  };

  const exportPDF = () => {
    const doc = new jsPDF('landscape');
    const title = `Attendance Report (${from} to ${to})`;
    doc.setFontSize(16);
    doc.text(title, 14, 16);
    doc.setFontSize(10);
    doc.text(`Generated: ${new Date().toLocaleString('id-ID')}`, 14, 23);
    doc.text(`Total Records: ${stats.total} | Present: ${stats.present} | Late: ${stats.late} | Outside: ${stats.outside} | Avg Distance: ${formatDistance(stats.avgDistance)}`, 14, 30);

    const headers = [['Date', 'Check-in', 'Check-out', 'Status', 'Distance', 'Coordinates']];
    const rows = records.map((r) => [
      format(new Date(r.check_in_time), 'dd MMM yyyy'),
      format(new Date(r.check_in_time), 'HH:mm'),
      r.check_out_time ? format(new Date(r.check_out_time), 'HH:mm') : '—',
      r.status.replace('_', ' '),
      formatDistance(r.distance_from_office),
      `${r.latitude.toFixed(4)}, ${r.longitude.toFixed(4)}`,
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
    toast.success('PDF report exported');
  };

  const columns = [
    {
      key: 'date',
      header: 'Date',
      sortable: true,
      render: (row: Attendance) => format(new Date(row.check_in_time), 'dd MMM yyyy'),
    },
    {
      key: 'time',
      header: 'Check-in',
      render: (row: Attendance) => format(new Date(row.check_in_time), 'HH:mm'),
    },
    {
      key: 'check_out',
      header: 'Check-out',
      render: (row: Attendance) => row.check_out_time ? format(new Date(row.check_out_time), 'HH:mm') : '—',
    },
    {
      key: 'status',
      header: 'Status',
      render: (row: Attendance) => (
        <Badge variant={row.status === 'present' ? 'success' : row.status === 'late' ? 'warning' : 'danger'}>
          {row.status.replace('_', ' ')}
        </Badge>
      ),
    },
    {
      key: 'distance',
      header: 'Distance',
      sortable: true,
      render: (row: Attendance) => formatDistance(row.distance_from_office),
    },
    {
      key: 'location',
      header: 'Location',
      render: (row: Attendance) => (
        <span className="text-xs text-gray-500">
          {row.latitude.toFixed(4)}, {row.longitude.toFixed(4)}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-5">
      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm border p-5">
        <div className="flex flex-col lg:flex-row gap-3 items-end">
          <div className="flex-1">
            <label className="block text-xs font-medium text-gray-500 mb-1">Date Range</label>
            <DateRangePicker from={from} to={to} onFromChange={setFrom} onToChange={setTo} />
          </div>
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
              <option value="outside_radius">Outside Radius</option>
            </select>
          </div>
          <div className="flex gap-2">
            <Button onClick={handleFilter}>Apply Filters</Button>
            <Button variant="ghost" onClick={handleReset}>Reset</Button>
            <Button variant="secondary" onClick={exportCSV}>
              <Download className="w-4 h-4" /> Export CSV
            </Button>
            <Button variant="secondary" onClick={exportPDF}>
              <FileDown className="w-4 h-4" /> Export PDF
            </Button>
          </div>
        </div>
      </div>

      {/* Summary Stats */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatsCard icon={<FileText className="w-5 h-5" />} value={stats.total} label="Total Records" color="blue" />
        <StatsCard icon={<CheckCircle className="w-5 h-5" />} value={stats.present} label="Present" color="green" />
        <StatsCard icon={<Clock className="w-5 h-5" />} value={stats.late} label="Late" color="yellow" />
        <StatsCard icon={<XCircle className="w-5 h-5" />} value={stats.outside} label="Outside" color="red" />
      </div>

      {/* Table */}
      <Table
        columns={columns}
        data={records}
        loading={loading}
        emptyText="No attendance records found for the selected filters"
        sortKey="date"
        sortDir="desc"
      />

      {/* Pagination */}
      <Pagination
        currentPage={page}
        totalPages={Math.ceil(total / PAGE_SIZE)}
        onPageChange={(p) => { setPage(p); load(from, to, status, p); }}
      />
    </div>
  );
}