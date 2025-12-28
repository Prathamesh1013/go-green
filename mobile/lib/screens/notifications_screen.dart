import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {'id': '1', 'type': 'assignment', 'title': 'New Vehicle Assigned', 'message': 'KA-01-AB-1234 assigned for Oil Change', 'timestamp': '2 hours ago', 'isRead': false},
      {'id': '2', 'type': 'update', 'title': 'Service Status Updated', 'message': 'MH-02-CD-5678 marked as In Progress', 'timestamp': '5 hours ago', 'isRead': false},
      {'id': '3', 'type': 'message', 'title': 'Message from Customer', 'message': 'Rajesh Kumar sent a message', 'timestamp': '1 day ago', 'isRead': true},
    ];

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity, padding: const EdgeInsets.fromLTRB(24, 64, 24, 24), color: AppTheme.primaryBlue,
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Notifications', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Stay updated with your tasks', style: TextStyle(fontSize: 14, color: Color(0xFFDBEAFE))),
            ]),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16), itemCount: notifications.length,
              separatorBuilder: (c, i) => const SizedBox(height: 12),
              itemBuilder: (c, i) => _NotificationCard(n: notifications[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> n;
  const _NotificationCard({required this.n});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: n['isRead'] ? Colors.white : const Color(0xFFEFF6FF),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Icon(LucideIcons.bell, color: AppTheme.primaryBlue)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(n['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(n['message'], style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
          ])),
        ]),
      ),
    );
  }
}
