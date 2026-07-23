import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/notifications');
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _notifications = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
        // Mock dynamic fallback notifications
        _notifications = [
          {
            '_id': 'n1',
            'title': 'Booking Confirmed!',
            'message': 'Your CCTV installation service is scheduled. Our partner will assign a technician soon.',
            'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
            'isRead': false,
            'type': 'booking'
          },
          {
            '_id': 'n2',
            'title': 'Flat 10% Off Offer',
            'message': 'Use promo code SECURE10 for CCTV products. Secure your home today!',
            'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'isRead': true,
            'type': 'offer'
          },
          {
            '_id': 'n3',
            'title': 'Invoice Ready',
            'message': 'Your digital receipt is generated and available for download in dashboard reports.',
            'createdAt': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'isRead': true,
            'type': 'payment'
          }
        ];
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final client = ref.read(dioClientProvider);
      await client.patch('/api/v2/notifications/read-all');
      _fetchNotifications();
    } catch (e) {
      debugPrint('Failed to mark read-all: $e');
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return Icons.calendar_month;
      case 'offer':
        return Icons.local_offer;
      case 'payment':
        return Icons.receipt_long;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
        return AppTheme.primaryColor;
      case 'offer':
        return AppTheme.secondaryColor;
      case 'payment':
        return Colors.blue;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['isRead'] == false))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined, size: 48, color: Colors.blueGrey.shade200),
                        const SizedBox(height: 16),
                        const Text(
                          'All caught up!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Transactional alerts and offers will appear here.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppTheme.primaryColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['isRead'] == true;
                      final date = DateTime.tryParse(n['createdAt'] ?? '') ?? DateTime.now();
                      final dateStr = DateFormat('d MMM, h:mm a').format(date);

                      return Container(
                        decoration: BoxDecoration(
                          color: isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.03),
                          border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: _getNotificationColor(n['type']).withOpacity(0.1),
                            child: Icon(
                              _getNotificationIcon(n['type']),
                              color: _getNotificationColor(n['type']),
                              size: 20,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                n['title'] ?? 'Update',
                                style: TextStyle(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              n['message'] ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                                height: 1.35,
                              ),
                            ),
                          ),
                          onTap: () async {
                            if (!isRead) {
                              try {
                                final client = ref.read(dioClientProvider);
                                await client.patch('/api/v2/notifications/${n['_id']}/read');
                                setState(() {
                                  n['isRead'] = true;
                                });
                              } catch (e) {
                                setState(() {
                                  n['isRead'] = true;
                                });
                              }
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
