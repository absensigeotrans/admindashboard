import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/password_change_request_service.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? shiftType;
  const LoginScreen({super.key, this.shiftType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/bg-login.png',
                fit: BoxFit.cover,
              ),
            ),
            // Blue Overlay (like web)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF03045E),
                      Color(0xFF0077B6),
                      Color(0xFF00B4D8),
                    ],
                  ),
                ),
              ),
            ),
            // Content
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: const Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: LoginForm(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

   Future<void> _handleLogin() async {
     setState(() {
       _isLoading = true;
       _errorMessage = null;
     });
     final authService = Provider.of<AuthService>(context, listen: false);
     final error = await authService.signIn(
       email: _emailController.text.trim(),
       password: _passwordController.text.trim(),
     );
     if (!mounted) return;
     setState(() {
       _isLoading = false;
     });
     if (error != null) {
       setState(() {
         _errorMessage = error;
       });
     } else {
       // Navigate based on role
       if (!mounted) return;
       final profile = authService.profile;
       if (profile == null) return;
       if (!mounted) return;
       if (profile['role'] == 'admin') {
         Navigator.of(context).pushReplacementNamed('/admin');
       } else {
         Navigator.of(context).pushReplacementNamed('/');
       }
     }
   }

    void _showForgotPasswordDialog() {
      final emailCtrl = TextEditingController(text: _emailController.text.trim());
      final passwordCtrl = TextEditingController();
      final confirmCtrl = TextEditingController();
      bool obscurePassword = true;
      bool obscureConfirm = true;
      bool isDialogSubmitting = false;

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Pengajuan Lupa Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Masukkan email Anda dan masukkan password baru yang ingin diajukan ke Admin.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDialogSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isDialogSubmitting
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          final newPass = passwordCtrl.text;
                          final confirmPass = confirmCtrl.text;

                          if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Semua field wajib diisi!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          if (newPass.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password baru minimal 8 karakter!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          if (newPass != confirmPass) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Konfirmasi password tidak cocok!'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setState(() => isDialogSubmitting = true);

                          final reqService = Provider.of<PasswordChangeRequestService>(context, listen: false);
                          final success = await reqService.submitForgotPasswordRequest(
                            email: email,
                            newPassword: newPass,
                          );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (mounted) {
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pengajuan reset password berhasil dikirim ke Admin. Hubungi Admin untuk persetujuan.'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal: ${reqService.error}'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isDialogSubmitting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Ajukan'),
                ),
              ],
            );
          },
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        const SizedBox(height: 20),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/logo-ptk.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Form Card with Glassmorphism
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white.withOpacity(0.15),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selamat Datang Kembali',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Silakan login untuk memulai absensi',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Email field
                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      hintText: 'email@pertamina.com',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.white.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password field
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.7)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: Text(
                        'Lupa Password?',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'MASUK',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Register link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Belum punya akun?',
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegistrationScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_errorMessage != null && _errorMessage!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}