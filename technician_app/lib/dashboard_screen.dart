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
      
      // Update via REST API
      await ref.read(apiServiceProvider).updateLocation(pos.latitude, pos.longitude, isOnline: true);
      
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
                const SizedBox(height: 32),
                _buildProductionSummary(completedCount, assignedCount, pendingCount),
                const SizedBox(height: 48),
                _buildSectionHeader("ACTIVE PROJECTS"),
                const SizedBox(height: 16),
                _buildStaggeredHorizontalTasks(context, jobs),
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
