import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../auth/providers/auth_provider.dart';

/// Unified Quotation / Enquiry Screen for Networking, Web Design,
/// Digital Marketing, Podcasting, and any future quotation-based categories.
///
/// Sends a POST to /api/v2/quotes (QuoteRequest model in BE).
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

  // Service lists per category (mirrors Main App QUOTATION_CATEGORIES)
  static const Map<String, List<Map<String, String>>> _servicesByCategory = {
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
    // Pre-fill from auth user
    final user = ref.read(authProvider).user;
    if (user != null) {
      _nameController.text = user['name'] ?? '';
      _emailController.text = user['email'] ?? '';
      _phoneController.text = user['mobileNumber'] ?? user['phone'] ?? '';
    }
    // Pre-select service if slug was passed
    if (widget.serviceSlug != null) {
      _selectedService = widget.serviceSlug;
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

  List<Map<String, String>> get _services {
    return _servicesByCategory[widget.categorySlug] ?? [];
  }

  IconData get _categoryIcon {
    switch (widget.categorySlug) {
      case 'networking':
        return Icons.router;
      case 'website-development':
        return Icons.language;
      case 'digital-marketing':
        return Icons.campaign;
      default:
        return Icons.miscellaneous_services;
    }
  }

  Color get _categoryColor {
    switch (widget.categorySlug) {
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

  Future<void> _submitQuotation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final client = ref.read(dioClientProvider);

      // Build the QuoteRequest payload matching the BE QuoteRequest model
      final selectedServiceName = _services.firstWhere(
        (s) => s['slug'] == _selectedService,
        orElse: () => {'name': widget.serviceName ?? widget.categoryName},
      )['name'] ?? widget.categoryName;

      final payload = {
        // BE required fields
        'fullName': _nameController.text.trim(),
        'mobile': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _locationController.text.trim(),
        'locality': _locationController.text.trim(),
        'category': widget.categorySlug,
        'serviceCategory': widget.categorySlug,
        'subcategory': _selectedService ?? widget.serviceSlug ?? widget.categorySlug,
        'service': _selectedService ?? widget.serviceSlug ?? widget.categorySlug,
        'serviceName': selectedServiceName,

        // Form fields & fallbacks
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'company': _companyController.text.trim(),
        'companyName': _companyController.text.trim(),
        'city': _locationController.text.trim(),
        'budget': _budgetController.text.trim(),
        'description': _descriptionController.text.trim(),
        'message': _descriptionController.text.trim(),
        'additionalRequirements': _descriptionController.text.trim(),
        'urgency': _urgency,
        'source': 'mobile_app',
      };

      final response = await client.post(ApiConfig.submitQuote, data: payload);

      if (response.data != null &&
          (response.data['success'] == true ||
              response.statusCode == 200 ||
              response.statusCode == 201)) {
        if (mounted) {
          setState(() {
            _submitted = true;
            _isSubmitting = false;
          });
        }
      } else {
        throw Exception(response.data?['message'] ?? 'Submission failed');
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
        title: Text('${widget.categoryName} Quotation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _categoryColor.withAlpha(15),
                border: Border(bottom: BorderSide(color: _categoryColor.withAlpha(40))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _categoryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_categoryIcon, color: _categoryColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.categoryName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: _categoryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Get a custom quote from our certified team. We\'ll contact you within 24 hours.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Service Selector
                    if (_services.isNotEmpty) ...[
                      _buildSectionLabel('Select Service'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedService,
                        decoration: _inputDecoration('Select a specific service'),
                        items: _services.map((s) {
                          return DropdownMenuItem<String>(
                            value: s['slug'],
                            child: Text(
                              s['name'] ?? '',
                              style: const TextStyle(fontSize: 13.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedService = v),
                        validator: (v) => v == null ? 'Please select a service' : null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Contact Info
                    _buildSectionLabel('Your Contact Details'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration('Full Name *'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration('Mobile Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone is required';
                        if (v.trim().length < 10) return 'Enter a valid 10-digit number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration('Email Address *'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _companyController,
                      decoration: _inputDecoration('Company / Organisation (Optional)'),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),

                    // Project Details
                    _buildSectionLabel('Project Details'),
                    const SizedBox(height: 8),

                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration('Location / City / Pincode *'),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Location is required' : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _budgetController,
                      decoration: _inputDecoration('Approximate Budget (Optional, e.g. ₹50,000)'),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration(
                          'Describe your requirements *\n(scope, timeline, special notes)'),
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) =>
                          (v == null || v.trim().length < 10)
                              ? 'Please provide at least a brief description'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Urgency selector
                    _buildSectionLabel('Timeline / Urgency'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _urgencyChip('flexible', 'Flexible'),
                        _urgencyChip('within_week', 'This Week'),
                        _urgencyChip('within_month', 'This Month'),
                        _urgencyChip('urgent', 'Urgent (48h)'),
                      ],
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
                              'Submit Quotation Request',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),

                    const SizedBox(height: 12),

                    // Trust note
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: AppTheme.textSecondaryColor),
                        SizedBox(width: 4),
                        Text(
                          'Secure submission. No spam, ever.',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _urgencyChip(String value, String label) {
    final selected = _urgency == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppTheme.textPrimaryColor)),
      selected: selected,
      selectedColor: _categoryColor,
      backgroundColor: AppTheme.borderColor,
      onSelected: (v) {
        if (v) setState(() => _urgency = value);
      },
      padding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13.5,
        color: AppTheme.textPrimaryColor,
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
      appBar: AppBar(title: const Text('Request Submitted')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 48, color: Color(0xFF047857)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quotation Request Sent!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your request for ${widget.categoryName} has been received. Our expert team will review your requirements and contact you within 24 business hours.',
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('View My Bookings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
