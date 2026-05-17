import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/admin_service.dart';
import 'services/sync_service.dart';
import 'services/database_helper.dart';
import 'services/leave_service.dart';
import 'services/notification_service.dart';
import 'services/office_service.dart';
import 'screens/shift_selection_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yoykktgggvvoigrbtvhq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlveWtrdGdnZ3Z2b2lncmJ0dmhxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg1NDc5MzUsImV4cCI6MjA5NDEyMzkzNX0.5Pj3uE4SXzLh_q8OTC_Ct91tR7Y0RBvXxZzaujVaQpI',
  );

  // Initialize local notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => AdminService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => LeaveService()),
        ChangeNotifierProvider(create: (_) => OfficeService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoAttend PTK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005494)), // PTK Blue
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.user == null) {
      return const ShiftSelectionScreen();
    }

    // Jika user sudah login tapi profile belum ke-load
    if (authService.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Cek status aktif (opsional, tergantung logic admin approve)
    if (authService.profile!['is_active'] == false) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Akun Menunggu Persetujuan',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Akun Anda sedang ditinjau oleh Admin. Silakan hubungi HRD jika ini memakan waktu lama.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => authService.signOut(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Redirect berdasarkan role
    final role = authService.profile!['role'] ?? '';
    if (role == 'admin') {
      return const AdminScreen();
    }
    return const DashboardScreen();
  }
}
