import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'services/api_service.dart';
import 'services/payment_firestore_service.dart';
import 'models.dart';
import 'widgets.dart';
import 'features/job_description/widgets/job_description_section.dart';
import 'features/reviews/screens/submit_review_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'core/payments/razorpay_config.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  late JobStatus _currentStatus;
  late PaymentStatus _currentPaymentStatus;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;
  bool _isProcessingPayment = false;
  late final Razorpay _razorpay;
  late final PaymentFirestoreService _paymentFirestoreService;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.job.status;
    _currentPaymentStatus = widget.job.paymentStatus;
    _paymentFirestoreService = PaymentFirestoreService();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    if (_currentStatus == JobStatus.started) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: Column(
                    children: [
                      _buildTimerSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            _buildCustomerCard(),
                            _buildSectionHeader('Payment Summary'),
                            _buildPaymentCard(),
                            JobDescriptionSection(projectId: widget.job.id),
                            _buildSectionHeader('Project Site Location'),
                            _buildMapCard(),
                            _buildSectionHeader('Technical Documentation'),
                            _buildPhotoGrid(),
                            _buildSectionHeader('Project Attachments'),
                            _buildAttachmentsList(),
                            _buildSectionHeader('Field Observations'),
                            _buildNotesArea(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActionDock(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      title: Hero(
        tag: 'job-id-${widget.job.id}',
        child: Material(
          color: Colors.transparent,
          child: Text(
            'PROJECT #${widget.job.id}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontSize: 14,
            ),
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTimerSection() {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Hero(
      tag: 'job-card-${widget.job.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 48),
          child: Column(
            children: [
              StatusChip(status: _currentStatus),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _buildTimeSegment(hours, "HRS"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(minutes, "MIN"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(seconds, "SEC"),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isRunning ? "TASK SESSION ACTIVE" : "SESSION PAUSED",
                style: TextStyle(
                  color: _isRunning ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSegment(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: _isRunning ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 24),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1E3A8A), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.customerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const Text(
                      "Corporate Client",
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F9FF),
                  foregroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    final amountText = widget.job.price.toStringAsFixed(2);
    final isPaid = _currentPaymentStatus == PaymentStatus.paid;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Amount to Collect',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF64748B)),
              ),
              Text(
                'INR $amountText',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF1E3A8A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPaymentInfoChip(
                  isPaid ? 'PAID' : 'PENDING',
                  isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.job.orderId?.isNotEmpty == true ? 'Order: ${widget.job.orderId}' : 'Order not linked',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Future<void> _openGoogleMapsNavigation() async {
    Uri url;
    if (widget.job.googleMapsLink != null && widget.job.googleMapsLink!.isNotEmpty) {
      url = Uri.parse(widget.job.googleMapsLink!);
    } else {
      final double lat = widget.job.latitude ?? 13.0827;
      final double lng = widget.job.longitude ?? 80.2707;
      url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Widget _buildMapCard() {
    return Container(
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative grid lines
          Positioned.fill(
            child: CustomPaint(painter: _MapGridPainter()),
          ),
          // Decorative rings
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF2563EB),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Address chip
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pin_drop_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 6),
                  Text(
                    widget.job.address.length > 24
                        ? '${widget.job.address.substring(0, 24)}…'
                        : widget.job.address,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Location chip
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.job.googleMapsLink != null ? 'Map Link Attached' : '${widget.job.latitude ?? 0.0}° N, ${widget.job.longitude ?? 0.0}° E',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Navigation button
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openGoogleMapsNavigation,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.near_me_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'NAVIGATION',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Row(
      children: [
        Expanded(child: _buildPhotoBox("SITE BEFORE", Icons.history_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildPhotoBox("SITE AFTER", Icons.verified_rounded)),
      ],
    );
  }

  Widget _buildPhotoBox(String label, IconData icon) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList() {
    final files = widget.job.fileAttachments ?? [];
    if (files.isEmpty) {
      return const Text("No attachments provided", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13));
    }
    return Column(
      children: files.map((path) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.description_rounded, color: Color(0xFF3B82F6), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                path.split('/').last,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.file_download_outlined, color: Color(0xFF94A3B8), size: 18),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildNotesArea() {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Enter detailed site observations...",
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildBottomActionDock() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, -10)),
          ],
        ),
        child: _buildActionButtonForStatus(),
      ),
    );
  }

  Future<void> _updateStatus(String newStatus, {List<String>? attachments}) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.updateJobStatus(widget.job.id, newStatus, attachments: attachments);
    } catch (e) {
      debugPrint("Failed to update status: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _uploadWork() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true, // Required for web/certain platforms
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isProcessingPayment = true); // Using existing loader flag for simplicity
        
        List<String> downloadUrls = [];
        final storage = FirebaseStorage.instance;

        for (var file in result.files) {
          if (file.bytes == null) continue;
          
          final fileName = 'proofs/${widget.job.id}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final ref = storage.ref().child(fileName);
          
          // Upload
          final uploadTask = await ref.putData(
            file.bytes!,
            SettableMetadata(contentType: 'image/${file.extension ?? 'jpeg'}'),
          );
          
          final url = await uploadTask.ref.getDownloadURL();
          downloadUrls.add(url);
        }

        if (downloadUrls.isNotEmpty) {
          await _updateStatus('work_uploaded', attachments: downloadUrls);
          setState(() => _currentStatus = JobStatus.workUploaded);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Work proof uploaded successfully to cloud!")),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    } finally {
      if (mounted) setState(() => _isProcessingPayment = false);
    }
  }

  void _showPaymentQR() {
    // Generate a UPI payment link or use the Razorpay payment link
    final String upiUrl = "upi://pay?pa=techbes@upi&pn=Techbes&am=${widget.job.price}&cu=INR&tn=Job_${widget.job.id}";
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Customer Payment QR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AMOUNT: INR ${widget.job.price}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: QrImageView(
                data: upiUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Scan this code to pay via any UPI app', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            CustomButton(
              label: "OPEN RAZORPAY",
              onPressed: () {
                Navigator.pop(context);
                _startPaymentCollection();
              },
              color: const Color(0xFF2563EB),
              icon: Icons.payment_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPaymentCollection() async {
    final session = ref.read(authProvider);
    final orderId = widget.job.orderId;

    if (orderId == null || orderId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment order is missing. Ask the manager to recreate this payment link.')),
        );
      }
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      _razorpay.open({
        'key': RazorpayConfig.keyId,
        'amount': (widget.job.price * 100).round(),
        'name': RazorpayConfig.companyName,
        'description': widget.job.description.isNotEmpty ? widget.job.description : widget.job.serviceName,
        'order_id': orderId,
        'prefill': {
          'contact': widget.job.customerPhone,
          'email': session?.email ?? '',
        },
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to open Razorpay checkout: $e')));
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final api = ref.read(apiServiceProvider);

    try {
      await api.verifyPayment(
        jobId: widget.job.id,
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      await _paymentFirestoreService.markPaymentPaid(
        jobId: widget.job.id,
        orderId: response.orderId ?? '',
        paymentId: response.paymentId ?? '',
        amount: widget.job.price,
      );

      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
        _currentPaymentStatus = PaymentStatus.paid;
      });

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful'),
          content: Text('Payment ${response.paymentId ?? ''} was verified and the job was marked as paid.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment was captured but verification failed: $e')),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message ?? 'Payment failed. Please try again.')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet selected: ${response.walletName ?? 'Unknown'}')),
    );
  }

  Widget _buildActionButtonForStatus() {
    switch (_currentStatus) {
      case JobStatus.assigned:
        return CustomButton(
          label: "START JOB",
          onPressed: () async {
            await _updateStatus('started');
            setState(() => _currentStatus = JobStatus.started);
            _startTimer();
          },
          color: const Color(0xFF2563EB),
          icon: Icons.play_circle_rounded,
        );
      case JobStatus.started:
        return Row(
          children: [
            Expanded(
              child: _isRunning
                  ? CustomButton(label: "PAUSE", onPressed: _pauseTimer, color: const Color(0xFFF59E0B), icon: Icons.pause_circle_rounded)
                  : CustomButton(label: "START", onPressed: _startTimer, color: const Color(0xFF2563EB), icon: Icons.play_circle_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: "SITE VISIT DONE",
                onPressed: _uploadWork,
                color: const Color(0xFF8B5CF6),
                icon: Icons.check_circle_outline,
              ),
            ),
          ],
        );
      case JobStatus.workUploaded:
        return CustomButton(
          label: "REQUEST COMPLETION",
          onPressed: () async {
            await _updateStatus('completion_requested');
            setState(() => _currentStatus = JobStatus.completionRequested);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Completion request sent to manager.")),
              );
            }
          },
          color: const Color(0xFF8B5CF6),
          icon: Icons.send_rounded,
        );
      case JobStatus.completionRequested:
        return CustomButton(
          label: "WAITING FOR APPROVAL",
          onPressed: () {},
          color: const Color(0xFF64748B),
          icon: Icons.hourglass_bottom_rounded,
        );
      case JobStatus.approvedByManager:
      case JobStatus.paymentPending:
        if (_currentPaymentStatus != PaymentStatus.paid) {
          return CustomButton(
            label: _isProcessingPayment ? "PROCESSING PAYMENT" : "COLLECT PAYMENT",
            onPressed: _isProcessingPayment ? () {} : _showPaymentQR,
            color: const Color(0xFF10B981),
            icon: Icons.qr_code_scanner_rounded,
          );
        }
        return const SizedBox();
      case JobStatus.paymentDone:
      case JobStatus.completed:
        return CustomButton(
          label: "COLLECT CLIENT REVIEW",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubmitReviewScreen(
                  technicianId: widget.job.technicianId ?? '',
                  technicianName: widget.job.technicianName ?? "Technician",
                  projectId: widget.job.id,
                  clientName: widget.job.customerName,
                ),
              ),
            );
          },
          color: const Color(0xFFF59E0B),
          icon: Icons.star_rounded,
        );
    }
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Horizontal lines
    const spacing = 28.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Cross-hair center lines
    final cx = size.width / 2;
    final cy = size.height / 2 - 20;
    final crossPaint = Paint()
      ..color = const Color(0xFF3B82F6).withValues(alpha: 0.12)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), crossPaint);
    canvas.drawLine(Offset(0, cy), Offset(size.width, cy), crossPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
