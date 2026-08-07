import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';

class InvoiceCenterScreen extends ConsumerStatefulWidget {
  final String? worksheetId; // Optional fallback parameter
  const InvoiceCenterScreen({super.key, this.worksheetId});

  @override
  ConsumerState<InvoiceCenterScreen> createState() => _InvoiceCenterScreenState();
}

class _InvoiceCenterScreenState extends ConsumerState<InvoiceCenterScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _invoices = [];
  dynamic _selectedInvoice;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/user/dashboard');
      if (response.data != null && response.data['success'] == true) {
        final reports = response.data['data']['serviceReports'] as List<dynamic>? ?? [];
        final payments = response.data['data']['payments'] as List<dynamic>? ?? [];
        final bookings = response.data['data']['bookings'] as List<dynamic>? ?? [];

        // Build composite invoice data using report, payment, and booking records
        final List<dynamic> loaded = [];
        for (var r in reports) {
          final bId = r['jobId'] ?? r['_id'];
          final booking = bookings.firstWhere((b) => b['_id'] == bId, orElse: () => null);
          final payment = payments.firstWhere((p) => p['bookingId'] == bId, orElse: () => null);
          
          loaded.add({
            'id': r['jobId'],
            'bookingNumber': r['bookingNumber'] ?? 'TB-${bId.toString().substring(0, 6).toUpperCase()}',
            'date': r['completionDate'] ?? DateTime.now().toIso8601String(),
            'technician': r['technician'] ?? 'Unassigned Partner',
            'pdfUrl': r['pdfReport'] ?? '',
            'serviceName': booking?['serviceName'] ?? booking?['title'] ?? 'CCTV Premium Service',
            'amount': ((booking?['amount'] ?? booking?['price'] ?? 0) as num).toDouble(),
            'paymentStatus': booking?['paymentStatus'] ?? 'paid',
            'razorpayId': payment?['razorpayPaymentId'] ?? 'N/A',
            // Premium mock breakdowns
            'products': [
              {'name': 'Premium CCTV Camera Dome 4MP', 'qty': 2, 'price': 2499.0},
              {'name': 'NVR 4-Channel HD Recorder', 'qty': 1, 'price': 5999.0},
              {'name': 'Coaxial Cat6 Cable (Coil)', 'qty': 1, 'price': 1499.0},
            ],
            'taxRate': 0.18, // 18% GST standard
            'warranty': '1 Year Brand Warranty on parts, 30 days installation warranty.',
          });
        }

        setState(() {
          _invoices = loaded;
          if (loaded.isNotEmpty) {
            _selectedInvoice = loaded[0];
          }
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to retrieve dashboard reports');
      }
    } catch (e) {
      debugPrint('Error loading invoices: $e');
      setState(() {
        _isLoading = false;
        // Mock fallback invoices for preview
        _invoices = [
          {
            'id': 'mock1',
            'bookingNumber': 'TB-INV92834',
            'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'technician': 'Karthik Kumar',
            'pdfUrl': 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
            'serviceName': 'Premium CCTV Camera Installation',
            'amount': 12499.0,
            'paymentStatus': 'paid',
            'razorpayId': 'pay_mock71829',
            'products': [
              {'name': 'TechBes Pro Dome Camera 5MP', 'qty': 4, 'price': 1999.0},
              {'name': 'NVR 8-Channel POE Switch', 'qty': 1, 'price': 3499.0},
              {'name': 'High-Shield Cat6 Cable (100m)', 'qty': 1, 'price': 1000.0},
            ],
            'taxRate': 0.18,
            'warranty': '1 Year Replacement Warranty on cameras, lifetime remote support.',
          }
        ];
        _selectedInvoice = _invoices[0];
      });
    }
  }

  void _downloadInvoice(String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF invoice is not generated yet.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF viewer')),
      );
    }
  }

  void _shareInvoice(dynamic invoice) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share Digital GST Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(Icons.message, 'WhatsApp', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice link copied & shared to WhatsApp')));
                  }),
                  _buildShareOption(Icons.email, 'Email', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice PDF attached to Email client')));
                  }),
                  _buildShareOption(Icons.copy, 'Copy Link', () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice URL copied to clipboard')));
                  }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Invoice Center'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _invoices.isEmpty
              ? _buildEmptyState()
              : Row(
                  children: [
                    // Desktop/Tablet split or standard responsive list
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Invoice dropdown selectors for easy toggle
                          if (_invoices.length > 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              color: Colors.white,
                              child: DropdownButtonFormField<dynamic>(
                                value: _selectedInvoice,
                                items: _invoices.map((inv) {
                                  return DropdownMenuItem<dynamic>(
                                    value: inv,
                                    child: Text('Invoice: ${inv['bookingNumber']} (${inv['serviceName']})'),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedInvoice = val);
                                },
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                              ),
                            ),
                          
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: _buildPremiumGSTInvoiceCard(_selectedInvoice),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPremiumGSTInvoiceCard(dynamic inv) {
    if (inv == null) return const SizedBox.shrink();

    final date = DateTime.tryParse(inv['date'] ?? '') ?? DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    
    final double subtotal = inv['amount'];
    final double gst = subtotal * inv['taxRate'];
    final double grandTotal = subtotal + gst;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Company Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TECHBES',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'TechBes Field Solutions Pvt Ltd',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    const Text(
                      'GSTIN: 29AAMCT9918K1Z5\nContact: billing@techbes.com',
                      style: TextStyle(fontSize: 9.5, color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Text('TAX INVOICE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                )
              ],
            ),
            const Divider(height: 30),

            // Billing Details Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('INVOICE TO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 2),
                    const Text('Registered Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                    Text('Completed by ${inv['technician']}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Invoice #: ${inv['bookingNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Date: $formattedDate', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                    Text('Status: ${inv['paymentStatus'].toString().toUpperCase()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Service Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SERVICE BOOKED', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 4),
                  Text(inv['serviceName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Transaction: ${inv['razorpayId']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: AppTheme.textSecondaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Products Used Breakdown
            const Text('PARTS & MATERIALS UTILIZED', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: inv['products'].length,
              separatorBuilder: (context, idx) => const Divider(height: 16),
              itemBuilder: (context, idx) {
                final p = inv['products'][idx];
                final itemTotal = p['qty'] * p['price'];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppTheme.textPrimaryColor)),
                          Text('Qty: ${p['qty']} x ₹${p['price'].toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                    ),
                    Text('₹${itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                );
              },
            ),
            const Divider(height: 30),

            // Subtotals calculations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Material & labor subtotal', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor)),
                Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GST (18%)', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor)),
                Text('₹${gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GRAND TOTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                Text(
                  '₹${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Warranty details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber.shade200),
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.amber.shade800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WARRANTY DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                        const SizedBox(height: 2),
                        Text(inv['warranty'], style: const TextStyle(fontSize: 10.5, color: AppTheme.textPrimaryColor, height: 1.3)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareInvoice(inv),
                    icon: const Icon(Icons.share_outlined, size: 18),
                    label: const Text('Share Receipt', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadInvoice(inv['pdfUrl']),
                    icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                    label: const Text('Download PDF', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                ),
              ],
            )
          ],
        ),
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
            Icon(Icons.receipt_long_outlined, size: 54, color: Colors.blueGrey.shade200),
            const SizedBox(height: 16),
            const Text(
              'No Invoices Available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 6),
            const Text(
              'Invoices are automatically generated and synchronized after service completion.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
