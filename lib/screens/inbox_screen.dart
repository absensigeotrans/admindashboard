import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/inbox_service.dart';
import '../models/user_notification.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh notifications when opening screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<InboxService>(context, listen: false).fetchNotifications();
    });
  }

  String _formatDateTime(DateTime dt) {
    // Return a readable date time string, e.g. "13-06-2026 21:30"
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day-$month-$year $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final inboxService = Provider.of<InboxService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesan & Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (inboxService.unreadCount > 0)
            TextButton.icon(
              onPressed: () => inboxService.markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18),
              label: const Text('Tandai Semua Dibaca', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: inboxService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : inboxService.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline,
                        size: 72,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kotak Masuk Kosong',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada update pesan atau notifikasi baru.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => inboxService.fetchNotifications(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: inboxService.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = inboxService.notifications[index];
                      return Card(
                        elevation: notif.isRead ? 0.5 : 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        color: notif.isRead ? Colors.white : Colors.blue[50],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: notif.isRead
                                ? Colors.grey[200]!
                                : Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: notif.isRead
                                ? Colors.grey[100]
                                : Colors.blue[100],
                            child: Icon(
                              notif.title.contains('Disetujui') || notif.title.contains('✅')
                                  ? Icons.check_circle_outline
                                  : notif.title.contains('Ditolak') || notif.title.contains('❌')
                                      ? Icons.cancel_outlined
                                      : Icons.notifications_none,
                              color: notif.title.contains('Disetujui') || notif.title.contains('✅')
                                  ? Colors.green
                                  : notif.title.contains('Ditolak') || notif.title.contains('❌')
                                      ? Colors.red
                                      : Colors.blue,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontWeight: notif.isRead
                                        ? FontWeight.w600
                                        : FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                notif.message,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatDateTime(notif.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            if (!notif.isRead) {
                              inboxService.markAsRead(notif.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
