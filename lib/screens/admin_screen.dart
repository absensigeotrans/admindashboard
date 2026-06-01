import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';
import 'admin_report_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminService>(context, listen: false).fetchAllUsers();
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
        title: const Text('Admin Panel',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF005494),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              final authService =
                  Provider.of<AuthService>(context, listen: false);
              authService.signOut();
            },
          ),
        ],
         bottom: TabBar(
           controller: _tabController,
           indicatorColor: Colors.white,
           labelColor: Colors.white,
           unselectedLabelColor: Colors.white70,
           tabs: [
             Tab(text: 'Pending'),
             Tab(text: 'Semua User'),
             Tab(text: 'Laporan'),
           ],
         ),
      ),
      body: Consumer<AdminService>(
        builder: (context, adminService, child) {
          if (adminService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${adminService.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => adminService.fetchAllUsers(),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

           return TabBarView(
             controller: _tabController,
             children: [
               // Tab Pending
               _UserListView(
                 users: adminService.pendingUsers,
                 emptyMessage: 'Tidak ada user menunggu persetujuan',
                 showApproveButton: true,
                 onApprove: (userId) async {
                   final success = await adminService.approveUser(userId);
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(
                           success
                               ? 'User berhasil diapprove'
                               : 'Gagal approve user',
                         ),
                         backgroundColor:
                             success ? Colors.green : Colors.red,
                       ),
                     );
                   }
                 },
               ),
               // Tab Semua User
               _UserListView(
                 users: adminService.allUsers,
                 emptyMessage: 'Belum ada user terdaftar',
                 showApproveButton: false,
                 onDeactivate: (userId) async {
                   final success = await adminService.deactivateUser(userId);
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text(
                           success
                               ? 'User berhasil dinonaktifkan'
                               : 'Gagal nonaktifkan user',
                         ),
                         backgroundColor:
                             success ? Colors.green : Colors.red,
                       ),
                     );
                   }
                 },
               ),
               // Tab Laporan
               const AdminReportScreen(),
             ],
           );
        },
      ),
    );
  }
}

class _UserListView extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String emptyMessage;
  final bool showApproveButton;
  final Function(String)? onApprove;
  final Function(String)? onDeactivate;

  const _UserListView({
    required this.users,
    required this.emptyMessage,
    required this.showApproveButton,
    this.onApprove,
    this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          Provider.of<AdminService>(context, listen: false).fetchAllUsers(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isActive = user['is_active'] == true;
          return _UserCard(
            user: user,
            isActive: isActive,
            showApproveButton: showApproveButton,
            onApprove: onApprove,
            onDeactivate: onDeactivate,
          );
        },
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isActive;
  final bool showApproveButton;
  final Function(String)? onApprove;
  final Function(String)? onDeactivate;

  const _UserCard({
    required this.user,
    required this.isActive,
    required this.showApproveButton,
    this.onApprove,
    this.onDeactivate,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
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
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF005494),
                  child: Text(
                    (user['full_name'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        user['employee_id'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green[800] : Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Info Row
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.badge,
                  label: user['role'] ?? '-',
                ),
                _InfoChip(
                  icon: Icons.schedule,
                  label: user['shift_type'] ?? '-',
                ),
                _InfoChip(
                  icon: Icons.email,
                  label: user['email'] ?? '-',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Terdaftar: ${_formatDate(user['created_at'])}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 12),

            // Action Button
            if (showApproveButton && !isActive)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onApprove != null
                      ? () => onApprove!(user['id'])
                      : null,
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Approve User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              )
            else if (!showApproveButton && isActive)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDeactivate != null
                      ? () => onDeactivate!(user['id'])
                      : null,
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Nonaktifkan'),
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
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
