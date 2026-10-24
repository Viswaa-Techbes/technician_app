import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  String? _errorMessage;
  List<dynamic> _notifications = [];

  // Search & Filter State
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Bookings',
    'Quotations',
    'Payments',
    'AMC',
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
      _errorMessage = null;
    });

    final cacheService = ref.read(offlineCacheProvider);

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/notifications');
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _notifications = list;
            _isLoading = false;
          });
        }
        await cacheService.cacheNotifications(list);
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      final cached = await cacheService.getCachedNotifications();
      if (mounted) {
        if (cached != null && cached.isNotEmpty) {
          setState(() {
            _notifications = cached;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = e.toString().replaceAll('Exception: ', '');
            _notifications = [];
          });
        }
      }
    }
  }

  Future<void> _markAsRead(dynamic notification) async {
    final notifId = notification['_id']?.toString();
    if (notifId == null || notification['isRead'] == true) return;

    // Optimistically mark as read
    setState(() {
      notification['isRead'] = true;
    });

    try {
      final client = ref.read(dioClientProvider);
      await client.patch('/api/v2/notifications/$notifId/read');
    } catch (e) {
      debugPrint('Failed to mark notification read on backend: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    if (_notifications.isEmpty) return;

    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });

    try {
      final client = ref.read(dioClientProvider);
      await client.patch('/api/v2/notifications/read-all');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
    }
  }

  void _handleNotificationTap(dynamic n) async {
    await _markAsRead(n);

    if (!mounted) return;

    final title = (n['title'] ?? '').toString().toLowerCase();
    final message = (n['message'] ?? '').toString().toLowerCase();
    final type = (n['type'] ?? '').toString().toLowerCase();
    final bookingId = n['bookingId']?.toString();

    // 1. Booking related
    if (bookingId != null && bookingId.isNotEmpty) {
      context.push('/tracking/$bookingId');
      return;
    }
    if (type.contains('booking') || title.contains('booking') || title.contains('technician') || message.contains('booking') || message.contains('tb-')) {
      context.push('/dashboard');
      return;
    }

    // 2. Quotation related
    if (type.contains('quote') || title.contains('quote') || title.contains('quotation') || message.contains('quote') || message.contains('quotation')) {
      context.push('/my-quotes');
      return;
    }

    // 3. Payment or Invoice related
    if (type.contains('pay') || type.contains('invoice') || title.contains('payment') || title.contains('invoice') || message.contains('payment')) {
      context.push('/invoice-center');
      return;
    }

    // 4. AMC related
    if (type.contains('amc') || title.contains('amc') || message.contains('amc') || message.contains('maintenance contract')) {
      context.push('/amc');
      return;
    }

    // 5. Default: Show Rich Notification Details Sheet
    _showNotificationDetailsModal(n);
  }

  void _showNotificationDetailsModal(dynamic n) {
    final title = n['title'] ?? 'Notification';
    final message = n['message'] ?? '';
    final type = n['type'] ?? 'General';
    final date = DateTime.tryParse(n['createdAt'] ?? '') ?? DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy • h:mm a').format(date);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type.toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: _getNotificationColor(type),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 6),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor),
              ),
              const Divider(height: 24),
              Text(
                message,
                style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Dismiss'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/my-quotes');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('View Quotations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
      case 'bookings':
        return Icons.calendar_month;
      case 'quote':
      case 'quotation':
      case 'quotes':
        return Icons.request_quote_outlined;
      case 'offer':
      case 'offers':
        return Icons.local_offer_outlined;
      case 'payment':
      case 'payments':
        return Icons.receipt_long;
      case 'amc':
        return Icons.verified_user_outlined;
      case 'support':
        return Icons.support_agent;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'booking':
      case 'bookings':
        return const Color(0xFF2563EB); // Blue
      case 'quote':
      case 'quotation':
      case 'quotes':
        return const Color(0xFF0284C7); // Sky
      case 'payment':
      case 'payments':
        return const Color(0xFF16A34A); // Green
      case 'amc':
        return const Color(0xFF7C3AED); // Purple
      case 'offer':
      case 'offers':
        return const Color(0xFFEA580C); // Orange
      case 'support':
        return const Color(0xFF0891B2); // Cyan
      default:
        return AppTheme.primaryColor;
    }
  }

  List<dynamic> _getFilteredNotifications() {
    return _notifications.filter((n) {
      final title = (n['title'] ?? '').toString().toLowerCase();
      final message = (n['message'] ?? '').toString().toLowerCase();
      final type = (n['type'] ?? '').toString().toLowerCase();

      // Search match
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !message.contains(query) && !type.contains(query)) {
          return false;
        }
      }

      // Category match
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Bookings') {
        return type.contains('booking') || title.contains('booking') || message.contains('booking');
      }
      if (_selectedCategory == 'Quotations') {
        return type.contains('quote') || title.contains('quote') || message.contains('quote');
      }
      if (_selectedCategory == 'Payments') {
        return type.contains('pay') || title.contains('payment') || message.contains('payment') || title.contains('invoice');
      }
      if (_selectedCategory == 'AMC') {
        return type.contains('amc') || title.contains('amc') || message.contains('amc');
      }
      if (_selectedCategory == 'General') {
        return type.contains('general') || type.contains('system') || type.contains('alert');
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredNotifications();
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all, size: 16, color: AppTheme.primaryColor),
              label: const Text(
                'Mark All Read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search in alerts, bookings, quotes...',
                hintStyle: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondaryColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Category Chips Filter
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final active = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: active,
                    onSelected: (val) {
                      setState(() => _selectedCategory = cat);
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
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
                : _errorMessage != null && _notifications.isEmpty
                    ? _buildErrorState()
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
                                final typeColor = _getNotificationColor(n['type']);

                                return InkWell(
                                  onTap: () => _handleNotificationTap(n),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isRead ? Colors.transparent : AppTheme.primaryColor.withValues(alpha: 0.03),
                                      border: const Border(bottom: BorderSide(color: AppTheme.borderColor)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: typeColor.withValues(alpha: 0.12),
                                            child: Icon(
                                              _getNotificationIcon(n['type']),
                                              color: typeColor,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        n['title'] ?? 'Notification',
                                                        style: TextStyle(
                                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                          fontSize: 13,
                                                          color: AppTheme.textPrimaryColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      dateStr,
                                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  n['message'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                                                    height: 1.35,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isRead) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_outlined, size: 40, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              'You\'re all caught up!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? 'No notifications match your current search or filter.'
                  : 'When you submit quotation requests or schedule services, real-time updates will appear here.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Check for Updates'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, size: 40, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Couldn\'t Load Notifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Unable to connect to the notification service.',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _fetchNotifications,
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              label: const Text('Try Again', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _IterableFilter<E> on Iterable<E> {
  Iterable<E> filter(bool Function(E element) test) => where(test);
}
