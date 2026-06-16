import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'widgets.dart';
import 'services/api_service.dart';
import 'services/realtime_service.dart';
import 'job_detail_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'login_screen.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'providers/live_technicians_provider.dart';
import 'providers/job_providers.dart';
import 'providers/incoming_requests_provider.dart';
import 'job_request_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnDuty = false;
  String _userName = "Technician";
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realtimeServiceProvider).connect();
    });
  }

  Future<void> _fetchProfile() async {
    final session = ref.read(authProvider);
    if (session == null) return;
    
    _userName = session.name;
    final api = ref.read(apiServiceProvider);
    
    try {
      final profile = await api.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _isOnDuty = profile['isOnline'] == true;
        });
        if (_isOnDuty) _checkPermissionAndStartTracking();
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _toggleDuty(bool val) async {
    final session = ref.read(authProvider);
    if (session == null) return;

    try {
      debugPrint('[DashboardScreen] Toggle clicked userId=${session.id} isOnline=$val');
      final response = await ref.read(apiServiceProvider).updateTechnicianStatus(
            userId: session.id,
            isOnline: val,
          );
      debugPrint('[DashboardScreen] Status update success: $response');
      setState(() => _isOnDuty = val);
      ref.invalidate(liveTechniciansProvider);
      
      if (val) {
        _checkPermissionAndStartTracking();
      } else {
        _trackingTimer?.cancel();
      }
    } catch (e) {
      _showMessage("Failed to update status: $e");
    }
  }

  Future<void> _checkPermissionAndStartTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage("Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage("Location permissions are permanently denied.");
      return;
    }

    _startTracking();
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    // Immediate first update
    _performLocationUpdate();
    
    _trackingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      _performLocationUpdate();
    });
  }

  Future<void> _performLocationUpdate() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      debugPrint('[DashboardScreen] Sending live location lat=${pos.latitude}, lng=${pos.longitude}');
      
      // Update via Socket
      ref.read(realtimeServiceProvider).updateLocation(pos.latitude, pos.longitude);
      
      // Update via REST API (New Phase 2 dispatch endpoint)
      await ref.read(apiServiceProvider).updateLiveLocation(pos.latitude, pos.longitude);
      
      ref.invalidate(liveTechniciansProvider);
    } catch (e) {
      debugPrint("Location update failed: $e");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }


  @override
  Widget build(BuildContext context) {
    ref.listen<List<IncomingJobRequest>>(incomingRequestsProvider, (previous, next) {
      if (next.isNotEmpty && (previous == null || next.length > previous.length)) {
        final newRequest = next.last;
        showGeneralDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.9),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation1, animation2) {
            return UberJobPopup(request: newRequest);
          },
        );
      }
    });

    final jobsAsync = ref.watch(jobsProvider(null));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: jobsAsync.when(
        data: (jobs) => _buildContent(context, jobs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Job> jobs) {
    final completedCount = jobs.where((j) => j.status == JobStatus.completed || j.status == JobStatus.paymentDone).length;
    final assignedCount = jobs.where((j) => j.status == JobStatus.assigned).length;
    final pendingCount = jobs.where((j) => j.status == JobStatus.completionRequested || j.status == JobStatus.workUploaded || j.status == JobStatus.approvedByManager || j.status == JobStatus.paymentPending).length;

    final screenWidth = MediaQuery.of(context).size.width;
    final requests = ref.watch(incomingRequestsProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        _buildProductionHeader(context),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedDutyToggle(),
                if (requests.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const JobRequestScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flash_on_rounded, color: Colors.amberAccent, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${requests.length} New Job Dispatch(es) Available!',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap here to view and accept requests before they expire.',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _buildProductionSummary(completedCount, assignedCount, pendingCount),
                const SizedBox(height: 48),
                _buildSectionHeader("ACTIVE PROJECTS"),
                const SizedBox(height: 16),
                _buildStaggeredHorizontalTasks(context, jobs.where((j) => j.status != JobStatus.completed && j.status != JobStatus.paymentDone && j.status != JobStatus.cancelled).toList()),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductionHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenWidth > 600 ? 300.0 : 220.0;
    
    return SliverAppBar(
      expandedHeight: headerHeight,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF1E3A8A),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -60,
                bottom: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(screenWidth * 0.06, 0, screenWidth * 0.06, 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) => Opacity(
                        opacity: value,
                        child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Hero(
                                tag: 'app_logo',
                                child: Image.asset(
                                  'assets/logos/logo.png',
                                  height: screenWidth > 600 ? 60 : 40,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Row(
                                children: [
                                  Consumer(
                                    builder: (context, ref, child) {
                                      final requests = ref.watch(incomingRequestsProvider);
                                      if (requests.isEmpty) return const SizedBox.shrink();
                                      return Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (context) => const JobRequestScreen()),
                                              );
                                            },
                                            icon: const Icon(Icons.notifications_active_rounded, color: Colors.amberAccent, size: 28),
                                          ),
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 16,
                                                minHeight: 16,
                                              ),
                                              child: Text(
                                                '${requests.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      ref.read(authProvider.notifier).logout();
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    },
                                    icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "WELCOME BACK,",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: screenWidth > 600 ? 15 : 13, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                          ),
                          Text(
                            _userName,
                            style: TextStyle(color: Colors.white, fontSize: screenWidth > 600 ? 44 : 36, fontWeight: FontWeight.w900, letterSpacing: -1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDutyToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutExpo,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _isOnDuty ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _isOnDuty ? const Color(0xFFBBF7D0) : const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: _isOnDuty ? const Color(0xFF166534) : const Color(0xFFF43F5E),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                    child: Text(_isOnDuty ? "SERVICE ONLINE" : "SERVICE OFFLINE"),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOnDuty ? "You are ready to accept new projects" : "Go online to start your work session",
                    style: TextStyle(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Switch.adaptive(
                value: _isOnDuty,
                onChanged: _toggleDuty,
                activeTrackColor: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 28),
          CustomButton(
            label: _isOnDuty ? "END SESSION" : "START SESSION",
            onPressed: () => _toggleDuty(!_isOnDuty),
            color: _isOnDuty ? const Color(0xFFF43F5E) : const Color(0xFF2563EB),
            icon: _isOnDuty ? Icons.logout_rounded : Icons.bolt_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildProductionSummary(int completed, int assigned, int pending) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildProductionStatCard("COMPLETED", completed.toString(), Icons.verified_user_rounded, const Color(0xFF10B981))),
            const SizedBox(width: 16),
            Expanded(child: _buildProductionStatCard("ASSIGNED", assigned.toString(), Icons.assignment_rounded, const Color(0xFF2563EB))),
          ],
        ),
        const SizedBox(height: 16),
        _buildProductionStatCard("PENDING APPROVAL", pending.toString(), Icons.hourglass_empty_rounded, const Color(0xFFF59E0B), isFullWidth: true),
      ],
    );
  }

  Widget _buildProductionStatCard(String label, String value, IconData icon, Color color, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 24),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
          Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
          label: const Text("VIEW ALL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF2563EB)),
        ),
      ],
    );
  }

  Widget _buildStaggeredHorizontalTasks(BuildContext context, List<Job> jobs) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 400.0 : screenWidth * 0.85;

    if (jobs.isEmpty) {
      return const SizedBox(
        height: 330, 
        child: Center(child: Text("No assigned projects for today.", style: TextStyle(color: Colors.grey, fontSize: 16))),
      );
    }

    return SizedBox(
      height: 330,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: jobs.length,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.only(right: 16, left: index == 0 ? 0 : 0),
          child: JobCard(
            index: index,
            width: cardWidth,
            job: jobs[index],
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 700),
                reverseTransitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                  opacity: animation,
                  child: JobDetailScreen(job: jobs[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}

class UberJobPopup extends ConsumerStatefulWidget {
  final IncomingJobRequest request;
  const UberJobPopup({super.key, required this.request});

  @override
  ConsumerState<UberJobPopup> createState() => _UberJobPopupState();
}

class _UberJobPopupState extends ConsumerState<UberJobPopup> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsLeft = 30;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _calculateSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateSecondsLeft();
        });
        if (_secondsLeft <= 0) {
          _declineAndClose();
        }
      }
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _calculateSecondsLeft() {
    final diff = widget.request.expiresAt.difference(DateTime.now()).inSeconds;
    _secondsLeft = diff > 0 ? diff : 0;
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    final api = ref.read(apiServiceProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
      await api.acceptJobRequest(widget.request.jobId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ref.read(incomingRequestsProvider.notifier).removeRequest(widget.request.jobId);
        ref.invalidate(jobsProvider(null));
        Navigator.pop(context); // Close full screen popup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Job request accepted successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        Navigator.pop(context); // Close popup
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _declineAndClose() async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.rejectJobRequest(widget.request.jobId, reason: 'Declined by technician');
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
    if (mounted) {
      ref.read(incomingRequestsProvider.notifier).removeRequest(widget.request.jobId);
      Navigator.pop(context); // Close popup
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsLeft / 30.0;

    return PopScope(
      canPop: false, // Prevent dismissing by back button
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Premium Dark slate
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.electric_bolt_rounded,
                      color: Colors.amber,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'NEW JOB REQUEST',
                  style: TextStyle(
                    color: Color(0xFF818CF8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.request.serviceName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.extrabold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Customer: ${widget.request.customerName}',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                // Estimated Earnings Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ESTIMATED EARNINGS',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${widget.request.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Location Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF334155).withOpacity(0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFF818CF8)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.request.address,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Distance: ${widget.request.distanceKm} km away',
                                  style: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Color(0xFF818CF8), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Schedule: ${widget.request.date} · ${widget.request.timeSlot}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Circular Countdown Timer
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: const Color(0xFF334155),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    ),
                    Text(
                      '${_secondsLeft}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _declineAndClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.redAccent, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'REJECT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981), // Emerald green
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                        ),
                        child: const Text(
                          'ACCEPT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
