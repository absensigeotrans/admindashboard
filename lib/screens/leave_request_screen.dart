import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/leave_service.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeaveService>(context, listen: false).fetchLeaveRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Cuti',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ajukan'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaveFormTab(onSubmitted: () {
            _tabController.animateTo(1);
          }),
          const _LeaveHistoryTab(),
        ],
      ),
      floatingActionButton: Consumer<LeaveService>(
        builder: (context, service, _) {
          final pending = service.pendingCount;
          if (pending == 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _tabController.animateTo(1),
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.pending_actions, color: Colors.white),
            label: Text(
              '$pending Menunggu',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      ),
    );
  }
}

// ─── Form Tab ───

class _LeaveFormTab extends StatefulWidget {
  final VoidCallback? onSubmitted;
  const _LeaveFormTab({this.onSubmitted});

  @override
  State<_LeaveFormTab> createState() => _LeaveFormTabState();
}

class _LeaveFormTabState extends State<_LeaveFormTab> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String _selectedType = 'cuti_tahunan';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _leaveTypes = [
    {'value': 'cuti_tahunan', 'label': 'Cuti Tahunan', 'icon': Icons.beach_access},
    {'value': 'cuti_sakit', 'label': 'Cuti Sakit', 'icon': Icons.local_hospital},
    {'value': 'cuti_darurat', 'label': 'Cuti Darurat', 'icon': Icons.warning_amber},
    {'value': 'izin_tidak_hadir', 'label': 'Izin Tidak Hadir', 'icon': Icons.event_busy},
  ];

  int get _totalDays {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays + 1;
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Mulai',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Selesai',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal mulai dan selesai'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final service = Provider.of<LeaveService>(context, listen: false);
    final success = await service.submitLeaveRequest(
      leaveType: _selectedType,
      startDate: _startDate!,
      endDate: _endDate!,
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _reasonController.clear();
        setState(() {
          _startDate = null;
          _endDate = null;
          _selectedType = 'cuti_tahunan';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan cuti berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSubmitted?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${service.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF005494).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF005494).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF005494)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pengajuan cuti akan ditinjau oleh Admin. Pastikan data yang diisi benar.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Leave Type Selector
            const Text(
              'Jenis Cuti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _leaveTypes.map((type) {
                final isSelected = _selectedType == type['value'];
                return InkWell(
                  onTap: () => setState(() => _selectedType = type['value']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF005494)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF005494)
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['label'],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Date Range
            const Text(
              'Periode Cuti',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _DateCard(
                    label: 'Mulai',
                    date: _startDate,
                    icon: Icons.play_arrow,
                    onTap: _selectStartDate,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey),
                ),
                Expanded(
                  child: _DateCard(
                    label: 'Selesai',
                    date: _endDate,
                    icon: Icons.stop,
                    onTap: _selectEndDate,
                  ),
                ),
              ],
            ),
            if (_totalDays > 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Total: $_totalDays hari',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Reason
            const Text(
              'Alasan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Contoh: Cuti tahunan untuk keluarga...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Alasan tidak boleh kosong' : null,
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005494),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text(
                            'Kirim Pengajuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final String label;
  final DateTime? date;
  final IconData icon;
  final VoidCallback onTap;

  const _DateCard({
    required this.label,
    required this.date,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: date != null ? const Color(0xFF005494).withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? const Color(0xFF005494) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              date != null ? DateFormat('dd MMM yyyy').format(date!) : 'Pilih...',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: date != null ? const Color(0xFF005494) : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History Tab ───

class _LeaveHistoryTab extends StatelessWidget {
  const _LeaveHistoryTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<LeaveService>(
      builder: (context, service, _) {
        if (service.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (service.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${service.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => service.fetchLeaveRequests(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (service.leaveList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada pengajuan cuti',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => service.fetchLeaveRequests(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.leaveList.length,
            itemBuilder: (context, index) {
              final leave = service.leaveList[index];
              return _LeaveCard(leave: leave);
            },
          ),
        );
      },
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequest leave;

  const _LeaveCard({required this.leave});

  String _leaveTypeLabel(String type) {
    switch (type) {
      case 'cuti_tahunan': return 'Cuti Tahunan';
      case 'cuti_sakit': return 'Cuti Sakit';
      case 'cuti_darurat': return 'Cuti Darurat';
      case 'izin_tidak_hadir': return 'Izin Tidak Hadir';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005494).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        size: 20,
                        color: Color(0xFF005494),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _leaveTypeLabel(leave.leaveType),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${leave.totalDays} hari',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: leave.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    leave.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: leave.status.color,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Date Range
            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reason
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    leave.reason,
                    style: TextStyle(color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Admin Note (if any)
            if (leave.adminNote != null && leave.adminNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Admin:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      leave.adminNote!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),
            Text(
              'Diajukan: ${DateFormat('dd MMM yyyy').format(leave.createdAt)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),

            // Cancel Button (only for pending)
            if (leave.status == LeaveStatus.pending) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context, leave),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Batalkan Pengajuan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, LeaveRequest leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pengajuan?'),
        content: Text(
          'Yakin ingin membatalkan pengajuan cuti ${DateFormat('dd MMM yyyy').format(leave.startDate)} - ${DateFormat('dd MMM yyyy').format(leave.endDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final service = Provider.of<LeaveService>(context, listen: false);
              final success = await service.cancelLeaveRequest(leave.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Pengajuan berhasil dibatalkan'
                          : 'Gagal membatalkan pengajuan',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}