import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'driver_role_request_screen.dart';
import 'password_change_request_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();

  bool _isSaving = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final p = auth.profile;
    _nameController.text = p?['full_name'] ?? '';
    _nikController.text = p?['employee_id'] ?? '';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final auth = Provider.of<AuthService>(context, listen: false);
    final err = await auth.updateProfile(
      fullName: _nameController.text.trim(),
      employeeId: _nikController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (err == null) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $err'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Lama', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (newPassCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru minimal 6 karakter'), backgroundColor: Colors.red),
                );
                return;
              }
              if (newPassCtrl.text != confirmCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi password tidak cocok'), backgroundColor: Colors.red),
                );
                return;
              }

              final auth = Provider.of<AuthService>(context, listen: false);
              final err = await auth.changePassword(newPassCtrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  err == null
                      ? const SnackBar(content: Text('Password berhasil diganti'), backgroundColor: Colors.green)
                      : SnackBar(content: Text('Gagal: $err'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final p = auth.profile;
    final email = auth.user?.email ?? '';
    final role = p?['role'] ?? '';
    final shiftType = p?['shift_type'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF005494),
                        child: Text(
                          (p?['full_name'] ?? '?').toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (!_isEditing) ...[
                        Text(p?['full_name'] ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(email, style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Chip(role.toString().replaceAll('_', ' ').toUpperCase(), Colors.blue),
                            if (shiftType.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _Chip(shiftType.toString().toUpperCase(), Colors.teal),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(icon: Icons.badge_outlined, label: 'NIK', value: p?['employee_id'] ?? '—'),
                        _InfoRow(icon: Icons.calendar_today, label: 'Bergabung', value: p?['created_at'] != null ? (p!['created_at'] as String).substring(0, 10) : '—'),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _isEditing = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005494),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nikController,
                          decoration: const InputDecoration(
                            labelText: 'NIK Karyawan',
                            prefixIcon: Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v!.isEmpty ? 'NIK tidak boleh kosong' : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005494),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isSaving
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Simpan'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(() => _isEditing = false),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Batal'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

             Card(
               elevation: 2,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               child: Column(
                 children: [
                   ListTile(
                     leading: const Icon(Icons.lock_reset, color: Colors.orange),
                     title: const Text('Ganti Password'),
                     trailing: const Icon(Icons.chevron_right),
                     onTap: _showChangePasswordDialog,
                   ),
                   if (role == 'driver_bebas' || role == 'driver_kantor') ...[
                     const Divider(height: 1),
                     ListTile(
                       leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                       title: const Text('Pengajuan Ganti Role'),
                       trailing: const Icon(Icons.chevron_right),
                       onTap: () {
                         Navigator.push(
                           context,
                           MaterialPageRoute(builder: (context) => const DriverRoleRequestScreen()),
                         );
                       },
                     ),
                   ],
                 ],
               ),
             ),

            const SizedBox(height: 16),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Statistik Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.receipt_long, label: 'Email Terverifikasi', value: auth.user?.emailConfirmedAt != null ? 'Ya' : 'Tidak'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => auth.signOut(),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }
}
