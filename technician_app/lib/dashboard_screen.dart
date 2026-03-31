import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'widgets.dart';
import 'services/mock_data_service.dart';
import 'job_detail_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'login_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isOnDuty = false;
  List<Job> _todaysJobs = [];
  bool _isLoading = true;
  String _userName = "Technician";
  int _completedCount = 0;
  int _assignedCount = 0;
  int _pendingCount = 0;
  final _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final session = ref.read(authProvider);
    if (session == null) return;
    
    _userName = session.name;

    if (MockDataService.useMock) {
      final allJobs = await MockDataService().getJobs();
      final myJobs = allJobs.where((j) => j.technicianId == session.id || session.id == 'tech1').toList();
      
      if (mounted) {
        setState(() {
          _todaysJobs = myJobs;
          _completedCount = myJobs.where((j) => j.status == JobStatus.completed).length;
          _assignedCount = myJobs.where((j) => j.status == JobStatus.assigned || j.status == JobStatus.inProgress).length;
          _pendingCount = myJobs.where((j) => j.status == JobStatus.pendingApproval).length;
          _isOnDuty = true; // Default to online for demo
          _isLoading = false;
        });
      }
      return;
    }

    // Listen to real-time status... [Firestore Code]
    _db.collection('technicians').doc(session.id).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        setState(() => _isOnDuty = doc.data()?['isOnline'] ?? false);
      }
    });

    // Listen to job counts... [Firestore Code]
    _db.collection('projects')
        .where('technicianId', isEqualTo: session.id)
        .snapshots().listen((snapshot) {
      if (mounted) {
        int completed = 0;
        int assigned = 0;
        int pending = 0;
        
        List<Job> jobs = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final statusStr = data['status'] as String? ?? 'assigned';
          
          JobStatus status = JobStatus.assigned;
          if (statusStr == 'in_progress') {
            status = JobStatus.inProgress;
            assigned++;
          } else if (statusStr == 'completed') {
            status = JobStatus.completed;
            completed++;
          } else if (statusStr == 'pending') {
            status = JobStatus.pendingApproval;
            pending++;
          } else {
            assigned++;
          }

          jobs.add(Job(
            id: doc.id,
            serviceName: data['serviceName'] ?? 'Task',
            customerName: data['customerName'] ?? 'System',
            customerPhone: data['customerPhone'] ?? 'N/A',
            address: data['address'] ?? 'See Notes',
            time: data['time'] ?? 'Anytime',
            status: status,
            notes: data['notes'] ?? '',
          ));
        }

        setState(() {
          _completedCount = completed;
          _assignedCount = assigned;
          _pendingCount = pending;
          _todaysJobs = jobs;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _toggleDuty(bool val) async {
    final session = ref.read(authProvider);
    if (session == null) return;

    await _db.collection('technicians').doc(session.id).set({
      'isOnline': val,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'name': session.name,
    }, SetOptions(merge: true));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildProductionHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildAnimatedDutyToggle(),
                  const SizedBox(height: 32),
                  _buildProductionSummary(),
                  const SizedBox(height: 48),
                  _buildSectionHeader("ACTIVE PROJECTS"),
                  const SizedBox(height: 16),
                  _buildStaggeredHorizontalTasks(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionHeader() {
    return SliverAppBar(
      expandedHeight: 220,
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
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                                  height: 40,
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
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                          ),
                          Text(
                            _userName,
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5),
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
                onChanged: (val) => setState(() => _isOnDuty = val),
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

  Widget _buildProductionSummary() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildProductionStatCard("COMPLETED", _completedCount.toString(), Icons.verified_user_rounded, const Color(0xFF10B981))),
            const SizedBox(width: 16),
            Expanded(child: _buildProductionStatCard("ASSIGNED", _assignedCount.toString(), Icons.assignment_rounded, const Color(0xFF2563EB))),
          ],
        ),
        const SizedBox(height: 16),
        _buildProductionStatCard("PENDING APPROVAL", _pendingCount.toString(), Icons.hourglass_empty_rounded, const Color(0xFFF59E0B), isFullWidth: true),
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

  Widget _buildStaggeredHorizontalTasks() {
    if (_isLoading) {
      return const SizedBox(height: 280, child: Center(child: CircularProgressIndicator()));
    }
    if (_todaysJobs.isEmpty) {
      return const SizedBox(
        height: 280, 
        child: Center(child: Text("No assigned projects for today.", style: TextStyle(color: Colors.grey, fontSize: 16))),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _todaysJobs.length,
        itemBuilder: (context, index) => JobCard(
          index: index,
          width: 330,
          job: _todaysJobs[index],
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 700),
              reverseTransitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
                opacity: animation,
                child: JobDetailScreen(job: _todaysJobs[index]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
