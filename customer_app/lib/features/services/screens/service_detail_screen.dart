import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';
import '../../../models/service_model.dart';
import '../../../repositories/service_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../components/service_config_modal.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  final String slug;

  const ServiceDetailScreen({super.key, required this.slug});

  @override
  ConsumerState<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  late MarketplaceService? _service;
  bool _quoteSubmitting = false;

  final _quoteNameController = TextEditingController();
  final _quotePhoneController = TextEditingController();
  final _quoteEmailController = TextEditingController();
  final _quoteLocationController = TextEditingController();
  final _quoteMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = ServiceRepository.getServiceBySlug(widget.slug);
  }

  @override
  void dispose() {
    _quoteNameController.dispose();
    _quotePhoneController.dispose();
    _quoteEmailController.dispose();
    _quoteLocationController.dispose();
    _quoteMessageController.dispose();
    super.dispose();
  }

  void _openBookingFlow() {
    final authState = ref.read(authProvider);
    if (authState.status != AuthStatus.authenticated) {
      // Prompt login, keep pending state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to continue booking this service.')),
      );
      context.push('/login');
      return;
    }

    if (_service == null) return;

    // Show step config modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ServiceConfigModal(
          serviceSlug: _service!.slug,
          serviceName: _service!.title,
          categoryId: _service!.categoryId,
          subcategoryId: _service!.id.toString(),
          defaultPrice: _service!.priceValue,
          onQuoteRequested: () {
            Navigator.pop(context);
            _openQuoteModal();
          },
        );
      },
    );
  }

  void _openQuoteModal() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Request Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Share details for ${_service?.title ?? 'service'}. We will contact you with a tailored estimate.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _quoteNameController,
                      decoration: const InputDecoration(labelText: 'Name', hintText: 'Enter name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quotePhoneController,
                      decoration: const InputDecoration(labelText: 'Phone', hintText: 'Enter mobile number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quoteEmailController,
                      decoration: const InputDecoration(labelText: 'Email', hintText: 'Enter email address'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quoteLocationController,
                      decoration: const InputDecoration(labelText: 'Location / Pincode', hintText: 'Enter area or pin'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _quoteMessageController,
                      decoration: const InputDecoration(labelText: 'Message (Optional)', hintText: 'Briefly describe your requirements'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ),
                ElevatedButton(
                  onPressed: _quoteSubmitting 
                      ? null 
                      : () async {
                          setDialogState(() => _quoteSubmitting = true);
                          final success = await _submitQuoteRequest();
                          setDialogState(() => _quoteSubmitting = false);
                          if (success && mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: _quoteSubmitting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Request', style: TextStyle(fontSize: 13)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitQuoteRequest() async {
    final name = _quoteNameController.text.trim();
    final phone = _quotePhoneController.text.trim();
    final email = _quoteEmailController.text.trim();
    final pincode = _quoteLocationController.text.trim();
    final message = _quoteMessageController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || pincode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return false;
    }

    try {
      final client = ref.read(dioClientProvider);
      // Replicates cctvApi.createLead endpoint '/leads' V2
      final response = await client.post('/leads', data: {
        'name': name,
        'phone': phone,
        'email': email,
        'pincode': pincode,
        'service': _service?.title ?? 'Service Detail Inquiry',
        'plan': message.isNotEmpty ? message : 'Quote request',
        'status': 'Quote Requested',
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote request submitted successfully! We will contact you soon.')),
        );
        _quoteNameController.clear();
        _quotePhoneController.clear();
        _quoteEmailController.clear();
        _quoteLocationController.clear();
        _quoteMessageController.clear();
        return true;
      }
    } catch (e) {
      debugPrint('Lead submission failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: ${e.toString()}')),
      );
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Not Found')),
        body: const Center(child: Text('The requested service could not be loaded.')),
      );
    }

    final theme = Theme.of(context);
    final isConfigurable = _service!.configurableType == 'cctv';

    return Scaffold(
      appBar: AppBar(
        title: Text(_service!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Image Section
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(_service!.image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _service!.category.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),

            // Header Meta Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '${_service!.rating}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            ' (${_service!.reviewCount} reviews)',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _service!.title,
                        style: theme.textTheme.headlineMedium?.copyWith(fontSize: 22, height: 1.2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _service!.tagline,
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13, height: 1.4),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Starting from', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                              const SizedBox(height: 2),
                              Text(
                                _service!.price,
                                style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 18, color: AppTheme.textPrimaryColor),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 16, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Text(_service!.duration, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Core Booking triggers
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _openBookingFlow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(isConfigurable ? 'Configure & Book' : 'Book Now'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: _openQuoteModal,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            ),
                            child: const Text('Request Quote', style: TextStyle(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Overview Section
            _buildSection(
              title: 'Overview',
              child: Text(
                _service!.description,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor, height: 1.5),
              ),
            ),

            // Includes / Checklist Section
            _buildSection(
              title: 'What\'s Included',
              child: Column(
                children: _service!.includes.map((inc) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppTheme.primaryColor, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            inc,
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Steps / How it works Section
            _buildSection(
              title: 'How it works',
              child: Column(
                children: List.generate(_service!.steps.length, (index) {
                  final step = _service!.steps[index];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            if (index < _service!.steps.length - 1)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: AppTheme.borderColor,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              step,
                              style: const TextStyle(fontSize: 13, height: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            // FAQs Section
            _buildSection(
              title: 'FAQs',
              child: _service!.faqs.isEmpty
                  ? const Text('No FAQs configured for this service.')
                  : ExpansionPanelList.radio(
                      elevation: 0,
                      dividerColor: Colors.transparent,
                      children: _service!.faqs.map((faq) {
                        return ExpansionPanelRadio(
                          value: faq.question,
                          headerBuilder: (context, isExpanded) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                faq.question,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            );
                          },
                          body: Padding(
                            padding: const EdgeInsets.only(bottom: 12, left: 4),
                            child: Text(
                              faq.answer,
                              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor, height: 1.5),
                            ),
                          ),
                          canTapOnHeader: true,
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
