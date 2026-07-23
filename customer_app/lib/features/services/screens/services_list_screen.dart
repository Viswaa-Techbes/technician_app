import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../components/service_config_modal.dart';

class ServicesListScreen extends ConsumerStatefulWidget {
  const ServicesListScreen({super.key});

  @override
  ConsumerState<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends ConsumerState<ServicesListScreen> {
  bool _isLoadingCategories = true;
  String? _error;
  List<dynamic> _categories = [];
  String? _selectedCategorySlug;
  List<dynamic> _subcategories = [];
  bool _isLoadingSubcategories = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/catalog/categories');
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _categories = response.data['data'] ?? [];
          _isLoadingCategories = false;
        });
        if (_categories.isNotEmpty) {
          _selectCategory(_categories[0]['slug']);
        }
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      setState(() {
        _error = 'Unable to connect to service catalog.';
        _isLoadingCategories = false;
        // Fallback to static values
        _categories = [
          {'name': 'CCTV', 'slug': 'cctv', 'description': 'Smart surveillance and security setups', 'icon': 'Camera'},
          {'name': 'Networking', 'slug': 'networking', 'description': 'LAN, router and Mesh setups', 'icon': 'Network'},
          {'name': 'Laptop Repair', 'slug': 'laptop', 'description': 'OS fixes and hardware repair', 'icon': 'Laptop'},
          {'name': 'Desktop Setup', 'slug': 'desktop', 'description': 'Custom builds and diagnostic checkups', 'icon': 'Monitor'},
          {'name': 'Business AMC', 'slug': 'amc', 'description': 'Preventive maintenance plans', 'icon': 'Zap'},
        ];
        if (_categories.isNotEmpty) {
          _selectCategory(_categories[0]['slug']);
        }
      });
    }
  }

  Future<void> _selectCategory(String slug) async {
    setState(() {
      _selectedCategorySlug = slug;
      _isLoadingSubcategories = true;
      _subcategories = [];
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/catalog/categories/$slug/subcategories');
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _subcategories = response.data['data'] ?? [];
          _isLoadingSubcategories = false;
        });
      } else {
        throw Exception('Failed to load subcategories');
      }
    } catch (e) {
      debugPrint('Error loading subcategories: $e');
      setState(() {
        _isLoadingSubcategories = false;
        // Offline Fallbacks
        if (slug == 'cctv') {
          _subcategories = [
            {
              '_id': '1000',
              'name': 'Install New CCTV',
              'slug': 'install-new-cctv',
              'description': 'Fresh CCTV camera installation for homes and offices.',
            },
            {
              '_id': '1001',
              'name': 'Repair Existing CCTV',
              'slug': 'repair-existing-cctv',
              'description': 'Diagnose and repair video loss, DVR/NVR errors, and power faults.',
            },
            {
              '_id': '1002',
              'name': 'Maintenance (AMC)',
              'slug': 'maintenance-amc',
              'description': 'Annual Maintenance Contracts for continuous, uninterrupted security coverage.',
            },
            {
              '_id': '1003',
              'name': 'Upgrade Existing CCTV',
              'slug': 'upgrade-existing-cctv',
              'description': 'Expand your coverage, upgrade to IP cameras, or increase storage capacities.',
            },
            {
              '_id': '1004',
              'name': 'Buy CCTV Products',
              'slug': 'buy-cctv-products',
              'description': 'Purchase individual security cameras, recorders, or cables.',
            },
            {
              '_id': '1005',
              'name': 'Free Site Survey',
              'slug': 'free-site-survey',
              'description': 'Schedule a free on-site survey for custom security planning and estimation.',
            }
          ];
        } else {
          _subcategories = [
            {
              '_id': '2000',
              'name': 'Standard Diagnostics & Service',
              'slug': 'standard-diagnostics',
              'description': 'Audit and troubleshoot configurations.',
            }
          ];
        }
      });
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
          categoryId: _selectedCategorySlug ?? 'cctv',
          subcategoryId: subcategory['_id']?.toString() ?? subcategory['id']?.toString() ?? '1000',
          defaultPrice: (subcategory['packages'] != null && subcategory['packages'].isNotEmpty)
              ? (subcategory['packages'][0]['price'] as num).toDouble()
              : 499.0,
        );
      },
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug.toLowerCase()) {
      case 'cctv':
        return Icons.videocam;
      case 'networking':
      case 'network':
        return Icons.router;
      case 'laptop':
        return Icons.laptop;
      case 'desktop':
        return Icons.monitor;
      case 'server':
        return Icons.dns;
      case 'amc':
      case 'electronic-contracts':
        return Icons.electrical_services;
      case 'home-automation':
        return Icons.home_repair_service;
      case 'website-development':
        return Icons.public;
      default:
        return Icons.category;
    }
  }

  IconData _getSubcategoryIcon(String slug) {
    if (slug.contains('install')) return Icons.videocam;
    if (slug.contains('repair')) return Icons.build;
    if (slug.contains('maintenance') || slug.contains('amc')) return Icons.handyman;
    if (slug.contains('upgrade')) return Icons.trending_up;
    if (slug.contains('buy') || slug.contains('products')) return Icons.shopping_bag;
    if (slug.contains('survey')) return Icons.assignment;
    return Icons.arrow_circle_right_outlined;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCategories) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

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
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategorySlug == cat['slug'];
                return InkWell(
                  onTap: () => _selectCategory(cat['slug']),
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
                          _getCategoryIcon(cat['slug']),
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['name'] ?? '',
                          style: TextStyle(
                            fontSize: 11,
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

          // Right content for Subcategories list
          Expanded(
            child: Container(
              color: AppTheme.backgroundColor,
              child: _isLoadingSubcategories
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                  : _subcategories.isEmpty
                      ? const Center(child: Text('No services found in this category'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _subcategories.length,
                          itemBuilder: (context, index) {
                            final sub = _subcategories[index];
                            final startPrice = sub['packages'] != null && sub['packages'].isNotEmpty
                                ? '₹${sub['packages'][0]['price']}'
                                : (sub['slug'] == 'free-site-survey' ? 'Free' : '₹499');

                            return Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.borderColor),
                              ),
                              child: InkWell(
                                onTap: () => _openBookingWizard(sub),
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
                                                  child: const Row(
                                                    children: [
                                                      Text(
                                                        'Book Now',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      Icon(
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
