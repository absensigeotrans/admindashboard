import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/password_change_request_service.dart';

class PasswordChangeRequestScreen extends StatefulWidget {
  const PasswordChangeRequestScreen({super.key});

  @override
  State<PasswordChangeRequestScreen> createState() => _PasswordChangeRequestScreenState();
}

class _PasswordChangeRequestScreenState extends State<PasswordChangeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _isObscurePassword = true;
  bool _isObscureConfirm = true;
  bool _isSubmitting = false;

  // Track which history items have their password visible
  final Map<String, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PasswordChangeRequestService>(context, listen: false).fetchRequests();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final service = Provider.of<PasswordChangeRequestService>(context, listen: false);
    final success = await service.submitRequest(
      newPassword: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _passwordController.clear();
        _confirmController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan ganti password berhasil dikirim'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim pengajuan: ${service.error}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<PasswordChangeRequestService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan Ganti Password', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Form Request Card
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
                        'Ajukan Password Baru',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Password baru Anda tidak akan aktif sampai disetujui oleh Admin.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isObscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password Baru',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isObscurePassword = !_isObscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password baru wajib diisi';
                          }
                          if (value.length < 8) {
                            return 'Password baru minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _isObscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Konfirmasi Password Baru',
                          prefixIcon: const Icon(Icons.lock_reset),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          suffixIcon: IconButton(
                            icon: Icon(_isObscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _isObscureConfirm = !_isObscureConfirm),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRequest,
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
                'Riwayat Pengajuan Ganti Password',
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
                          'Belum ada riwayat pengajuan ganti password',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: service.requests.length,
                        itemBuilder: (context, index) {
                          final req = service.requests[index];
                          final isPassVisible = _visiblePasswords[req.id] ?? false;

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
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.key, color: Colors.grey, size: 18),
                                      const SizedBox(width: 8),
                                      const Text('Password Baru: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                      Expanded(
                                        child: Text(
                                          isPassVisible ? req.newPassword : '••••••••',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(isPassVisible ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.grey[600]),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () {
                                          setState(() {
                                            _visiblePasswords[req.id] = !isPassVisible;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  if (req.adminNotes != null && req.adminNotes!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50]?.withOpacity(0.5) ?? Colors.grey[100],
                                        border: Border.all(color: Colors.red[100] ?? Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Catatan Admin:',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            req.adminNotes!,
                                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                                          ),
                                        ],
                                      ),
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

class _StatusBadge extends StatelessWidget {
  final PasswordChangeRequestStatus status;
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
