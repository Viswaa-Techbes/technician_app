import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> notifications = [
      {"title": "Job Completed", "body": "Chris Wong completed Job #103", "time": "2 min ago", "type": "success"},
      {"title": "Job Started", "body": "Alex Brown started service at Downtown", "time": "15 min ago", "type": "info"},
      {"title": "Pending Payment", "body": "Customer Smith has hasn't paid for Job #098", "time": "1 hour ago", "type": "warning"},
      {"title": "New Assignment", "body": "You assigned Bank West to Jamie Doe", "time": "2 hours ago", "type": "info"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("NOTIFICATIONS")),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        itemBuilder: (context, index) => _buildNotificationTile(notifications[index]),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, String> data) {
    Color color = const Color(0xFF2563EB);
    IconData icon = Icons.info_rounded;

    if (data['type'] == 'success') {
      color = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (data['type'] == 'warning') {
      color = const Color(0xFFF59E0B);
      icon = Icons.warning_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title']!, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(data['body']!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(data['time']!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
