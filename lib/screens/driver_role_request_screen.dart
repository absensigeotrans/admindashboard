import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/driver_role_request_service.dart';
import '../services/auth_service.dart';

class DriverRoleRequestScreen extends StatefulWidget {
  const DriverRoleRequestScreen({super.key});

  @override
  State<DriverRoleRequestScreen> createState() => _DriverRoleRequestScreenState();
}

class _DriverRoleRequestScreenState extends State<DriverRoleRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DriverRoleRequestService>(context, listen: false).fetchRequests();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitRequest(String currentRole) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final targetRole = currentRole == 'driver_kantor' ? 'driver_bebas' : 'driver_kantor';
    final service = Provider.of<DriverRoleRequestService>(context, listen: false);
    
    final success = await service.submitRequest(
      fromRole: currentRole,
      toRole: targetRole,
      reason: _reasonController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _reasonController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan berhasil dikirim'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pengajuan: ${service.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _getRoleLabel(String role) {
    if (role == 'driver_bebas') return 'Driver (Bebas)';
    if (role == 'driver_kantor') return 'Driver (Kantor)';
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final currentRole = auth.profile?['role'] ?? '';
    final service = Provider.of<DriverRoleRequestService>(context);

    final targetRole = currentRole == 'driver_kantor' ? 'driver_bebas' : 'driver_kantor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Ganti Role', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Form Request
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Buat Pengajuan Baru',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleField(
                              label: 'Role Saat Ini',
                              value: _getRoleLabel(currentRole),
                              icon: Icons.person_outline,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child: Icon(Icons.arrow_forward, color: Colors.grey),
                          ),
                          Expanded(
                            child: _RoleField(
                              label: 'Role Target',
                              value: _getRoleLabel(targetRole),
                              icon: Icons.swap_horiz,
                              highlight: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Alasan / Keterangan',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          hintText: 'Contoh: Harus mengantar barang ke luar kota/radius...',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Alasan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _submitRequest(currentRole),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005494),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text('Kirim Pengajuan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),

          // Title History
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Riwayat Pengajuan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
            ),
          ),

          // History List
          Expanded(
            child: service.isLoading
                ? const Center(child: CircularProgressIndicator())
                : service.requests.isEmpty
                    ? Center(
                        child: Text(
                          'Belum ada riwayat pengajuan',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: service.requests.length,
                        itemBuilder: (context, index) {
                          final req = service.requests[index];
                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('dd MMM yyyy, HH:mm').format(req.createdAt.toLocal()),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                      _StatusBadge(status: req.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(_getRoleLabel(req.fromRole), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                      const Icon(Icons.arrow_right_alt, color: Colors.grey, size: 18),
                                      Text(_getRoleLabel(req.toRole), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      req.reason,
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[750]),
                                    ),
                                  ),
                                  if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Catatan Admin:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      req.adminNotes!,
                                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _RoleField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const _RoleField({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
        border: Border.all(color: highlight ? Colors.blue.withOpacity(0.3) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 14, color: highlight ? Colors.blue : Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: highlight ? Colors.blue[800] : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final DriverRoleRequestStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
