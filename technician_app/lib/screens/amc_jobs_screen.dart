import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../services/api_service.dart';

// Standalone Riverpod provider for AMC visits
final amcVisitsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final res = await api.getAmcVisits();
  if (res['success'] == true) {
    return res['data'] as List<dynamic>? ?? [];
  }
  throw Exception(res['message'] ?? 'Failed to load AMC visits');
});

// Add getAmcVisits to ApiService extension or helper
extension ApiServiceAmc on ApiService {
  Future<Map<String, dynamic>> getAmcVisits() async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/v2/amc/technician/visits"),
      headers: _headers,
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> completeAmcVisit({
    required String contractId,
    required String visitId,
    required String notes,
    required List<String> partsUsed,
    required String recommendations,
    required String customerSignature,
    required String technicianSignature,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/api/v2/amc/contracts/$contractId/complete-visit"),
      headers: _headers,
      body: jsonEncode({
        'visitId': visitId,
        'notes': notes,
        'partsUsed': partsUsed,
        'recommendations': recommendations,
        'customerSignature': customerSignature,
        'technicianSignature': technicianSignature,
      }),
    );
    return jsonDecode(res.body);
  }
}

class AmcJobsScreen extends ConsumerStatefulWidget {
  const AmcJobsScreen({super.key});

  @override
  ConsumerState<AmcJobsScreen> createState() => _AmcJobsScreenState();
}

class _AmcJobsScreenState extends ConsumerState<AmcJobsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isToday(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  bool _isUpcoming(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return checkDate.isAfter(today);
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitsAsync = ref.watch(amcVisitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AMC CONTRACT JOBS'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF1E3A8A),
          indicatorWeight: 4,
          tabs: const [
            Tab(text: "TODAY'S"),
            Tab(text: "UPCOMING"),
            Tab(text: "COMPLETED"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(amcVisitsProvider),
          )
        ],
      ),
      body: visitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading visits: $err')),
        data: (visits) {
          final todayVisits = visits.where((v) => v['status'] == 'Scheduled' && _isToday(v['visitDate'])).toList();
          final upcomingVisits = visits.where((v) => v['status'] == 'Scheduled' && _isUpcoming(v['visitDate'])).toList();
          final completedVisits = visits.where((v) => v['status'] == 'Completed' || v['status'] == 'Cancelled' || v['status'] == 'Skipped').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildVisitsList(todayVisits),
              _buildVisitsList(upcomingVisits),
              _buildVisitsList(completedVisits),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVisitsList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No AMC checkups found',
              style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final visit = list[index];
        final visitDate = DateTime.tryParse(visit['visitDate'])?.toLocal() ?? DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        visit['customerName'] ?? 'Customer checkup',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: visit['status'] == 'Completed' ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        visit['status'].toUpperCase(),
                        style: TextStyle(
                          color: visit['status'] == 'Completed' ? const Color(0xFF065F46) : const Color(0xFF1E40AF),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'AMC Plan: ${visit['amcPlan'] ?? 'Basic'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Checkup Date: ${visitDate.day}/${visitDate.month}/${visitDate.year}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        visit['address'] ?? 'No Address Provided',
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => launchUrl(Uri.parse("tel:${visit['customerPhone']}")),
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Colors.blue),
                      onPressed: () => launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(visit['address'])}")),
                    ),
                    const Spacer(),
                    if (visit['status'] == 'Scheduled')
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AmcVisitFormScreen(visit: visit),
                            ),
                          ).then((_) => ref.invalidate(amcVisitsProvider));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Start Checkup', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------
// AMC Visit Form Screen
// ----------------------------------------------------
class AmcVisitFormScreen extends ConsumerStatefulWidget {
  final dynamic visit;
  const AmcVisitFormScreen({super.key, required this.visit});

  @override
  ConsumerState<AmcVisitFormScreen> createState() => _AmcVisitFormScreenState();
}

class _AmcVisitFormScreenState extends ConsumerState<AmcVisitFormScreen> {
  final _notesController = TextEditingController();
  final _partsController = TextEditingController();
  final _recommendationsController = TextEditingController();
  
  bool _submitting = false;

  // Checklists
  final Map<String, bool> _checklist = {
    'Cameras alignment checked': false,
    'Lens cleaned & dust free': false,
    'Power supply voltages verified': false,
    'Hard drive recording checks': false,
    'Connectors checked & tightened': false,
  };

  // Signatures points lists
  final List<Offset?> _customerSigPoints = [];
  final List<Offset?> _techSigPoints = [];

  @override
  void dispose() {
    _notesController.dispose();
    _partsController.dispose();
    _recommendationsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    // Validate checklist
    if (_checklist.values.contains(false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all checklist items first!'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_customerSigPoints.isEmpty || _techSigPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture both signatures before submitting!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      
      // Simple base64 signature simulation or mock URL strings
      final customerSigBase64 = "data:image/png;base64,mockCustSig";
      final techSigBase64 = "data:image/png;base64,mockTechSig";

      final parts = _partsController.text.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

      final res = await api.completeAmcVisit(
        contractId: widget.visit['contractId'],
        visitId: widget.visit['visitId'],
        notes: _notesController.text,
        partsUsed: parts,
        recommendations: _recommendationsController.text,
        customerSignature: customerSigBase64,
        technicianSignature: techSigBase64,
      );

      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Visit completed and saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        throw Exception(res['message'] ?? 'Submission failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMC CHECKUP FORM'),
      ),
      body: _submitting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Client: ${widget.visit['customerName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Address: ${widget.visit['address']}',
                  style: TextStyle(color: Colors.grey.shade650, fontSize: 13, height: 1.3),
                ),
                const Divider(height: 32),

                // Checklist Section
                const Text(
                  'PREVENTATIVE CHECKLIST',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 8),
                ..._checklist.keys.map((key) => CheckboxListTile(
                      title: Text(key, style: const TextStyle(fontSize: 14)),
                      value: _checklist[key],
                      onChanged: (val) => setState(() => _checklist[key] = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
                const Divider(height: 32),

                // Notes Fields
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Observations & Notes',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _partsController,
                  decoration: InputDecoration(
                    labelText: 'Parts Installed (Comma Separated)',
                    helperText: 'e.g. 2 BNC Pins, 1 DC Jack',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _recommendationsController,
                  decoration: InputDecoration(
                    labelText: 'Future Recommendations',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Divider(height: 32),

                // Signatures
                const Text(
                  'SIGNATURE CONFIRMATION',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 0.5),
                ),
                const SizedBox(height: 12),
                
                // Customer Signature
                const Text('Customer Signature Pad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                _buildSigPad(_customerSigPoints, () => setState(() => _customerSigPoints.clear())),
                
                const SizedBox(height: 20),
                
                // Technician Signature
                const Text('Technician Signature Pad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                _buildSigPad(_techSigPoints, () => setState(() => _techSigPoints.clear())),

                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'SUBMIT & CLOSE CHECKUP',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
    );
  }

  Widget _buildSigPad(List<Offset?> points, VoidCallback onClear) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.globalPosition);
              setState(() {
                points.add(localPos);
              });
            },
            onPanEnd: (details) => points.add(null),
            child: CustomPaint(
              painter: SignaturePainter(points),
              size: Size.infinite,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade100,
              child: IconButton(
                icon: const Icon(Icons.clear, size: 14, color: Colors.red),
                onPressed: onClear,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// Custom painter for signature pads
// ----------------------------------------------------
class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Adjust points locally to avoid offsets offsetting
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
