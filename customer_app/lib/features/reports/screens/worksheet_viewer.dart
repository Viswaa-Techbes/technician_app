import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_config.dart';

class WorksheetViewerScreen extends ConsumerStatefulWidget {
  final String worksheetId; // maps to jobId in routing

  const WorksheetViewerScreen({super.key, required this.worksheetId});

  @override
  ConsumerState<WorksheetViewerScreen> createState() => _WorksheetViewerScreenState();
}

class _WorksheetViewerScreenState extends ConsumerState<WorksheetViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _worksheet;
  String? _activePhotoUrl; // Lightbox overlay photo

  @override
  void initState() {
    super.initState();
    _fetchWorksheetDetails();
  }

  Future<void> _fetchWorksheetDetails() async {
    try {
      final client = ref.read(dioClientProvider);
      final response = await client.get('/api/v2/worksheets/job/${widget.worksheetId}');

      if (response.data != null && response.data['success'] == true) {
        setState(() {
          _worksheet = response.data['data'];
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load service worksheet data');
      }
    } catch (e) {
      debugPrint('Error fetching worksheet: $e');
      setState(() {
        _errorMessage = 'Failed to load service report. Ensure you are connected to the network.';
        _isLoading = false;
      });
    }
  }

  void _downloadPdf() async {
    final pdfUrl = _worksheet?['pdfUrl'];
    if (pdfUrl == null || pdfUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF report link is not ready yet')),
      );
      return;
    }

    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open PDF download link')),
        );
      }
    }
  }

  void _shareReportLink() {
    final pdfUrl = _worksheet?['pdfUrl'];
    if (pdfUrl == null || pdfUrl.isEmpty) return;

    Clipboard.setData(ClipboardData(text: pdfUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF Report download link copied to clipboard!')),
    );
  }

  void _openLightbox(String url) {
    setState(() {
      _activePhotoUrl = url;
    });
  }

  void _closeLightbox() {
    setState(() {
      _activePhotoUrl = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    if (_errorMessage != null || _worksheet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service Report')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage ?? 'Worksheet not found.', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _fetchWorksheetDetails, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final status = _worksheet!['status'] ?? 'draft';
    final tech = _worksheet!['technicianId'] ?? {};
    final materials = _worksheet!['materialsUsed'] as List<dynamic>? ?? [];
    final beforePhotos = _worksheet!['beforePhotos'] as List<dynamic>? ?? [];
    final duringPhotos = _worksheet!['duringPhotos'] as List<dynamic>? ?? [];
    final afterPhotos = _worksheet!['afterPhotos'] as List<dynamic>? ?? [];

    final double labourCost = double.tryParse(_worksheet!['labourCost']?.toString() ?? '') ?? 0;
    final double materialCost = double.tryParse(_worksheet!['materialCost']?.toString() ?? '') ?? 0;
    final double totalCost = double.tryParse(_worksheet!['totalCost']?.toString() ?? '') ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Report ${_worksheet!['worksheetNumber'] ?? ''}'),
        actions: [
          if (_worksheet!['pdfUrl'] != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReportLink,
            ),
          ]
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header ribbon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.slate.shade900,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'OFFICIAL WORK REPORT',
                          style: TextStyle(color: AppTheme.primaryColor, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Booking: ${_worksheet!['bookingId']}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.extrabold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(
                            'Status: ${status.toString().toUpperCase()}',
                            style: const TextStyle(color: Colors.emerald, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            _worksheet!['completionOtpVerified'] == true ? 'OTP Verified' : 'Standard Handover',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Info & Tech details cards
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, size: 16, color: AppTheme.primaryColor),
                                SizedBox(width: 6),
                                Text('Client Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimaryColor)),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(_worksheet!['customerName'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(_worksheet!['customerMobile'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                            const SizedBox(height: 4),
                            Text(_worksheet!['customerAddress'] ?? '', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.handyman_outlined, size: 16, color: AppTheme.primaryColor),
                                SizedBox(width: 6),
                                Text('Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimaryColor)),
                              ],
                            ),
                            const Divider(height: 16),
                            Text(tech['name'] ?? 'Engineer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(tech['specialty'] ?? 'Service Specialist', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                            if (tech['rating'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${tech['rating']} / 5',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Description and Observations
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Observations & Findings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        const Text('REQUESTED WORK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.slate.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_worksheet!['requestedWorkDescription'] ?? 'Standard CCTV Setup.', style: const TextStyle(fontSize: 12.5)),
                        ),
                        const SizedBox(height: 12),
                        const Text('DIAGNOSTICS & FINDINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.slate.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_worksheet!['technicianObservations'] ?? 'No findings logged.', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.slate.shade800)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Installed materials table
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Materials / Spare Parts Installed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        materials.isEmpty
                            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No materials billed.', style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondaryColor))))
                            : Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(1),
                                  2: FlexColumnWidth(1.5),
                                  3: FlexColumnWidth(1.5),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(color: Colors.slate.shade900),
                                    children: const [
                                      TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                      TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Qty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                      TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                      TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Total', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)))),
                                    ],
                                  ),
                                  ...materials.map((m) {
                                    final rate = double.tryParse(m['unitPrice']?.toString() ?? m['unitCost']?.toString() ?? '') ?? 0;
                                    final total = double.tryParse(m['total']?.toString() ?? m['totalCost']?.toString() ?? '') ?? 0;
                                    return TableRow(
                                      children: [
                                        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text(m['name'] ?? '', style: const TextStyle(fontSize: 11.5)))),
                                        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('${m['quantity']}', style: const TextStyle(fontSize: 11.5)))),
                                        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('₹${rate.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11.5)))),
                                        TableCell(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)))),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Photo Verification Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Work Verification Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildPhotoThumbnail('Before Work', beforePhotos)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPhotoThumbnail('During Work', duringPhotos)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildPhotoThumbnail('After Work', afterPhotos)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Signatures Section
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppTheme.borderColor)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Signatures', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildSignatureBox('Client Signature', _worksheet!['customerSignatureUrl'])),
                            const SizedBox(width: 12),
                            Expanded(child: _buildSignatureBox('Technician Signature', _worksheet!['technicianSignatureUrl'])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Invoice Summary panel
                Card(
                  elevation: 0,
                  color: Colors.slate.shade50,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.slate.shade200)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('Labour Charges', style: TextStyle(color: AppTheme.textSecondaryColor)),
                            Text('₹${labourCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('Materials Subtotal', style: TextStyle(color: AppTheme.textSecondaryColor)),
                            Text('₹${materialCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text('Total Billed amount', style: TextStyle(fontWeight: FontWeight.extrabold, fontSize: 14)),
                            Text('₹${totalCost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.extrabold, fontSize: 16, color: AppTheme.primaryColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),

          // Fullscreen Lightbox Overlay
          if (_activePhotoUrl != null)
            GestureDetector(
              onTap: _closeLightbox,
              child: Container(
                color: Colors.black.withOpacity(0.9),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Image.network(
                    _activePhotoUrl!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnail(String label, List<dynamic> list) {
    final hasPhoto = list.isNotEmpty;
    final photoUrl = hasPhoto ? list[0].toString() : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor), textAlign: TextAlign.center),
        const SizedBox(height: 4),
        InkWell(
          onTap: hasPhoto ? () => _openLightbox(photoUrl) : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            aspectRatio: 1,
            decoration: BoxDecoration(
              color: Colors.slate.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(photoUrl, fit: BoxFit.cover)
                : const Icon(Icons.camera_alt_outlined, color: Colors.slate, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureBox(String label, String? url) {
    final hasSign = url != null && url.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 6),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.center,
          child: hasSign
              ? Image.network(url, fit: BoxFit.contain)
              : const Text('No signature', style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        ),
      ],
    );
  }
}
