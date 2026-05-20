import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String? shiftType;
  const RegistrationScreen({super.key, this.shiftType});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String _selectedRole = 'juru_parkir';
  final List<String> _roles = ['driver', 'juru_parkir', 'ob'];

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      fullName: _nameController.text.trim(),
      employeeId: _employeeIdController.text.trim(),
      role: _selectedRole,
      shiftType: widget.shiftType ?? '',
    );

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Menunggu persetujuan admin.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke login
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthService>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buat Profil Karyawan',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Daftarkan diri Anda untuk sistem GeoAttend PTK',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
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
                controller: _employeeIdController,
                decoration: const InputDecoration(
                  labelText: 'NIK Karyawan',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'NIK tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Peran / Jabatan',
                  prefixIcon: Icon(Icons.assignment_ind_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _roles.map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role.toUpperCase().replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email (@gmail.com)',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Email tidak boleh kosong';
                  if (!v.endsWith('@gmail.com')) return 'Harus menggunakan Gmail';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF005494),
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
