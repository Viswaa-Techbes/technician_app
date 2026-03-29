import 'package:flutter/material.dart';
import 'widgets.dart';
import 'completion_requests_screen.dart';
import 'assign_job_screen.dart';
import 'project_detail_screen.dart';
import 'demo_data.dart';
import 'dart:async';
import 'location_service.dart';

class ManagerDashboardScreen extends StatelessWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("OPERATIONAL OVERVIEW"),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: DemoData.instance,
                    builder: (context, _) {
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.9,
                        children: [
                          SummaryCard(
                            label: "TOTAL JOBS",
                            value: DemoData.instance.totalJobs.toString(),
                            icon: Icons.assignment_rounded,
                          ),
                          SummaryCard(
                            label: "ACTIVE NOW",
                            value: DemoData.instance.activeJobs.toString(),
                            icon: Icons.bolt_rounded,
                          ),
                          SummaryCard(
                            label: "COMPLETED",
                            value: DemoData.instance.completedJobs.toString(),
                            icon: Icons.check_circle_rounded,
                          ),
                          const SummaryCard(
                            label: "REVENUE",
                            value: "4.2k",
                            icon: Icons.payments_rounded,
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("LIVE TRACKING"),
                  const SizedBox(height: 16),
                  const LiveLocationCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("CRITICAL ACTIONS"),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    "Completion Requests",
                    "3 technicians waiting for approval",
                    Icons.pending_actions_rounded,
                    const Color(0xFF8B5CF6),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CompletionRequestsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildActionCard(
                    context,
                    "Assign New Project",
                    "Create and dispatch a new project",
                    Icons.add_task_rounded,
                    const Color(0xFF1E3A8A),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AssignJobScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("RECENT ACTIVITY"),
                  const SizedBox(height: 16),
                  _buildRecentJobsList(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back,",
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  "Manager Mike",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            Hero(
              tag: 'techbes-logo',
              child: Image.asset('assets/logos/logo.png', height: 40),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.w900,
        fontSize: 11,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsList(BuildContext context) {
    return ListenableBuilder(
      listenable: DemoData.instance,
      builder: (context, _) {
        final recentJobs = DemoData.instance.recentJobs;
        return Column(
          children: recentJobs
              .map((job) => JobCard(
                    job: job,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDetailScreen(job: job),
                      ),
                    ),
                  ))
              .toList(),
        );
      }
    );
  }
}

class LiveLocationCard extends StatefulWidget {
  const LiveLocationCard({super.key});

  @override
  State<LiveLocationCard> createState() => _LiveLocationCardState();
}

class _LiveLocationCardState extends State<LiveLocationCard> {
  Timer? _timer;
  Map<String, dynamic>? _locationData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchLocation());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Simulating fetching location for "T1" (Alex Brown)
    final data = await LocationService.getLiveLocation("T1");
    if (mounted) {
      setState(() {
        if (data != null) {
          _locationData = data;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Alex Brown (Active)",
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                if (_isLoading && _locationData == null)
                  const Text("Locating...", style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600))
                else if (_locationData != null)
                  Text(
                    "Lat: ${_locationData!['latitude'].toStringAsFixed(4)}, Lng: ${_locationData!['longitude'].toStringAsFixed(4)}",
                    style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700, fontSize: 13),
                  )
                else
                  const Text("Waiting for signal...", style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: _fetchLocation,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
          )
        ],
      ),
    );
  }
}

