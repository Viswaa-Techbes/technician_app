import 'package:flutter/material.dart';
import 'package:techbes_app/models/models.dart';
import '../services/services_api_service.dart';

class ServicesProvider extends ChangeNotifier {
  final ServicesApiService _apiService = ServicesApiService();

  List<Service> _services = [];
  List<Category> _categories = [];
  List<Service> _filteredServices = [];
  String _selectedCategory = '';
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  List<Category> get categories => _categories;
  List<Service> get filteredServices =>
      _selectedCategory.isEmpty ? _services : _filteredServices;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ServicesProvider() {
    loadServices();
  }

  void _initializeMockData() {
    _categories = [
      Category(id: '1', name: 'CCTV Systems', icon: 'videocam', serviceCount: 5),
      Category(id: '2', name: 'Networking', icon: 'router', serviceCount: 4),
      Category(
          id: '3', name: 'Cyber Security', icon: 'security', serviceCount: 6),
      Category(id: '4', name: 'IT Support', icon: 'support_agent', serviceCount: 8),
    ];

    _services = [
      Service(
        id: '1',
        name: 'HD CCTV Installation',
        category: 'CCTV Systems',
        description: 'Professional HD CCTV setup for homes and offices',
        longDescription:
            'Complete HD CCTV system installation with 24/7 monitoring capabilities. Includes 4K cameras, NVR setup, and cloud backup.',
        price: 499.99,
        rating: 4.8,
        reviewCount: 156,
        imageUrl:
            'https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=500&h=500&fit=crop',
        features: [
          '4K Ultra HD Cameras',
          '24/7 Cloud Monitoring',
          'Mobile App Access',
          'Night Vision',
          'Motion Detection',
        ],
      ),
      Service(
        id: '2',
        name: 'Network Setup & Optimization',
        category: 'Networking',
        description: 'Fast and secure network configuration for your business',
        longDescription:
            'Enterprise-grade network setup with optimization for speed and security. Includes WiFi 6, VPN, and firewall configuration.',
        price: 799.99,
        rating: 4.9,
        reviewCount: 234,
        imageUrl:
            'https://images.unsplash.com/photo-1633356122544-f134324ef6db?w=500&h=500&fit=crop',
        features: [
          'WiFi 6 Support',
          'VPN Configuration',
          'Firewall Setup',
          'Network Security',
          'Speed Optimization',
        ],
      ),
      Service(
        id: '3',
        name: 'Cybersecurity Assessment',
        category: 'Cyber Security',
        description: 'Comprehensive security audit and threat analysis',
        longDescription:
            'Professional security assessment including vulnerability scanning, penetration testing, and detailed report with recommendations.',
        price: 1299.99,
        rating: 5.0,
        reviewCount: 89,
        imageUrl:
            'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=500&h=500&fit=crop',
        features: [
          'Vulnerability Scanning',
          'Penetration Testing',
          'Report & Analysis',
          'Threat Modeling',
          'Security Recommendations',
        ],
      ),
      Service(
        id: '4',
        name: 'IT Technical Support',
        category: 'IT Support',
        description: '24/7 technical support for all your IT needs',
        longDescription:
            'Comprehensive IT support with remote assistance, on-site visits, and priority response times. Covers hardware and software issues.',
        price: 199.99,
        rating: 4.7,
        reviewCount: 412,
        imageUrl:
            'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=500&h=500&fit=crop',
        features: [
          'Remote Assistance',
          'On-site Support',
          'Priority Response',
          '24/7 Availability',
          'Hardware & Software',
        ],
      ),
      Service(
        id: '5',
        name: 'Backup & Recovery Solution',
        category: 'IT Support',
        description: 'Secure data backup with disaster recovery',
        longDescription:
            'Automated backup system with cloud storage and disaster recovery plan. Ensure your data is always safe and recoverable.',
        price: 599.99,
        rating: 4.6,
        reviewCount: 178,
        imageUrl:
            'https://images.unsplash.com/photo-1526374965328-7f5af1e1f4da?w=500&h=500&fit=crop',
        features: [
          'Automated Backup',
          'Cloud Storage',
          'Disaster Recovery',
          'Encryption',
          'Version Control',
        ],
      ),
      Service(
        id: '6',
        name: 'Firewall Installation',
        category: 'Networking',
        description: 'Advanced firewall for network protection',
        longDescription:
            'Next-generation firewall with threat prevention, intrusion detection, and real-time monitoring.',
        price: 899.99,
        rating: 4.8,
        reviewCount: 145,
        imageUrl:
            'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=500&h=500&fit=crop',
        features: [
          'Threat Prevention',
          'Intrusion Detection',
          'Real-time Monitoring',
          'DDoS Protection',
          'Advanced Logging',
        ],
      ),
      Service(
        id: '7',
        name: 'Data Encryption Service',
        category: 'Cyber Security',
        description: 'Enterprise-level data encryption',
        longDescription:
            'Military-grade encryption for sensitive data. Includes key management, encryption at rest, and in transit.',
        price: 699.99,
        rating: 4.9,
        reviewCount: 203,
        imageUrl:
            'https://images.unsplash.com/photo-1526628652108-351a0d44d13f?w=500&h=500&fit=crop',
        features: [
          'Military-grade Encryption',
          'Key Management',
          'End-to-end Protection',
          'Compliance Support',
          'Audit Trail',
        ],
      ),
      Service(
        id: '8',
        name: 'DVR Surveillance System',
        category: 'CCTV Systems',
        description: 'Complete DVR setup with storage',
        longDescription:
            'Professional DVR system with high-capacity storage, remote viewing, and analytics capabilities.',
        price: 349.99,
        rating: 4.7,
        reviewCount: 198,
        imageUrl:
            'https://images.unsplash.com/photo-1621905267918-48416bd8575a?w=500&h=500&fit=crop',
        features: [
          'High-capacity Storage',
          'Remote Viewing',
          'Analytics',
          'Backup System',
          'Professional Installation',
        ],
      ),
    ];
  }

