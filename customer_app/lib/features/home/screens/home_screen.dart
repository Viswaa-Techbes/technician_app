import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/techbes_logo.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/service_model.dart';
import '../../../repositories/service_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/screens/main_navigation_screen.dart';
import '../../../services/offline_cache_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  List<dynamic> _activeBookings = [];
  bool _isLoading = true;
  bool _isOffline = false;

  // Account details
  double _walletBalance = 0;
  int _loyaltyPoints = 0;
  Map<String, dynamic>? _activeAmcSummary;

  // Auto-rotating promo carousel
  late PageController _pageController;
  late Timer _carouselTimer;
  int _carouselIndex = 0;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'FREE SITE SURVEY',
      'subtitle': 'Schedule layout assessment & cabling audit by a senior engineer.',
      'code': 'SURVEYFREE',
      'bgGradient': [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
      'accent': Color(0xFFEA580C),
      'icon': Icons.location_searching_rounded,
    },
    {
      'title': 'MONSOON SHIELD',
      'subtitle': 'Zero wiring shorts. Get free waterproof casing upgrades.',
      'code': 'RAINSECURE',
      'bgGradient': [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
      'accent': Color(0xFF0284C7),
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'AMC IT PROTECTION',
      'subtitle': 'Protect office workstations starting from ₹1,499/year.',
      'code': 'AMCSHIELD',
      'bgGradient': [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
      'accent': Color(0xFF16A34A),
      'icon': Icons.verified_user_outlined,
    },
    {
      'title': 'FESTIVE SURVEILLANCE',
      'subtitle': 'Special discount on HD camera kits and smart lock installation.',
      'code': 'FESTIVE15',
      'bgGradient': [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
      'accent': Color(0xFFDB2777),
      'icon': Icons.videocam_outlined,
    }
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startCarouselTimer();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _carouselTimer.cancel();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        setState(() {
          _carouselIndex = (_carouselIndex + 1) % _promoBanners.length;
        });
        _pageController.animateToPage(
          _carouselIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final cacheService = ref.read(offlineCacheProvider);

    try {
      final client = ref.read(dioClientProvider);

      // Fetch user dashboard
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final raw = response.data['data'];
        await cacheService.cacheDashboard(raw);
        _parseDashboardPayload(raw);
        setState(() {
          _isOffline = false;
        });
      } else {
        throw Exception('Server returned success=false');
      }

      // Fetch wallet balance
      try {
        final walletRes = await client.get('/api/v2/customer/wallet');
        if (walletRes.data != null && walletRes.data['success'] == true) {
          final walletData = walletRes.data['data']['wallet'];
          setState(() {
            _walletBalance = ((walletData['balance'] ?? 0) as num).toDouble();
            _loyaltyPoints = (walletData['loyaltyPoints'] ?? 0).toInt();
          });
        }
      } catch (e) {
        debugPrint('Wallet fetch error: $e');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('HomeScreen API Error, loading from offline cache: $e');
      final cached = await cacheService.getCachedDashboard();
      if (cached != null) {
        _parseDashboardPayload(cached);
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isOffline = true;
          _isLoading = false;
        });
      }
    }
  }

  void _parseDashboardPayload(Map<String, dynamic> raw) {
    final bookings = raw['bookings'] as List<dynamic>? ?? [];

    final active = bookings.where((b) {
      final s = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
      return s == 'dispatched' || s == 'in_progress' || s == 'active';
    }).toList();

    dynamic amcPlan;
    for (var b in bookings) {
      final title = (b['serviceName'] ?? b['title'] ?? '').toString().toLowerCase();
      if (title.contains('amc') || title.contains('annual maintenance')) {
        amcPlan = {
          'id': b['_id'],
          'title': b['serviceName'] ?? b['title'],
          'expiry': '285 days remaining',
        };
        break;
      }
    }

    setState(() {
      _activeBookings = active;
      _activeAmcSummary = amcPlan;
    });
  }

  void _triggerEmergencyBooking(String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Emergency $type', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
          content: Text(
            'Raises a high-priority dispatch request for critical $type failures. SLA response time is 1-hour. Standard emergency call-out fee is ₹999.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  final client = ref.read(dioClientProvider);
                  String? addressId;
                  try {
                    final addrRes = await client.get('/api/v2/user/addresses');
                    if (addrRes.data != null && addrRes.data['data'] != null) {
                      final addrs = addrRes.data['data'] as List<dynamic>;
                      if (addrs.isNotEmpty) {
                        addressId = addrs[0]['_id']?.toString() ?? addrs[0]['id']?.toString();
                      }
                    }
                  } catch (_) {}

                  final payload = {
                    'serviceId': 'cctv-installation',
                    'serviceName': 'Emergency $type Dispatch',
                    'bookingDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'timeSlot': DateFormat('HH:mm').format(DateTime.now()),
                    'amount': 999,
                    'latitude': '12.9716',
                    'longitude': '77.5946',
                    'notes': 'EMERGENCY SLA DISPATCH REQUIRED: $type issue',
                  };
                  if (addressId != null && addressId.isNotEmpty) {
                    payload['addressId'] = addressId;
                  }

                  final res = await client.post('/api/v2/bookings/create', data: payload);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Emergency technician dispatched! Check bookings to track live.')),
                    );
                    _loadDashboardData();
                  } else {
                    throw Exception();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to book emergency online. Connecting directly to Hotline...')),
                  );
                }
                setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('Confirm Dispatch', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String id) {
    switch (id.toLowerCase()) {
      case 'cctv':
        return Icons.videocam_rounded;
      case 'networking':
        return Icons.router_rounded;
      case 'website-development':
      case 'web-designing':
        return Icons.language_rounded;
      case 'digital-marketing':
        return Icons.campaign_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getCategoryColor(String id) {
    switch (id.toLowerCase()) {
      case 'cctv':
        return const Color(0xFF0284C7); // Sky / Techbes Blue
      case 'networking':
        return const Color(0xFF059669); // Emerald Green
      case 'website-development':
        return const Color(0xFF4F46E5); // Indigo
      case 'digital-marketing':
        return const Color(0xFFEA580C); // Techbes Orange
      default:
        return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final name = user?['name'] ?? 'Valued Customer';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const TechBesLogo(
          size: 32.0,
          fontSize: 17.0,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppTheme.textPrimaryColor),
            tooltip: 'Search Services',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimaryColor),
            tooltip: 'Cart',
            onPressed: () => context.push('/cart'),
          ),
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Tooltip(
                message: 'Offline mode active',
                child: Icon(Icons.cloud_off_rounded, color: Colors.orange, size: 20),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modern Hero Banner matching Main Site
                    _buildHeroSection(context),

                    // Personalized Welcome & Quick Wallet Strip
                    _buildAccountStrip(name, context),

                    // Active Live Tracking Banner (if any)
                    if (_activeBookings.isNotEmpty) _buildActiveTrackingBanner(context),

                    // Quick Module Shortcuts
                    _buildQuickShortcuts(context),

                    // Society Resident Portal Banner
                    _buildApartmentResidentBanner(context),

                    // Verified 4 Core Service Divisions (2x2 Grid)
                    _buildCoreCategoriesSection(context),

                    // Special Deals & Offers Carousel
                    _buildDealsCarousel(),

                    // Featured Canonical Services
                    _buildFeaturedServicesSection(context),

                    // Active AMC Summary Card (if active)
                    if (_activeAmcSummary != null) _buildAmcSummaryCard(context),

                    // Emergency SLA Dispatch Desk
                    _buildEmergencyDesk(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // Hero Section matching TechBes Main Site
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEA580C).withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFFFB923C), size: 13),
                SizedBox(width: 5),
                Text(
                  'BANGALORE’S TRUSTED IT & SECURITY PARTNER',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFED7AA),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Smart CCTV, Networking &\nDigital IT Solutions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Certified technicians, transparent quotation pricing, and SLA-backed maintenance for homes and offices.',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.blue.shade100,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/quotation'),
                  icon: const Icon(Icons.request_quote_rounded, size: 16),
                  label: const Text(
                    'Request Free Quote',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(navigationIndexProvider.notifier).state = 1;
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Explore Services',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Account Strip (Welcome, Wallet, AI Support)
  Widget _buildAccountStrip(String name, BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$name 👋',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              IconButton(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                  child: const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                tooltip: 'TechBes Support Assistant',
                onPressed: () => context.push('/ai-assistant'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/wallet'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.account_balance_wallet_rounded, size: 14, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wallet Balance', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                            Text('₹${_walletBalance.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 26, color: AppTheme.borderColor),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push('/referral'),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFEA580C).withOpacity(0.1),
                          child: const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFEA580C)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Loyalty Points', style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
                            Text('$_loyaltyPoints pts', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Active Live Tracking Banner
  Widget _buildActiveTrackingBanner(BuildContext context) {
    final booking = _activeBookings[0];
    final bookingId = booking['bookingNumber'] ?? booking['_id']?.toString().substring(0, 6).toUpperCase() ?? 'ACTIVE';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.motorcycle_rounded, color: Color(0xFF1E3A8A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Technician En Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A))),
                Text('Booking #$bookingId', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/tracking/${booking['_id']}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Track Live', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Quick Module Shortcuts
  Widget _buildQuickShortcuts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildShortcutItem(Icons.request_quote_outlined, 'My Quotes', () => context.push('/my-quotes')),
          _buildShortcutItem(Icons.calendar_today_outlined, 'Bookings', () => ref.read(navigationIndexProvider.notifier).state = 2),
          _buildShortcutItem(Icons.verified_user_outlined, 'AMC Plans', () => context.push('/amc')),
          _buildShortcutItem(Icons.receipt_long_outlined, 'Invoices', () => context.push('/invoice-center')),
          _buildShortcutItem(Icons.support_agent_outlined, 'Support', () => context.push('/ai-assistant')),
        ],
      ),
    );
  }

  Widget _buildApartmentResidentBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/apartment'),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Society Resident Portal',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COMPLAINTS',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Report flat maintenance issues, attach photos, and communicate directly with apartment in-charge.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
      ),
    );
  }

  // The 4 Verified Main Categories (2x2 Grid)
  Widget _buildCoreCategoriesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OUR 4 CORE DIVISIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textSecondaryColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Official TechBes Service Catalogue',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
                child: const Row(
                  children: [
                    Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    Icon(Icons.chevron_right, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ServiceRepository.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, idx) {
              final cat = ServiceRepository.categories[idx];
              final color = _getCategoryColor(cat.id);
              final icon = _getCategoryIcon(cat.id);

              return InkWell(
                onTap: () {
                  ref.read(selectedCategoryProvider.notifier).state = cat.id;
                  ref.read(navigationIndexProvider.notifier).state = 1;
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 22),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              cat.servicesLabel,
                              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.description,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor, height: 1.25),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Explore',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 12, color: color),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Promotional Banner Carousel
  Widget _buildDealsCarousel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SPECIAL PROMOTIONS & DEALS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _carouselIndex = idx),
              itemCount: _promoBanners.length,
              itemBuilder: (context, idx) {
                final p = _promoBanners[idx];
                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: p['bgGradient'] as List<Color>,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (p['accent'] as Color).withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4),
                          ],
                        ),
                        child: Icon(p['icon'] as IconData, color: p['accent'] as Color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              p['title'] as String,
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: p['accent'] as Color),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['subtitle'] as String,
                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondaryColor, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: (p['accent'] as Color).withOpacity(0.3)),
                        ),
                        child: Text(
                          p['code'] as String,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: p['accent'] as Color),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_promoBanners.length, (idx) {
              return Container(
                width: _carouselIndex == idx ? 16 : 6,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                decoration: BoxDecoration(
                  color: _carouselIndex == idx ? AppTheme.primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // Featured Canonical Services
  Widget _buildFeaturedServicesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FEATURED SERVICES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Popular Customer Choices',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => ref.read(navigationIndexProvider.notifier).state = 1,
                child: const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ServiceRepository.services.take(3).length,
            separatorBuilder: (context, idx) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final service = ServiceRepository.services[index];
              return _buildServiceCardItem(service);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCardItem(MarketplaceService service) {
    final hasRating = service.rating > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/services/${service.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                Image.network(
                  service.image,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 130,
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, size: 36, color: AppTheme.textSecondaryColor),
                  ),
                ),
                if (service.badge != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.badge!,
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.category.toUpperCase(),
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 0.5),
                      ),
                      if (hasRating)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${service.rating} (${service.reviewCount})',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.tagline,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.price,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor),
                      ),
                      ElevatedButton(
                        onPressed: () => context.push('/services/${service.slug}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('View & Quote', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active AMC Summary Card
  Widget _buildAmcSummaryCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ACTIVE AMC SHIELD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade50,
                child: Icon(Icons.verified_user_rounded, color: Colors.green.shade700, size: 20),
              ),
              title: Text(_activeAmcSummary!['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Coverage: ${_activeAmcSummary!['expiry']}', style: const TextStyle(fontSize: 11)),
              trailing: TextButton(
                onPressed: () => context.push('/amc'),
                child: const Text('Manage', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Emergency Service Desk
  Widget _buildEmergencyDesk() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                const SizedBox(width: 6),
                Text(
                  'EMERGENCY SERVICE DESK',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.red.shade700, letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '1-Hour SLA emergency response and on-site dispatch for critical security or device network outages.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _triggerEmergencyBooking('CCTV Outage'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Emergency CCTV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _triggerEmergencyBooking('Network Failure'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Emergency Network', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
