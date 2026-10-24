import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/providers/auth_provider.dart';

/// Unified Quotation / Enquiry Screen for CCTV, Networking, Web Designing,
/// and Digital Marketing & Podcasting.
///
/// Sends a POST to /api/v2/quotes (QuoteRequest model in BE).
/// Guaranteed zero upfront payment, matching the Main Site customer workflow.
class QuotationScreen extends ConsumerStatefulWidget {
  final String categorySlug;
  final String categoryName;
  final String? serviceSlug;
  final String? serviceName;

  const QuotationScreen({
    super.key,
    required this.categorySlug,
    required this.categoryName,
    this.serviceSlug,
    this.serviceName,
  });

  @override
  ConsumerState<QuotationScreen> createState() => _QuotationScreenState();
}

class _QuotationScreenState extends ConsumerState<QuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedService;
  String _urgency = 'flexible';
  bool _isSubmitting = false;
  bool _submitted = false;
  String? _submittedRequestId;

  // CCTV Specific Fields
  String _cctvPropertyType = 'Independent House / Villa';
  String _cctvCameraCount = '3-4 Cameras';
  String _cctvStorage = '1TB Surveillance HDD (~15 Days)';
  DateTime? _preferredDate;
  String _preferredTimeSlot = 'Morning (10:00 AM - 01:00 PM)';

  // Networking Specific Fields
  String _networkPremises = 'Corporate Office';
  String _networkUsersCount = '10-25 Users';

  // Web Specific Fields
  String _webProjectType = 'Corporate Business Website';

  // Digital Marketing Specific Fields
  String _marketingFocus = 'Podcasting Studio Recording';

  // Canonical Service lists matching Main App QUOTATION_CATEGORIES
  static const Map<String, List<Map<String, String>>> _servicesByCategory = {
    'cctv': [
      {'slug': 'install-new-cctv', 'name': 'Install New CCTV'},
      {'slug': 'repair-existing-cctv', 'name': 'Repair Existing CCTV'},
      {'slug': 'maintenance-amc', 'name': 'Maintenance / AMC'},
      {'slug': 'upgrade-existing-cctv', 'name': 'Upgrade Existing CCTV'},
      {'slug': 'buy-cctv-products', 'name': 'Buy CCTV Products'},
      {'slug': 'free-site-survey', 'name': 'Free Site Survey'},
    ],
    'networking': [
      {'slug': 'new-network-setup', 'name': 'New Office Network Setup'},
      {'slug': 'wifi-internet-issues', 'name': 'Wi-Fi & Internet Speed Optimization'},
      {'slug': 'router-modem', 'name': 'Router, Switch & Access Point Setup'},
      {'slug': 'office-network-deployment', 'name': 'Office Network Deployment'},
      {'slug': 'structured-cabling', 'name': 'Structured Cat6 / Fiber Cabling'},
      {'slug': 'network-upgrade', 'name': 'Network Hardware Upgrade'},
      {'slug': 'network-security', 'name': 'Network Security & Firewall'},
      {'slug': 'server-storage', 'name': 'Server & NAS Storage Integration'},
      {'slug': 'network-amc', 'name': 'Network AMC'},
      {'slug': 'network-accessories', 'name': 'Network Accessories'},
      {'slug': 'network-troubleshooting', 'name': 'Network Troubleshooting'},
      {'slug': 'network-survey', 'name': 'Free Network Site Audit'},
    ],
    'website-development': [
      {'slug': 'business-website', 'name': 'Business Website'},
      {'slug': 'landing-page', 'name': 'Landing Page'},
      {'slug': 'ecommerce-website', 'name': 'Ecommerce Website'},
      {'slug': 'web-app', 'name': 'Custom Web Application'},
      {'slug': 'web-redesign', 'name': 'Website Redesign'},
      {'slug': 'web-maintenance', 'name': 'Website Maintenance'},
      {'slug': 'speed-optimization', 'name': 'Speed Optimization'},
      {'slug': 'web-security', 'name': 'Website Security & SSL'},
      {'slug': 'domain-hosting', 'name': 'Domain & Hosting Setup'},
      {'slug': 'seo-optimization', 'name': 'SEO Optimization'},
      {'slug': 'web-content', 'name': 'Website Content & Copywriting'},
      {'slug': 'web-migration', 'name': 'Website Migration'},
      {'slug': 'web-support', 'name': 'Website Technical Support'},
      {'slug': 'web-amc', 'name': 'Website AMC'},
      {'slug': 'web-consultation', 'name': 'Web Consultation'},
      {'slug': 'new-website', 'name': 'New Website Setup'},
      {'slug': 'portfolio-website', 'name': 'Portfolio Website'},
      {'slug': 'website-development', 'name': 'Website Development'},
    ],
    'digital-marketing': [
      {'slug': 'podcasting', 'name': 'Podcasting Studio'},
      {'slug': 'podcast-studio-recording', 'name': 'Podcast Studio Recording'},
      {'slug': 'podcast-editing-mastering', 'name': 'Podcast Video & Audio Editing'},
      {'slug': 'podcast-shorts-reels', 'name': 'Podcast Shorts & Viral Reels'},
      {'slug': 'podcast-distribution-seo', 'name': 'Podcast Distribution & SEO'},
      {'slug': 'remote-podcast-production', 'name': 'Remote Podcast Production'},
      {'slug': 'digital-marketing', 'name': 'Digital Marketing Strategy'},
      {'slug': 'google-ads-ppc', 'name': 'Google Ads & PPC Campaigns'},
      {'slug': 'meta-ads-campaigns', 'name': 'Meta Ads (IG & FB)'},
      {'slug': 'seo-organic-growth', 'name': 'SEO & Organic Growth'},
    ],
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill from auth user state
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['mobileNumber'] ?? user['phone'] ?? '';
      if (user['address'] != null && user['address'].toString().isNotEmpty) {
        _locationController.text = user['address'].toString();
      }
    }

    // Pre-select service if slug was passed
    if (widget.serviceSlug != null && widget.serviceSlug!.isNotEmpty) {
      _selectedService = widget.serviceSlug;
    } else {
      final available = _services;
      if (available.isNotEmpty) {
        _selectedService = available.first['slug'];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String get _normalizedCategorySlug {
    final s = widget.categorySlug.toLowerCase();
    if (s.contains('cctv')) return 'cctv';
    if (s.contains('net')) return 'networking';
    if (s.contains('web') || s.contains('design')) return 'website-development';
    if (s.contains('market') || s.contains('podcast')) return 'digital-marketing';
    return 'cctv';
  }

  List<Map<String, String>> get _services {
    return _servicesByCategory[_normalizedCategorySlug] ?? _servicesByCategory['cctv']!;
  }

  IconData get _categoryIcon {
    switch (_normalizedCategorySlug) {
      case 'cctv':
        return Icons.videocam;
      case 'networking':
        return Icons.router;
      case 'website-development':
        return Icons.language;
      case 'digital-marketing':
        return Icons.campaign;
      default:
        return Icons.verified_outlined;
    }
  }

  Color get _categoryColor {
    switch (_normalizedCategorySlug) {
      case 'cctv':
        return const Color(0xFF0284C7); // sky / brand blue
      case 'networking':
        return const Color(0xFF059669); // emerald
      case 'website-development':
        return const Color(0xFF4F46E5); // indigo
      case 'digital-marketing':
        return const Color(0xFFDB2777); // pink
      default:
        return AppTheme.primaryColor;
    }
  }

  String get _canonicalCategoryName {
    switch (_normalizedCategorySlug) {
      case 'cctv':
        return 'CCTV';
      case 'networking':
        return 'Networking';
      case 'website-development':
        return 'Web Designing';
      case 'digital-marketing':
        return 'Digital Marketing';
      default:
        return widget.categoryName;
    }
  }

  Future<void> _selectPreferredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _categoryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final client = ref.read(dioClientProvider);

      final selectedServiceMap = _services.firstWhere(
        (s) => s['slug'] == _selectedService,
        orElse: () => {'name': widget.serviceName ?? _canonicalCategoryName},
      );
      final selectedServiceName = selectedServiceMap['name'] ?? _canonicalCategoryName;

      // Compile tailored property / requirement notes based on category
      String finalRequirements = _descriptionController.text.trim();
      if (_normalizedCategorySlug == 'cctv') {
        final cctvDetails = 'Property: $_cctvPropertyType | Cameras: $_cctvCameraCount | Storage: $_cctvStorage';
        finalRequirements = finalRequirements.isEmpty ? cctvDetails : '$cctvDetails\nNotes: $finalRequirements';
      } else if (_normalizedCategorySlug == 'networking') {
        final netDetails = 'Premises: $_networkPremises | Users: $_networkUsersCount';
        finalRequirements = finalRequirements.isEmpty ? netDetails : '$netDetails\nNotes: $finalRequirements';
      }

      // Build payload strictly aligned with BE QuoteRequest and Main App
      final payload = {
        'fullName': _nameController.text.trim(),
        'name': _nameController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'whatsapp': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _locationController.text.trim(),
        'locality': _locationController.text.trim(),
        'serviceCategory': _canonicalCategoryName,
        'category': _canonicalCategoryName,
        'subcategory': selectedServiceName,
        'service': selectedServiceName,
        'serviceSlug': _selectedService ?? widget.serviceSlug,
        'propertyType': _normalizedCategorySlug == 'cctv'
            ? _cctvPropertyType
            : (_normalizedCategorySlug == 'networking' ? _networkPremises : null),
        'cameraCount': _normalizedCategorySlug == 'cctv' ? _cctvCameraCount : null,
        'storage': _normalizedCategorySlug == 'cctv' ? _cctvStorage : null,
        'company': _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
        'companyName': _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : null,
        'budget': _budgetController.text.trim().isNotEmpty ? _budgetController.text.trim() : null,
        'additionalRequirements': finalRequirements,
        'message': finalRequirements,
        'preferredVisitDate': _preferredDate?.toIso8601String(),
        'preferredVisitTime': _preferredTimeSlot,
        'urgency': _urgency,
        'source': 'Customer Mobile App',
      };

      final response = await client.post(ApiConfig.submitQuote, data: payload);

      if (response.data != null &&
          (response.data['success'] == true ||
              response.statusCode == 200 ||
              response.statusCode == 201)) {
        final data = response.data['data'];
        final reqId = data?['requestId'] ?? data?['id']?.toString() ?? 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        if (mounted) {
          setState(() {
            _submitted = true;
            _isSubmitting = false;
            _submittedRequestId = reqId.toString();
          });
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to submit quotation request');
      }
    } catch (e) {
      debugPrint('Quotation submit error: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_canonicalCategoryName Quotation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _categoryColor.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: _categoryColor.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon, color: _categoryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _canonicalCategoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: _categoryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: const Text(
                                'No Upfront Payment',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Our certified engineering team reviews your requirements and provides a transparent itemized quotation.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Service Selection
                    _buildSectionLabel('Select Service'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedService,
                      decoration: _inputDecoration('Choose service'),
                      items: _services.map((s) {
                        return DropdownMenuItem<String>(
                          value: s['slug'],
                          child: Text(
                            s['name'] ?? '',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedService = v),
                      validator: (v) => v == null ? 'Please select a service' : null,
                    ),
                    const SizedBox(height: 20),

                    // 2. Category-Specific Specifications
                    if (_normalizedCategorySlug == 'cctv') ...[
                      _buildSectionLabel('CCTV System Specifications'),
                      const SizedBox(height: 8),

                      // Property Type
                      const Text('Premises / Property Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _cctvPropertyType,
                        decoration: _inputDecoration('Select property type'),
                        items: const [
                          DropdownMenuItem(value: 'Independent House / Villa', child: Text('Independent House / Villa')),
                          DropdownMenuItem(value: 'Apartment / Gated Community', child: Text('Apartment / Gated Community')),
                          DropdownMenuItem(value: 'Retail Shop / Showroom', child: Text('Retail Shop / Showroom')),
                          DropdownMenuItem(value: 'Commercial Office', child: Text('Commercial Office')),
                          DropdownMenuItem(value: 'Warehouse / Factory', child: Text('Warehouse / Factory')),
                        ],
                        onChanged: (v) => setState(() => _cctvPropertyType = v!),
                      ),
                      const SizedBox(height: 12),

                      // Camera Count
                      const Text('Number of Cameras', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _cctvCameraCount,
                        decoration: _inputDecoration('Estimated cameras'),
                        items: const [
                          DropdownMenuItem(value: '1-2 Cameras', child: Text('1-2 Cameras (Small Office / Entry)')),
                          DropdownMenuItem(value: '3-4 Cameras', child: Text('3-4 Cameras (Complete Home / Shop)')),
                          DropdownMenuItem(value: '5-8 Cameras', child: Text('5-8 Cameras (Office / Villa)')),
                          DropdownMenuItem(value: '9-16 Cameras', child: Text('9-16 Cameras (Large Commercial)')),
                          DropdownMenuItem(value: '16+ Cameras', child: Text('16+ Cameras (Enterprise System)')),
                        ],
                        onChanged: (v) => setState(() => _cctvCameraCount = v!),
                      ),
                      const SizedBox(height: 12),

                      // Storage
                      const Text('Recording & Storage Preference', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _cctvStorage,
                        decoration: _inputDecoration('Select storage'),
                        items: const [
                          DropdownMenuItem(value: '1TB Surveillance HDD (~15 Days)', child: Text('1TB Surveillance HDD (~15 Days)')),
                          DropdownMenuItem(value: '2TB Surveillance HDD (~30 Days)', child: Text('2TB Surveillance HDD (~30 Days)')),
                          DropdownMenuItem(value: '4TB Surveillance HDD (~60 Days)', child: Text('4TB Surveillance HDD (~60 Days)')),
                          DropdownMenuItem(value: 'SD Card Storage', child: Text('SD Card Storage (Wi-Fi Camera)')),
                          DropdownMenuItem(value: 'Advise during site inspection', child: Text('Advise during site inspection')),
                        ],
                        onChanged: (v) => setState(() => _cctvStorage = v!),
                      ),
                      const SizedBox(height: 20),
                    ] else if (_normalizedCategorySlug == 'networking') ...[
                      _buildSectionLabel('Networking Infrastructure Details'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _networkPremises,
                        decoration: _inputDecoration('Premises type'),
                        items: const [
                          DropdownMenuItem(value: 'Corporate Office', child: Text('Corporate Office')),
                          DropdownMenuItem(value: 'Co-Working / Startup Space', child: Text('Co-Working / Startup Space')),
                          DropdownMenuItem(value: 'Residential Villa / Home', child: Text('Residential Villa / Home')),
                          DropdownMenuItem(value: 'Retail / Restaurant / Clinic', child: Text('Retail / Restaurant / Clinic')),
                          DropdownMenuItem(value: 'Warehouse / Campus', child: Text('Warehouse / Campus')),
                        ],
                        onChanged: (v) => setState(() => _networkPremises = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _networkUsersCount,
                        decoration: _inputDecoration('Concurrent devices / users'),
                        items: const [
                          DropdownMenuItem(value: '1-10 Users', child: Text('1-10 Users')),
                          DropdownMenuItem(value: '10-25 Users', child: Text('10-25 Users')),
                          DropdownMenuItem(value: '25-50 Users', child: Text('25-50 Users')),
                          DropdownMenuItem(value: '50-100+ Users', child: Text('50-100+ Users (Enterprise)')),
                        ],
                        onChanged: (v) => setState(() => _networkUsersCount = v!),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // 3. Contact & Location
                    _buildSectionLabel('Contact & Site Address'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name *'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('Mobile Number (10 digits) *'),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                        final digits = v.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) return 'Please enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email Address (Optional)'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration('Site Location / Address / Area *'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Location or address is required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _companyController,
                      decoration: _inputDecoration('Business / Organisation Name (Optional)'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 20),

                    // 4. Preferred Visit Schedule (Optional)
                    _buildSectionLabel('Preferred Site Visit Schedule (Optional)'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectPreferredDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                            const SizedBox(width: 10),
                            Text(
                              _preferredDate != null
                                  ? DateFormat('EEEE, d MMMM yyyy').format(_preferredDate!)
                                  : 'Select Preferred Date (Tap to schedule)',
                              style: TextStyle(
                                fontSize: 13,
                                color: _preferredDate != null ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                                fontWeight: _preferredDate != null ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _preferredTimeSlot,
                      decoration: _inputDecoration('Preferred time window'),
                      items: const [
                        DropdownMenuItem(value: 'Morning (10:00 AM - 01:00 PM)', child: Text('Morning (10:00 AM - 01:00 PM)')),
                        DropdownMenuItem(value: 'Afternoon (01:00 PM - 04:00 PM)', child: Text('Afternoon (01:00 PM - 04:00 PM)')),
                        DropdownMenuItem(value: 'Evening (04:00 PM - 07:00 PM)', child: Text('Evening (04:00 PM - 07:00 PM)')),
                        DropdownMenuItem(value: 'Flexible Any Time', child: Text('Flexible Any Time')),
                      ],
                      onChanged: (v) => setState(() => _preferredTimeSlot = v!),
                    ),
                    const SizedBox(height: 20),

                    // 5. Additional Notes & Description
                    _buildSectionLabel('Additional Notes / Specific Requirements'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration('Mention brands preferred, cabling distance, or special requests...'),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitQuotation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _categoryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'Request Free Quotation',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        '🛡️ Zero upfront commitment. Verified technician review.',
                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _categoryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Quotation Received')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, size: 52, color: Color(0xFF15803D)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quotation Request Submitted!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textPrimaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_submittedRequestId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    'Reference #$_submittedRequestId',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                'Your request for $_canonicalCategoryName has been logged. Our engineering team will review your requirements and share an itemized quote within 24 business hours.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/my-quotes'),
                  icon: const Icon(Icons.description_outlined, color: Colors.white, size: 18),
                  label: const Text('View in My Quotations', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go('/'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
