import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/report_service.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({super.key});

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedUserId;
  String? _selectedWorkStatus;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _attendanceRecords = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _fetchAttendanceRecords();
  }

  Future<void> _loadUsers() async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    if (mounted) {
      setState(() {
        _users = adminService.allUsers;
      });
    }
  }

  Future<void> _fetchAttendanceRecords() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final records = await adminService.fetchAttendanceRecords(
        userId: _selectedUserId,
        startDate: _startDate,
        endDate: _endDate,
        workStatus: _selectedWorkStatus,
      );
      
      if (mounted) {
        setState(() {
          _attendanceRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generatePdfReport() async {
    if (_attendanceRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk dilapor')),
      );
      return;
    }

    // Get user info for report
    final selectedUser = _users.firstWhere(
      (u) => u['id'] == _selectedUserId,
      orElse: () => {'full_name': 'Semua User', 'employee_id': ''},
    );

    try {
      await ReportService.generateAttendancePdf(
        fullName: selectedUser['full_name'] ?? 'Semua User',
        employeeId: selectedUser['employee_id'] ?? '',
        attendanceData: _attendanceRecords,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghasilkan PDF: $e')),
        );
      }
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      // Parse as UTC time (as stored in database)
      final dateTimeUtc = DateTime.parse(dateTimeStr).toUtc();
      // Convert to WIB (UTC+7)
      final dateTimeWib = dateTimeUtc.add(const Duration(hours: 7));
      return DateFormat('dd/MM HH:mm').format(dateTimeWib);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kehadiran'),
        centerTitle: true,
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchAttendanceRecords,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Filter Controls
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Date Range
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Tanggal Mulai',
                                        border: OutlineInputBorder(),
                                        suffixIcon: const Icon(Icons.calendar_today),
                                      ),
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _startDate,
                                          firstDate:
                                              DateTime.now().subtract(const Duration(days: 365)),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null && mounted) {
                                          setState(() {
                                            _startDate = date;
                                          });
                                          _fetchAttendanceRecords();
                                        }
                                      },
                                      controller: TextEditingController(
                                          text: _formatDate(_startDate)),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Tanggal Akhir',
                                        border: OutlineInputBorder(),
                                        suffixIcon: const Icon(Icons.calendar_today),
                                      ),
                                      onTap: () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _endDate,
                                          firstDate:
                                              DateTime.now().subtract(const Duration(days: 365)),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null && mounted) {
                                          setState(() {
                                            _endDate = date;
                                          });
                                          _fetchAttendanceRecords();
                                        }
                                      },
                                      controller: TextEditingController(
                                          text: _formatDate(_endDate)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // User Filter
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Pilih User',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                initialValue: _selectedUserId,
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Semua User'),
                                  ),
                                  ..._users.map((user) => DropdownMenuItem<String>(
                                    value: user['id'] as String?,
                                    child: Text(
                                        '${user['full_name']} (${user['employee_id']})'),
                                  )),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedUserId = newValue;
                                  });
                                  _fetchAttendanceRecords();
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Status Kerja',
                                  border: OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                initialValue: _selectedWorkStatus,
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('Semua Status'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'WFO',
                                    child: Text('WFO'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'WFH',
                                    child: Text('WFH'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'DINAS',
                                    child: Text('DINAS'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'LAINNYA',
                                    child: Text('Lainnya'),
                                  ),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedWorkStatus = newValue;
                                  });
                                  _fetchAttendanceRecords();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary Statistics
                      if (_attendanceRecords.isNotEmpty)
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ringkasan Laporan',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    _buildSummaryItem(
                                        'Total Records',
                                        '${_attendanceRecords.length}',
                                        Icons.description,
                                        Colors.blue),
                                    _buildSummaryItem(
                                        'Check-In Hari Ini',
                                        '${_attendanceRecords.where((r) => r['check_out_time'] == null).length}',
                                        Icons.access_time,
                                        Colors.orange),
                                    _buildSummaryItem(
                                        'Check-Out Lengkap',
                                        '${_attendanceRecords.where((r) => r['check_out_time'] != null).length}',
                                        Icons.check_circle,
                                        Colors.green),
                                    _buildSummaryItem(
                                        'WFH',
                                        '${_attendanceRecords.where((r) => r['work_status'] == 'WFH').length}',
                                        Icons.home,
                                        Colors.green),
                                    _buildSummaryItem(
                                        'WFO',
                                        '${_attendanceRecords.where((r) => r['work_status'] == 'WFO').length}',
                                        Icons.work,
                                        Colors.blue),
                                    _buildSummaryItem(
                                        'DINAS',
                                        '${_attendanceRecords.where((r) => r['work_status'] == 'DINAS').length}',
                                        Icons.flight_takeoff,
                                        Colors.purple),
                                    _buildSummaryItem(
                                        'Lainnya',
                                        '${_attendanceRecords.where((r) => r['work_status'] == 'LAINNYA').length}',
                                        Icons.more_horiz,
                                        Colors.grey),
                                    const SizedBox(width: 24),
                                    _buildSummaryItem(
                                        'Total Lembur',
                                        '${_attendanceRecords.fold<int>(0, (sum, r) => sum + ((r['overtime_minutes'] as num?)?.toInt() ?? 0))} menit',
                                        Icons.timer,
                                        Colors.orange),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                         )
                       else
                         const Center(
                             child: Text('Tidak ada data untuk periode yang dipilih')),
                      const SizedBox(height: 16),
                      // Attendance Records Table
                      Expanded(
                        child: _attendanceRecords.isEmpty
                            ? const Center(child: Text('Tidak ada data'))
                            : ListView.builder(
                                itemCount: _attendanceRecords.length,
                                itemBuilder: (context, index) {
                                  final record = _attendanceRecords[index];
                                  final user = _users.firstWhere(
                                    (u) => u['id'] == record['user_id'],
                                    orElse: () => {
                                      'full_name': 'Unknown',
                                      'employee_id': 'N/A'
                                    },
                                  );

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Header with user info
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${user['full_name']} (${user['employee_id']})',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              // Work status badge
                                              _buildWorkStatusBadge(
                                                  record['work_status'] as String?),
                                              const SizedBox(width: 8),
                                              // Attendance status indicator
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                 decoration: BoxDecoration(
                                                  color: _getStatusColor(record['status'])
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  record['status'] ?? '-',
                                                  style: TextStyle(
                                                    color: _getStatusColor(record['status']),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Details
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Tanggal: ${_formatDateTime(record['check_in_time']?.substring(0, 10))}',
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                    Text(
                                                        'Check-In: ${_formatDateTime(record['check_in_time'])}',
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                    Text(
                                                        'Check-Out: ${_formatDateTime(record['check_out_time'])}',
                                                        style: const TextStyle(
                                                            fontSize: 12)),

                                                    Text(
                                                        'Validitas: ${record['is_mocked'] == true ? 'Fake GPS' : 'Valid'}',
                                                        style: const TextStyle(
                                                            fontSize: 12)),
                                                    Row(
                                                      children: [
                                                        const Text('Lembur: ',
                                                            style: TextStyle(fontSize: 12)),
                                                        if (record['overtime_minutes'] != null && (record['overtime_minutes'] as num) > 0)
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                                horizontal: 6, vertical: 2),
                                                            decoration: BoxDecoration(
                                                              color: Colors.orange.withValues(alpha: 0.2),
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              '${record['overtime_minutes']} menit',
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.orange),
                                                            ),
                                                          )
                                                        else
                                                          const Text('-',
                                                              style: TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _attendanceRecords.isEmpty
                                  ? null
                                  : _generatePdfReport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF005494),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Export ke PDF'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _fetchAttendanceRecords,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF005494)),
                              ),
                              child: const Text('Refresh'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'outside_radius':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getWorkStatusColor(String? workStatus) {
    switch (workStatus) {
      case 'WFO':
        return Colors.blue;
      case 'WFH':
        return Colors.green;
      case 'DINAS':
        return Colors.purple;
      case 'LAINNYA':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildWorkStatusBadge(String? workStatus) {
    final color = _getWorkStatusColor(workStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        workStatus ?? '-',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7))),
      ],
    );
  }
}