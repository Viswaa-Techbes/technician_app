import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';

class MyQuotesScreen extends ConsumerStatefulWidget {
  const MyQuotesScreen({super.key});

  @override
  ConsumerState<MyQuotesScreen> createState() => _MyQuotesScreenState();
}

class _MyQuotesScreenState extends ConsumerState<MyQuotesScreen> {
  List<dynamic> _quotes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  Future<void> _fetchQuotes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get(ApiConfig.myQuotes);
      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _quotes = response.data['data'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception(response.data?['message'] ?? 'Failed to load quotations');
      }
    } catch (e) {
      debugPrint('Error loading quotes: $e');
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'quotation_sent':
      case 'quotation sent':
      case 'quote sent':
        return Colors.green;
      case 'quotation_accepted':
      case 'accepted':
        return AppTheme.primaryColor;
      case 'advance_paid':
        return Colors.blue;
      case 'balance_pending':
      case 'payment_pending':
        return Colors.purple;
      case 'paid':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'in_review':
      case 'under review':
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'quotation_sent':
      case 'quotation sent':
      case 'quote sent':
        return 'Quote Ready';
      case 'quotation_accepted':
      case 'accepted':
        return 'Accepted';
      case 'advance_paid':
        return 'Advance Paid';
      case 'balance_pending':
        return 'Balance Due';
      case 'payment_pending':
        return 'Payment Pending';
      case 'paid':
        return 'Booked & Paid';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'in_review':
      case 'under review':
      case 'pending':
      default:
        return 'Under Review';
    }
  }

  void _downloadPdf(String quoteId) async {
    final pdfUrl = '${ApiConfig.baseUrl}/api/v2/quotes/$quoteId/pdf';
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF quotation')),
        );
      }
    }
  }

  Future<void> _acceptQuote(String quoteId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Accept Quotation?'),
        content: const Text('By accepting this quotation, you confirm that the proposed scope and estimation are agreeable. Our service team will be notified immediately.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final client = ref.read(dioClientProvider);
      final res = await client.post('/api/v2/quotes/$quoteId/accept');
      if (res.data?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation accepted! Admin team notified.'), backgroundColor: Colors.green),
          );
        }
        await _fetchQuotes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept quotation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectQuote(String quoteId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Decline Quotation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please share the reason for declining (optional):', style: TextStyle(fontSize: 12.5, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Budget constraints, changed requirements',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Back')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Decline Quote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final client = ref.read(dioClientProvider);
      final res = await client.post('/api/v2/quotes/$quoteId/reject', data: {
        'reason': reasonController.text.trim(),
      });
      if (res.data?['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quotation marked as declined.'), backgroundColor: Colors.orange),
          );
        }
        await _fetchQuotes();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline quotation: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Quotations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchQuotes,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchQuotes,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _quotes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.request_quote_outlined,
                                size: 56,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No Quotation Requests Yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Submit a quote request for Networking, Website, Digital Marketing, or CCTV installation.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondaryColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/quotation'),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Request a Quote'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchQuotes,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotes.length,
                        itemBuilder: (context, index) {
                          final quote = _quotes[index];
                          final status = (quote['status'] ?? 'pending').toString();
                          final statusColor = _getStatusColor(status);
                          final requestId = quote['requestId'] ?? quote['_id'] ?? '';
                          final category = quote['serviceCategory'] ?? quote['category'] ?? 'Service';
                          final subcategory = quote['subcategory'] ?? quote['serviceName'] ?? quote['service'] ?? '';
                          final finalAmount = quote['finalAmount'];
                          final createdAt = quote['createdAt'] != null
                              ? DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(quote['createdAt']))
                              : '';
                          final pricingStatus = quote['pricingStatus'] ?? '';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppTheme.borderColor),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '#$requestId',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _formatStatus(status),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Service title
                                  Text(
                                    subcategory.isNotEmpty ? subcategory : category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Category: $category',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor,
                                    ),
                                  ),
                                  const Divider(height: 20),

                                  // Pricing & Date
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Estimate',
                                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            finalAmount != null ? '₹$finalAmount' : pricingStatus,
                                            style: TextStyle(
                                              fontSize: finalAmount != null ? 16 : 11.5,
                                              fontWeight: finalAmount != null ? FontWeight.bold : FontWeight.w500,
                                              color: finalAmount != null ? AppTheme.primaryColor : Colors.orange.shade800,
                                            ),
                                          ),
                                          if (finalAmount != null && quote['advanceAmount'] != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              'Adv: ₹${quote['advanceAmount']} (${quote['advancePercentage'] ?? 50}%) • Bal: ₹${quote['balanceAmount'] ?? 0}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (quote['_id'] != null && finalAmount != null)
                                        OutlinedButton.icon(
                                          onPressed: () => _downloadPdf(quote['_id']),
                                          icon: const Icon(Icons.picture_as_pdf, size: 14),
                                          label: const Text('View PDF', style: TextStyle(fontSize: 11)),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                    ],
                                  ),

                                  if (status.toLowerCase().contains('sent') && quote['_id'] != null) ...[
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _acceptQuote(quote['_id']),
                                            icon: const Icon(Icons.check_circle_outline, size: 16),
                                            label: const Text('Accept Quote', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _rejectQuote(quote['_id']),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                                            label: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.redAccent),
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (createdAt.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      'Submitted on $createdAt',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppTheme.textSecondaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
