import 'package:flutter/material.dart';
import 'login_screen.dart';

class ShiftSelectionScreen extends StatelessWidget {
  const ShiftSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF005494), Color(0xFF002D50)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 80, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'GeoAttend PTK',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sistem Absensi Geofencing\nPertamina Trans Kontinental',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 60),
                const Text(
                  'Silakan Login atau Daftar',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                _buildShiftButton(
                  context,
                  title: 'Masuk',
                  subtitle: 'Sudah punya akun? Login di sini',
                  icon: Icons.login,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
                const SizedBox(height: 16),
                _buildShiftButton(
                  context,
                  title: 'Daftar',
                  subtitle: 'Belum punya akun? Registrasi di sini',
                  icon: Icons.person_add_alt,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF005494).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF005494)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF002D50),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