  void filterByCategory(String categoryId) {
    _selectedCategory = categoryId;
    if (categoryId.isEmpty) {
      _filteredServices = [];
    } else {
      final category =
          _categories.firstWhere((c) => c.id == categoryId, orElse: () {
        return Category(id: '', name: '', icon: '', serviceCount: 0);
      });
      _filteredServices = _services
          .where((s) => s.category == category.name)
          .toList();
    }
    notifyListeners();
  }

  void clearFilter() {
    _selectedCategory = '';
    _filteredServices = [];
    notifyListeners();
  }

  Future<void> loadServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from API first
      final servicesResult = await _apiService.getAllServices();
      final categoriesResult = await _apiService.getCategories();

      if (servicesResult['success']) {
        _services = servicesResult['services'] ?? [];
      } else {
        // Fallback to mock data if API fails
        _initializeMockData();
        _error = 'Using cached data. API unavailable.';
      }

      if (categoriesResult['success']) {
        final categoryNames = categoriesResult['categories'] ?? [];
        _categories = categoryNames
            .asMap()
            .entries
            .map((e) => Category(
                  id: (e.key + 1).toString(),
                  name: e.value,
                  icon: _getCategoryIcon(e.value),
                  serviceCount: _services
                      .where((s) => s.category == e.value)
                      .length,
                ))
            .toList();
      } else {
        // Use default categories if API fails
        _categories = [
          Category(id: '1', name: 'CCTV Systems', icon: 'videocam', serviceCount: 3),
          Category(id: '2', name: 'Networking', icon: 'router', serviceCount: 2),
          Category(id: '3', name: 'Cyber Security', icon: 'security', serviceCount: 2),
          Category(id: '4', name: 'IT Support', icon: 'support_agent', serviceCount: 1),
        ];
      }
    } catch (e) {
      _error = 'Failed to load services: ${e.toString()}';
      _initializeMockData();
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'cctv systems':
        return 'videocam';
      case 'networking':
        return 'router';
      case 'cyber security':
        return 'security';
      case 'it support':
        return 'support_agent';
      default:
        return 'build';
    }
  }
}
