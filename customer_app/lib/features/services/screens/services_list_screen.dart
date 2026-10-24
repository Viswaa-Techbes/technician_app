import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../../repositories/service_repository.dart';
import '../../dashboard/screens/main_navigation_screen.dart';
import '../components/service_config_modal.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  List<dynamic> _subcategories = [];
  bool _isLoadingSubcategories = false;
  String? _loadedCategorySlug;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeSlug = ref.read(selectedCategoryProvider);
      _fetchSubcategories(activeSlug);
    });
  }

  Future<void> _fetchSubcategories(String slug) async {
    setState(() {
      _isLoadingSubcategories = true;
      _loadedCategorySlug = slug;
      _subcategories = [];
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/catalog/categories/$slug/subcategories');
      if (response.data != null && response.data['success'] == true) {
        final List<dynamic> fetched = response.data['data'] ?? [];
        if (mounted && fetched.isNotEmpty) {
          setState(() {
            _subcategories = fetched;
            _isLoadingSubcategories = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading subcategories from API: $e');
    }

    // Use robust, curated fallbacks for each category
    if (mounted) {
      setState(() {
        _isLoadingSubcategories = false;
        _subcategories = _getFallbackSubcategories(slug);
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackSubcategories(String slug) {
    switch (slug.toLowerCase()) {
      case 'cctv':
        return [
          {
            '_id': '1000',
            'name': 'Install New CCTV',
            'slug': 'install-new-cctv',
            'description': 'Fresh CCTV camera installation for homes and offices with HD/IP options.',
            'startingPrice': '₹499',
          },
          {
            '_id': '1001',
            'name': 'Repair Existing CCTV',
            'slug': 'repair-existing-cctv',
            'description': 'Diagnose and repair video loss, DVR/NVR errors, and power supply faults.',
            'startingPrice': '₹499',
          },
          {
            '_id': '1002',
            'name': 'Maintenance (AMC)',
            'slug': 'maintenance-amc',
            'description': 'Annual Maintenance Contracts for continuous, uninterrupted security coverage.',
            'startingPrice': '₹999',
          },
          {
            '_id': '1003',
            'name': 'Upgrade Existing CCTV',
            'slug': 'upgrade-existing-cctv',
            'description': 'Expand camera coverage, upgrade to IP cameras, or increase storage capacities.',
            'startingPrice': '₹499',
          },
          {
            '_id': '1004',
            'name': 'Buy CCTV Products',
            'slug': 'buy-cctv-products',
            'description': 'Purchase individual security cameras, recorders, cables, or storage disks.',
            'startingPrice': '₹199',
          },
          {
            '_id': '1005',
            'name': 'Free Site Survey',
            'slug': 'free-site-survey',
            'description': 'Schedule a free on-site survey for custom security planning and estimation.',
            'startingPrice': 'Free',
          },
        ];

      case 'networking':
        return [
          {
            '_id': '2001',
            'name': 'New Office Network Setup',
            'slug': 'new-network-setup',
            'description': 'Full network setup with router, managed switch, and Wi-Fi mesh planning.',
            'startingPrice': '₹4,999',
          },
          {
            '_id': '2002',
            'name': 'Wi-Fi & Internet Speed Optimization',
            'slug': 'wifi-internet-issues',
            'description': 'Resolve dead zones, speed bottlenecks, and interference in offices and homes.',
            'startingPrice': '₹999',
          },
          {
            '_id': '2003',
            'name': 'Router, Switch & AP Setup',
            'slug': 'router-modem',
            'description': 'Configure Cisco, TP-Link, Ubiquiti, or MikroTik routers and access points.',
            'startingPrice': '₹1,499',
          },
          {
            '_id': '2004',
            'name': 'Structured Cat6 / Fiber Cabling',
            'slug': 'structured-cabling',
            'description': 'Neat patch panel termination, cable testing, wall jacks, and trunking.',
            'startingPrice': '₹1,999',
          },
          {
            '_id': '2005',
            'name': 'Network Security & Firewall',
            'slug': 'network-security',
            'description': 'Enterprise firewall installation, VLAN configuration, and guest Wi-Fi isolation.',
            'startingPrice': '₹5,999',
          },
          {
            '_id': '2006',
            'name': 'Server & NAS Storage Integration',
            'slug': 'server-storage',
            'description': 'Synology/QNAP NAS deployment, automatic data backup, and network shares.',
            'startingPrice': '₹3,499',
          },
          {
            '_id': '2007',
            'name': 'Network AMC',
            'slug': 'network-amc',
            'description': 'Priority corporate network maintenance, routine audits, and SLA uptime.',
            'startingPrice': '₹9,999/yr',
          },
          {
            '_id': '2008',
            'name': 'Free Network Site Audit',
            'slug': 'network-survey',
            'description': 'On-site assessment of cabling, Wi-Fi heatmaps, and infrastructure needs.',
            'startingPrice': 'Free',
          },
        ];

      case 'website-development':
        return [
          {
            '_id': '3001',
            'name': 'Business Website Design',
            'slug': 'business-website',
            'description': 'Custom, mobile-responsive corporate website with modern UI and CMS.',
            'startingPrice': '₹14,999',
          },
          {
            '_id': '3002',
            'name': 'High-Converting Landing Page',
            'slug': 'landing-page',
            'description': 'Optimized single-page sales funnel for lead generation and product campaigns.',
            'startingPrice': '₹6,999',
          },
          {
            '_id': '3003',
            'name': 'Ecommerce Website (Shopify/Woo)',
            'slug': 'ecommerce-website',
            'description': 'Complete online store with Razorpay payment gateway, inventory, and order tracking.',
            'startingPrice': '₹24,999',
          },
          {
            '_id': '3004',
            'name': 'Custom Web Application',
            'slug': 'web-app',
            'description': 'Tailored React/Next.js/Node.js web application for complex workflows.',
            'startingPrice': '₹39,999',
          },
          {
            '_id': '3005',
            'name': 'Website Redesign & Modernization',
            'slug': 'web-redesign',
            'description': 'Revamp outdated websites with state-of-the-art UI/UX and fast performance.',
            'startingPrice': '₹11,999',
          },
          {
            '_id': '3006',
            'name': 'SEO Optimization & Speed Boost',
            'slug': 'seo-optimization',
            'description': 'Technical SEO audit, Core Web Vitals optimization, and keyword ranking.',
            'startingPrice': '₹4,999',
          },
          {
            '_id': '3007',
            'name': 'Website Maintenance & AMC',
            'slug': 'web-maintenance',
            'description': 'Routine security updates, backups, SSL monitoring, and bug fixes.',
            'startingPrice': '₹2,999/mo',
          },
        ];

      case 'digital-marketing':
        return [
          {
            '_id': '4001',
            'name': 'Podcast Studio Recording (Bangalore)',
            'slug': 'podcast-studio-recording',
            'description': 'Acoustic soundproof studio with 4K multi-camera filming and broadcast Shure mics.',
            'startingPrice': '₹1,499/hr',
          },
          {
            '_id': '4002',
            'name': 'Podcast Video & Audio Editing',
            'slug': 'podcast-editing-mastering',
            'description': 'Full post-production, audio mastering, noise cleanup, and camera angle switching.',
            'startingPrice': '₹1,999',
          },
          {
            '_id': '4003',
            'name': 'Podcast Shorts & Viral Reels',
            'slug': 'podcast-shorts-reels',
            'description': 'Viral 9:16 vertical shorts clipping with animated captions, hooks, and sound FX.',
            'startingPrice': '₹1,499',
          },
          {
            '_id': '4004',
            'name': 'Full-Service Podcasting (Monthly)',
            'slug': 'podcasting',
            'description': '4 studio episodes recorded, edited, 12 viral reels, and Spotify/YouTube distribution.',
            'startingPrice': '₹14,999/mo',
          },
          {
            '_id': '4005',
            'name': 'Digital Marketing Campaigns',
            'slug': 'digital-marketing-campaigns',
            'description': 'Google Ads, Meta Ads (Facebook/Instagram), funnel architecture, and analytics.',
            'startingPrice': '₹4,999',
          },
          {
            '_id': '4006',
            'name': 'SEO & Organic Growth',
            'slug': 'seo-organic-growth',
            'description': 'Rank on Google Page 1 for high-intent business keywords in your city.',
            'startingPrice': '₹7,999/mo',
          },
        ];

      case 'laptop':
        return [
          {
            '_id': '5001',
            'name': 'Laptop Hardware Repair',
            'slug': 'laptop-repair',
            'description': 'Motherboard chip-level fix, keyboard, trackpad, and power port repair.',
            'startingPrice': '₹499',
          },
          {
            '_id': '5002',
            'name': 'Screen & Display Replacement',
            'slug': 'laptop-screen',
            'description': 'OEM display replacement with warranty for cracked or glitchy screens.',
            'startingPrice': '₹1,899',
          },
          {
            '_id': '5003',
            'name': 'SSD & RAM Performance Upgrade',
            'slug': 'laptop-upgrade',
            'description': 'High-speed NVMe SSD installation and RAM expansion for 5x speed boost.',
            'startingPrice': '₹999',
          },
          {
            '_id': '5004',
            'name': 'Free Diagnostic Check',
            'slug': 'laptop-diagnosis',
            'description': 'Free expert inspection and transparent quotation before starting repair.',
            'startingPrice': 'Free',
          },
        ];

      case 'desktop':
        return [
          {
            '_id': '6001',
            'name': 'Desktop Repair & Diagnostics',
            'slug': 'desktop-repair',
            'description': 'Fix no-display, boot loops, SMPS failure, and motherboard issues.',
            'startingPrice': '₹499',
          },
          {
            '_id': '6002',
            'name': 'Custom PC Build & Assembly',
            'slug': 'custom-pc',
            'description': 'Design, part sourcing, cable management, and build of office or gaming PCs.',
            'startingPrice': '₹1,499',
          },
          {
            '_id': '6003',
            'name': 'Deep Cleaning & Thermal Paste',
            'slug': 'desktop-service',
            'description': 'Blower dust cleanup, fan replacement, and premium Arctic thermal paste.',
            'startingPrice': '₹599',
          },
        ];

      case 'server':
        return [
          {
            '_id': '7001',
            'name': 'Server Hardware Setup & Rack Mount',
            'slug': 'server-installation',
            'description': 'Rack mounting, dual power supply, redundant network cabling, and OS install.',
            'startingPrice': '₹6,999',
          },
          {
            '_id': '7002',
            'name': 'Server Maintenance & AMC',
            'slug': 'server-maintenance',
            'description': 'Quarterly preventative health audits, RAID monitoring, and emergency support.',
            'startingPrice': '₹14,999/yr',
          },
        ];

      case 'cyber-security':
        return [
          {
            '_id': '8001',
            'name': 'Managed Firewall Deployment',
            'slug': 'managed-firewall-setup',
            'description': 'Fortinet/Sophos/pfsense firewall setup, VPN policies, and IPS rules.',
            'startingPrice': '₹12,999',
          },
          {
            '_id': '8002',
            'name': 'Security & Vulnerability Audit',
            'slug': 'security-audit',
            'description': 'Identify security gaps, rogue devices, and open ports on your network.',
            'startingPrice': '₹4,999',
          },
        ];

      default:
        return [];
    }
  }

  void _openBookingWizard(dynamic subcategory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ServiceConfigModal(
          serviceSlug: subcategory['slug'] ?? '',
          serviceName: subcategory['name'] ?? '',
          categoryId: 'cctv',
          subcategoryId: subcategory['_id']?.toString() ?? subcategory['id']?.toString() ?? '1000',
          defaultPrice: (subcategory['packages'] != null && subcategory['packages'].isNotEmpty)
              ? (subcategory['packages'][0]['price'] as num).toDouble()
              : 499.0,
        );
      },
    );
  }

  void _openSubcategoryAction(dynamic subcategory, String activeSlug) {
    if (activeSlug == 'cctv') {
      _openBookingWizard(subcategory);
    } else {
      final cat = ServiceRepository.categories.firstWhere(
        (c) => c.id == activeSlug,
        orElse: () => ServiceRepository.categories[0],
      );
      context.push('/quotation', extra: {
        'categorySlug': activeSlug,
        'categoryName': cat.title,
        'serviceSlug': subcategory['slug'] ?? '',
        'serviceName': subcategory['name'] ?? '',
      });
    }
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'cctv':
        return Icons.videocam;
      case 'networking':
        return Icons.router;
      case 'website-development':
        return Icons.language;
      case 'digital-marketing':
        return Icons.campaign;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.monitor;
      case 'server':
        return Icons.dns;
      case 'cyber-security':
        return Icons.security_outlined;
      case 'home-automation':
        return Icons.home_outlined;
      case 'electronic-contracts':
        return Icons.article_outlined;
      case 'software-licensing':
        return Icons.card_membership_outlined;
      default:
        return Icons.category;
    }
  }

  IconData _getSubcategoryIcon(String slug) {
    if (slug.contains('install') || slug.contains('camera')) return Icons.videocam;
    if (slug.contains('repair') || slug.contains('fix')) return Icons.build;
    if (slug.contains('maintenance') || slug.contains('amc')) return Icons.handyman;
    if (slug.contains('upgrade') || slug.contains('speed')) return Icons.trending_up;
    if (slug.contains('buy') || slug.contains('product')) return Icons.shopping_bag;
    if (slug.contains('survey') || slug.contains('audit')) return Icons.assignment;
    if (slug.contains('podcast') || slug.contains('mic')) return Icons.mic;
    if (slug.contains('web') || slug.contains('landing')) return Icons.language;
    if (slug.contains('security') || slug.contains('firewall')) return Icons.shield;
    return Icons.arrow_circle_right_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategorySlug = ref.watch(selectedCategoryProvider);

    // Sync subcategory loading if category slug changed
    if (_loadedCategorySlug != selectedCategorySlug) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSubcategories(selectedCategorySlug);
      });
    }

    final activeCategory = ServiceRepository.categories.firstWhere(
      (c) => c.id == selectedCategorySlug,
      orElse: () => ServiceRepository.categories[0],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar for Categories list
          Container(
            width: 110,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.borderColor)),
            ),
            child: ListView.builder(
              itemCount: ServiceRepository.categories.length,
              itemBuilder: (context, index) {
                final cat = ServiceRepository.categories[index];
                final isSelected = selectedCategorySlug == cat.id;
                return InkWell(
                  onTap: () {
                    ref.read(selectedCategoryProvider.notifier).state = cat.id;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(cat.id),
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.title,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Right content panel: Subcategories or Coming Soon
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: _isLoadingSubcategories
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _subcategories.isEmpty
                      ? ComingSoonPanel(
                          categoryTitle: activeCategory.title,
                          categorySlug: activeCategory.id,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subcategories.length,
                          itemBuilder: (context, index) {
                            final sub = _subcategories[index];
                            final startPrice = sub['startingPrice'] ??
                                (sub['packages'] != null && sub['packages'].isNotEmpty
                                    ? '₹${sub['packages'][0]['price']}'
                                    : (sub['slug'] == 'free-site-survey' ? 'Free' : '₹499'));

                            final isCctv = selectedCategorySlug == 'cctv';

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                              child: InkWell(
                                onTap: () => _openSubcategoryAction(sub, selectedCategorySlug),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                                        child: Icon(
                                          _getSubcategoryIcon(sub['slug'] ?? ''),
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sub['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppTheme.textPrimaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              sub['description'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondaryColor,
                                                height: 1.35,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Starting from: $startPrice',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 12.5,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.primaryColor,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        isCctv ? 'Book Now' : 'Get Quote',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 4),
                                                      const Icon(
                                                        Icons.arrow_forward,
                                                        color: Colors.white,
                                                        size: 11,
                                                      ),
                                                    ],
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
}

class ComingSoonPanel extends StatelessWidget {
  final String categoryTitle;
  final String categorySlug;

  const ComingSoonPanel({
    super.key,
    required this.categoryTitle,
    required this.categorySlug,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.upcoming_outlined,
                color: AppTheme.secondaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "$categoryTitle Services",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Custom Consultation Available",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Need services in this category? Our engineering team provides custom quotations and expert consultation.",
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/quotation', extra: {
                  'categorySlug': categorySlug,
                  'categoryName': categoryTitle,
                });
              },
              icon: const Icon(Icons.request_quote_outlined, size: 16),
              label: const Text("Request Custom Quotation"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
