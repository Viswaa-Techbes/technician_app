import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../services/offline_cache_service.dart';

class NotificationsTab extends ConsumerStatefulWidget {
  const NotificationsTab({super.key});

  @override
  ConsumerState<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends ConsumerState<NotificationsTab> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _notifications = [];
  
  // Search & Filter State
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Bookings',
    'Payments',
    'Offers',
    'AMC',
    'Support',
    'General',
  ];

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

    final cacheService = ref.read(offlineCacheProvider);

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/notifications');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
        await cacheService.cacheNotifications(list);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error loading notifications, checking cache: $e');
      final cached = await cacheService.getCachedNotifications();
      if (cached != null) {
        setState(() {
          _notifications = cached;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          // Fallback mock notifications for demonstration
          _notifications = [
            {
              '_id': 'n_mock_1',
              'title': 'Technician Assigned',
              'message': 'Your CCTV repair job TB-71289 has been assigned to Sanjay Sharma.',
              'createdAt': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
              'isRead': false,
              'type': 'bookings'
            },
            {
              '_id': 'n_mock_2',
              'title': 'Advance Payment Received',
              'message': 'Advance booking payment of ₹1.00 verified successfully.',
              'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
              'isRead': false,
              'type': 'payments'
            },
            {
              '_id': 'n_mock_3',
              'title': 'Seasonal Discount 10%',
              'message': 'Get 10% off on all network routers and switches using code NETSHIELD.',
              'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              'isRead': true,
              'type': 'offers'
            },
            {
              '_id': 'n_mock_4',
              'title': 'AMC Contract Signed',
              'message': 'Your Premium CCTV AMC plan is active. 4 preventive visits scheduled.',
              'createdAt': DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
              'isRead': true,
              'type': 'amc'
            },
            {
              '_id': 'n_mock_5',
              'title': 'AI Escalation Callback Raised',
              'message': 'A support ticket has been created for your assistant query.',
              'createdAt': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
              'isRead': true,
              'type': 'support'
            }
          ];
        });
      }
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
      case 'bookings':
        return Icons.calendar_month;
      case 'offer':
      case 'offers':
        return Icons.local_offer;
      case 'payment':
      case 'payments':
        return Icons.receipt_long;
      case 'amc':
        return Icons.verified_user;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
      case 'bookings':
        return AppTheme.primaryColor;
      case 'offer':
      case 'offers':
        return AppTheme.secondaryColor;
      case 'payment':
      case 'payments':
        return Colors.green;
      case 'amc':
        return Colors.teal;
      case 'support':
        return Colors.purple;
      default:
        return AppTheme.textSecondaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

    // Filter list by category and search
    final filtered = _notifications.where((n) {
      final matchesSearch = (n['title'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (n['message'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final type = (n['type'] ?? 'general').toString().toLowerCase();
      final cat = _selectedCategory.toLowerCase();

      final matchesCategory = cat == 'all' || 
          type == cat || 
          (cat == 'bookings' && type == 'booking') ||
          (cat == 'payments' && type == 'payment') ||
          (cat == 'offers' && type == 'offer');

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  '$unreadCount new',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            ]
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Field Panel
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search notification history...',
                  prefixIcon: Icon(Icons.search, size: 20, color: AppTheme.textSecondaryColor),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Horizontal scroll filter chips
          Container(
            height: 50,
            color: Colors.white,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final active = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 10),
                  child: FilterChip(
                    label: Text(cat),
                    selected: active,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.08),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.bold : FontWeight.w500,
                      color: active ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: active ? AppTheme.primaryColor : AppTheme.borderColor),
                    ),
                  ),
                );
              },
            ),
          ),

          // Notifications List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchNotifications,
                        color: AppTheme.primaryColor,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final n = filtered[index];
                            final isRead = n['isRead'] == true;
                            final date = DateTime.tryParse(n['createdAt'] ?? '') ?? DateTime.now();
                            final dateStr = DateFormat('d MMM, h:mm a').format(date);

                            return Container(
                              decoration: BoxDecoration(
                                color: isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.02),
                                border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _getNotificationColor(n['type']).withOpacity(0.08),
                                  child: Icon(
                                    _getNotificationIcon(n['type']),
                                    color: _getNotificationColor(n['type']),
                                    size: 18,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'] ?? 'Notification',
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(dateStr, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    n['message'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                trailing: !isRead
                                    ? Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                      )
                                    : null,
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 48, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text(
              'No matching alerts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'No new transactional alerts or promotions found under this group filter.',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
