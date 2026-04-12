import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets.dart';
import 'models.dart';
import 'services/api_service.dart';
import 'completion_requests_screen.dart';
import 'assign_job_screen.dart';
import 'project_detail_screen.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/reviews/screens/manager_reviews_screen.dart';
import 'field_map_screen.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider);
    final userName = session?.name ?? "Manager";
    final api = ref.watch(apiServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, userName, ref),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("OPERATIONAL OVERVIEW"),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: api.getDashboard(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final summary = snapshot.data?['summary'] ?? {};
                      final total = summary['totalRequests'] ?? 0;
                      final active = summary['inProgress'] ?? 0;
                      final completed = summary['completedJobs'] ?? 0;
                      final revenue = (summary['totalRevenue'] ?? 0).toString();
                      return _buildOverviewGrid(total, active, completed, revenue);
                    },
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("LIVE TRACKING"),
                  const SizedBox(height: 16),
                  const LiveLocationCard(),
                  const SizedBox(height: 32),
                  _buildSectionHeader("CRITICAL ACTIONS"),
                  FutureBuilder<Map<String, dynamic>>(
                    future: api.getDashboard(),
                    builder: (context, snapshot) {
                      final pendingCount = snapshot.data?['summary']?['pendingRequests'] ?? 0;
                      return Column(
                        children: [
                          _buildActionCard(
                            context,
                            "Completion Requests",
                            "$pendingCount technicians waiting for approval",
                            Icons.pending_actions_rounded,
                            const Color(0xFF8B5CF6),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CompletionRequestsScreen()),
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
                              MaterialPageRoute(builder: (context) => const AssignJobScreen()),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActionCard(
                            context,
                            "Technician Reviews",
                            "Monitor performance and client feedback",
                            Icons.star_rate_rounded,
                            const Color(0xFFF59E0B),
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ManagerReviewsScreen()),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader("RECENT ACTIVITY"),
                  const SizedBox(height: 16),
                  _buildRecentJobsList(context, api),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String userName, WidgetRef ref) {
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
                  style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  userName,
                  style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
                ),
                Hero(tag: 'techbes-logo', child: Image.asset('assets/logos/logo.png', height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B))),
                  Text(subtitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentJobsList(BuildContext context, ApiService api) {
    return FutureBuilder<List<Job>>(
      future: api.getJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final allJobs = snapshot.data ?? [];
        if (allJobs.isEmpty) return const Center(child: Text("No recent activity"));
        
        return Column(
          children: allJobs.take(5).map((job) => JobCard(
            job: job,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(job: job))),
          )).toList(),
        );
      },
    );
  }

  Widget _buildOverviewGrid(int total, int active, int completed, String revenue) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        SummaryCard(label: "TOTAL JOBS", value: total.toString(), icon: Icons.assignment_rounded),
        SummaryCard(label: "ACTIVE NOW", value: active.toString(), icon: Icons.bolt_rounded),
        SummaryCard(label: "COMPLETED", value: completed.toString(), icon: Icons.check_circle_rounded),
        SummaryCard(label: "REVENUE", value: "\$$revenue", icon: Icons.payments_rounded),
      ],
    );
  }
}

class LiveLocationCard extends ConsumerWidget {
  const LiveLocationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(apiServiceProvider);
    return FutureBuilder<List<Technician>>(
      future: api.getTechnicians(),
      builder: (context, snapshot) {
        final activeTechs = (snapshot.data ?? []).where((t) => t.isOnline).toList();
        return _buildContent(context, activeTechs.length);
      },
    );
  }

  Widget _buildContent(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FieldMapScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count == 0 ? "No Technicians Active" : "$count Active Now",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count == 0 ? "All field staff are currently offline" : "Real-time status monitoring active",
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

