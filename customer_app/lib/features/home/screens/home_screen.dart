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
  String _searchQuery = '';
  List<dynamic> _activeBookings = [];
  List<dynamic> _upcomingBookings = [];
  bool _isLoading = true;
  bool _isOffline = false;

  // Premium details
  double _walletBalance = 0;
  int _loyaltyPoints = 0;
  Map<String, dynamic>? _activeAmcSummary;

  // Auto-rotating promo banner variables
  late PageController _pageController;
  late Timer _carouselTimer;
  int _carouselIndex = 0;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'MONSOON SHIELD',
      'subtitle': 'Zero wiring shorts. Get free waterproof casing upgrades.',
      'code': 'RAINSECURE',
      'color': Color(0xFFEFF6FF),
      'textColor': Color(0xFF1E3A8A),
    },
    {
      'title': 'FREE SITE SURVEY',
      'subtitle': 'Schedule layout assessment by senior network engineer.',
      'code': 'SURVEYFREE',
      'color': Color(0xFFFFF7ED),
      'textColor': Color(0xFFEA580C),
    },
    {
      'title': 'AMC SPECIAL DEALS',
      'subtitle': 'Protect office workstations starting from ₹1,499/year.',
      'code': 'AMCSHIELD',
      'color': Color(0xFFF0FDF4),
      'textColor': Color(0xFF15803D),
    },
    {
      'title': 'FESTIVE SURVEILLANCE',
      'subtitle': 'Get 15% discount on camera kits and smart lock installation.',
      'code': 'FESTIVE15',
      'color': Color(0xFFFDF2F8),
      'textColor': Color(0xFFBE185D),
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
        
        // Cache data for offline usage
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
    
    // Active trackable bookings (dispatched, in_progress, active)
    final active = bookings.where((b) {
      final s = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
      return s == 'dispatched' || s == 'in_progress' || s == 'active';
    }).toList();

    // Upcoming bookings (confirmed, assigned, travelling, arrived)
    final upcoming = bookings.where((b) {
      final s = (b['status'] ?? b['bookingStatus'] ?? '').toString().toLowerCase();
      return s == 'confirmed' || s == 'assigned' || s == 'travelling' || s == 'arrived';
    }).toList();

    // Identify active AMC plan
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
      _upcomingBookings = upcoming;
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
              const Icon(Icons.warning, color: Colors.redAccent, size: 24),
              const SizedBox(width: 10),
              Text('Emergency $type', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  // Book high priority mock
                  final res = await client.post('/api/v2/bookings/create', data: {
                    'serviceId': 'cctv-installation', // dummy configurable service id
                    'serviceName': 'Emergency $type Dispatch',
                    'bookingDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    'timeSlot': DateFormat('HH:mm').format(DateTime.now()),
                    'amount': 999,
                    'addressId': '65baaa7782193b21820b8293', // mock
                    'latitude': '12.9716',
                    'longitude': '77.5946',
                    'notes': 'EMERGENCY SLA DISPATCH REQUIRED',
                  });
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
        return Icons.videocam;
      case 'networking':
        return Icons.router;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.computer;
      case 'server':
        return Icons.dns;
      case 'home-automation':
        return Icons.home_repair_service;
      case 'cyber-security':
        return Icons.shield;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final name = user?['name'] ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const TechBesLogo(
          size: 32.0,
          fontSize: 16.0,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
          if (_isOffline)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: const Icon(Icons.cloud_off, color: Colors.orange),
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
                    // Premium Header & Personalized Greeting
                    Container(
                      decoration: AppTheme.heroGradient,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
                                  ),
                                  Text(
                                    '$name 👋',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimaryColor, letterSpacing: -0.5),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                                child: IconButton(
                                  icon: const Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 20),
                                  onPressed: () => context.push('/ai-assistant'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Wallet Balance & Loyalty Points Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 16),
                                          SizedBox(width: 6),
                                          Text('Wallet Balance', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${_walletBalance.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(width: 1.5, height: 35, color: AppTheme.borderColor),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.stars, color: AppTheme.secondaryColor, size: 16),
                                          SizedBox(width: 6),
                                          Text('Loyalty Points', style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondaryColor)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$_loyaltyPoints pts',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textPrimaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    // Active live tracking shortcut
                    if (_activeBookings.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEFF6FF), Colors.white],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100, width: 1.5),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.motorcycle, color: Colors.blue),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Technician is En Route', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                    const SizedBox(height: 2),
                                    Text('Booking: #${_activeBookings[0]['bookingNumber'] ?? _activeBookings[0]['_id']?.toString().substring(0, 6).toUpperCase()}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => context.push('/tracking/${_activeBookings[0]['_id']}'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text('Track Live', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Promotional banner carousel (offers, discounts)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SPECIAL DEALS & PROMOS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 115,
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (idx) => setState(() => _carouselIndex = idx),
                              itemCount: _promoBanners.length,
                              itemBuilder: (context, idx) {
                                final p = _promoBanners[idx];
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: p['color'],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(p['title'], style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: p['textColor'])),
                                            const SizedBox(height: 3),
                                            Text(p['subtitle'], style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.35), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                        child: Text(p['code'], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: p['textColor'])),
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
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: _carouselIndex == idx ? AppTheme.primaryColor : Colors.blueGrey.shade100,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    // Quick features shortcuts grid
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('QUICK MODULE ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildShortcutButton(Icons.verified_user, 'AMC Plans', () => context.push('/amc')),
                              _buildShortcutButton(Icons.bar_chart, 'Analytics', () => context.push('/analytics')),
                              _buildShortcutButton(Icons.history, 'Timeline', () => context.push('/timeline')),
                              _buildShortcutButton(Icons.receipt_long, 'Invoices', () => context.push('/invoice-center')),
                              _buildShortcutButton(Icons.card_giftcard, 'Rewards', () => context.push('/referral')),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Emergency Dispatch banner
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200, width: 1.2),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'EMERGENCY SERVICE DESK',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5, color: Colors.red.shade700, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Immediate SLA response and dispatch for critical security or device network failures.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _triggerEmergencyBooking('CCTV Repair'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, padding: const EdgeInsets.symmetric(vertical: 10)),
                                    child: const Text('Emergency CCTV', style: TextStyle(fontSize: 12, color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _triggerEmergencyBooking('Network Audit'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red.shade700,
                                      side: BorderSide(color: Colors.red.shade300),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text('Emergency Network', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),

                    // Active AMC summary card
                    if (_activeAmcSummary != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ACTIVE AMC SHIELD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                            const SizedBox(height: 10),
                            Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.shade50,
                                  child: Icon(Icons.verified_user, color: Colors.green.shade700, size: 20),
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
                      ),
                    ],

                    // Explore Categories
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPLORE CORE CATEGORIES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 85,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ServiceRepository.categories.length,
                              itemBuilder: (context, index) {
                                final cat = ServiceRepository.categories[index];
                                return InkWell(
                                  onTap: () {
                                    ref.read(selectedCategoryProvider.notifier).state = cat.id;
                                    ref.read(navigationIndexProvider.notifier).state = 1;
                                  },
                                  child: Container(
                                    width: 80,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_getCategoryIcon(cat.id), color: AppTheme.primaryColor, size: 24),
                                        const SizedBox(height: 6),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                          child: Text(
                                            cat.title,
                                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Popular Services Section
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('RECOMMENDED SERVICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: ServiceRepository.services.take(3).length,
                            separatorBuilder: (context, idx) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final service = ServiceRepository.services[index];
                              return _buildServiceCardItem(service);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShortcutButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.06),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCardItem(MarketplaceService service) {
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
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, _, __) => Container(
                    height: 140,
                    color: const Color(0xFFF1F5F9),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, size: 40, color: AppTheme.textSecondaryColor),
                  ),
                ),
                if (service.badge != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
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
              padding: const EdgeInsets.all(14.0),
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
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
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
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    service.tagline,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        service.price,
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Configure',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
}
