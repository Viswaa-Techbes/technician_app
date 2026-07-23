import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _profile = {};
  List<dynamic> _addresses = [];
  List<dynamic> _payments = [];
  List<dynamic> _serviceReports = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        setState(() {
          _profile = data['profile'] ?? {};
          _addresses = data['addresses'] ?? [];
          _payments = data['payments'] ?? [];
          _serviceReports = data['serviceReports'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      setState(() {
        _error = 'Failed to load profile settings.';
        _isLoading = false;
      });
    }
  }

  void _openPDFReport(String? pdfUrl) async {
    if (pdfUrl == null || pdfUrl.isEmpty) return;
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF document')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final name = _profile['name'] ?? user?['name'] ?? 'User';
    final email = _profile['email'] ?? user?['email'] ?? 'Not provided';
    final phone = _profile['phone'] ?? _profile['mobileNumber'] ?? user?['mobileNumber'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfileData,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Card Info
            Card(
              elevation: 0,
              color: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      backgroundImage: _profile['profilePhoto'] != null 
                          ? NetworkImage(_profile['profilePhoto']) 
                          : null,
                      child: _profile['profilePhoto'] == null 
                          ? const Icon(Icons.person, color: Colors.white, size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                          if (phone.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2.0),
                              child: Text(
                                phone,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // Invoices & Worksheets Section
            if (_serviceReports.isNotEmpty) ...[
              _buildSectionHeader('Service Reports & Invoices'),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _serviceReports.length,
                itemBuilder: (context, index) {
                  final rep = _serviceReports[index];
                  final date = rep['completionDate'] != null 
                      ? DateFormat('d MMM yyyy').format(DateTime.parse(rep['completionDate'])) 
                      : '';
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                      title: Text('Booking #${rep['bookingNumber'] ?? rep['jobId']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text('Completed: $date', style: const TextStyle(fontSize: 11.5)),
                      trailing: const Icon(Icons.download, size: 20, color: AppTheme.primaryColor),
                      onTap: () => _openPDFReport(rep['pdfReport']),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Addresses Section
            _buildSectionHeader('Saved Addresses'),
            const SizedBox(height: 10),
            if (_addresses.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No saved addresses yet. Choose pin on maps in config modal or checkout to save.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _addresses.length,
                itemBuilder: (context, index) {
                  final addr = _addresses[index];
                  final formatted = addr['formattedAddress'] ?? 
                      [
                        addr['address'] ?? addr['addressLine1'],
                        addr['addressLine2'],
                        addr['city'],
                        addr['pincode']
                      ].where((s) => s != null).join(', ');

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(addr['label'] ?? 'Home', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              if (addr['isDefault'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Default', style: TextStyle(color: Color(0xFF065F46), fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(formatted, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.35)),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // Payments Archive Section
            if (_payments.isNotEmpty) ...[
              _buildSectionHeader('Transactions History'),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _payments.length > 5 ? 5 : _payments.length, // show max 5
                itemBuilder: (context, index) {
                  final p = _payments[index];
                  final amount = (p['amount'] ?? 0) / 100;
                  final date = p['createdAt'] != null 
                      ? DateFormat('d MMM, h:mm a').format(DateTime.parse(p['createdAt'])) 
                      : '-';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    child: ListTile(
                      title: Text(p['razorpayPaymentId'] ?? 'ID Pending', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(date, style: const TextStyle(fontSize: 11)),
                      trailing: Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Help & Settings Section
            _buildSectionHeader('Help & Settings'),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
                    title: const Text('Help Center & FAQs', style: TextStyle(fontSize: 13.5)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                    title: const Text('Contact Techbes Support', style: TextStyle(fontSize: 13.5)),
                    subtitle: const Text('24/7 client support assistance', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () async {
                      final url = Uri.parse('tel:9999999999');
                      if (await canLaunchUrl(url)) await launchUrl(url);
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primaryColor),
                    title: const Text('Privacy Policies', style: TextStyle(fontSize: 13.5)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Sign Out', style: TextStyle(fontSize: 13.5, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textPrimaryColor),
    );
  }
}
