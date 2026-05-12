import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final String shiftType;
  const LoginScreen({super.key, required this.shiftType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();
  bool _obscurePassword = true;
  bool _isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await _biometricService.isFeatureEnabled();
    final isAvailable = await _biometricService.isBiometricAvailable();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = isEnabled && isAvailable;
      });
    }
  }

  void _handleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final error = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    } else {
      // Tanya user apakah mau aktifkan biometric jika belum aktif
      if (!_isBiometricEnabled) {
        _showBiometricDialog();
      } else {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final credentials = await _biometricService.getSavedCredentials();
    if (credentials['email'] == null || credentials['password'] == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada data login tersimpan untuk Biometric.')),
        );
      }
      return;
    }

    final authenticated = await _biometricService.authenticate();
    if (authenticated) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final error = await authService.signIn(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Biometric Login Gagal: $error'), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  void _showBiometricDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan Biometric?'),
        content: const Text('Apakah Anda ingin menggunakan Sidik Jari/Face ID untuk login selanjutnya?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _biometricService.saveCredentials(
                _emailController.text.trim(),
                _passwordController.text.trim(),
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Close Login Screen
              }
            },
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<AuthService>(context).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shiftType == 'shifting' ? 'Login Shifting' : 'Login Non-Shifting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Selamat Datang Kembali',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Silakan login untuk memulai absensi',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF005494),
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Login'),
                  ),
                ),
                if (_isBiometricEnabled) ...[
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: isLoading ? null : _handleBiometricLogin,
                    icon: const Icon(Icons.fingerprint, size: 40, color: Color(0xFF005494)),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: const Color(0xFF005494).withOpacity(0.1),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum punya akun?'),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrationScreen(shiftType: widget.shiftType),
                      ),
                    );
                  },
                  child: const Text('Daftar Sekarang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
