import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/technician_entity.dart';
import '../providers/technicians_provider.dart';
import '../widgets/technician_widgets.dart';

class TechniciansScreen extends ConsumerStatefulWidget {
  const TechniciansScreen({super.key});

  @override
  ConsumerState<TechniciansScreen> createState() => _TechniciansScreenState();
}

class _TechniciansScreenState extends ConsumerState<TechniciansScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(techniciansProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(techniciansProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        final isTablet = constraints.maxWidth >= 600 && !isDesktop;
        final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(state, isDesktop),
            Expanded(
              child: _buildBody(state, crossAxisCount, isDesktop),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(TechniciansState state, bool isDesktop) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(isDesktop ? 28 : 16, 20, isDesktop ? 28 : 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician Management',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage, track and assign field technicians',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Add Technician', style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (state.technicians.isNotEmpty)
            TechniciansSummaryBar(technicians: state.technicians),
          if (state.technicians.isNotEmpty) const SizedBox(height: 18),
          TechFilterBar(
            searchQuery: state.params.searchQuery ?? '',
            selectedSkill: state.params.skillFilter,
            selectedStatus: state.params.statusFilter,
            skillCategories: state.skillCategories,
            onSearchChanged: (q) => ref.read(techniciansProvider.notifier).search(q),
            onSkillChanged: (s) => ref.read(techniciansProvider.notifier).filterBySkill(s),
            onStatusChanged: (s) => ref.read(techniciansProvider.notifier).filterByStatus(s),
            onClearFilters: () => ref.read(techniciansProvider.notifier).clearFilters(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBody(TechniciansState state, int crossAxisCount, bool isDesktop) {
    if (state.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF6366F1)),
            SizedBox(height: 16),
            Text('Loading technicians…', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 36, color: Color(0xFFF43F5E)),
              ),
              const SizedBox(height: 16),
              const Text('Failed to Load', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ref.read(techniciansProvider.notifier).loadTechnicians(refresh: true),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.technicians.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.engineering, size: 40, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 16),
            const Text('No Technicians Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            const Text('Try adjusting your search or filter criteria', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    final padding = EdgeInsets.fromLTRB(isDesktop ? 28 : 16, 16, isDesktop ? 28 : 16, 24);

    if (crossAxisCount == 1) {
      return RefreshIndicator(
        onRefresh: () => ref.read(techniciansProvider.notifier).loadTechnicians(refresh: true),
        color: const Color(0xFF6366F1),
        child: ListView.builder(
          controller: _scrollController,
          padding: padding,
          itemCount: state.technicians.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == state.technicians.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TechnicianCard(
                technician: state.technicians[index],
                onTap: () => _showTechnicianDetail(context, state.technicians[index]),
              ),
            );
          },
        ),
      );
    }

    // Grid for tablet / desktop
    return RefreshIndicator(
      onRefresh: () => ref.read(techniciansProvider.notifier).loadTechnicians(refresh: true),
      color: const Color(0xFF6366F1),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: padding,
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return TechnicianCard(
                    technician: state.technicians[index],
                    onTap: () => _showTechnicianDetail(context, state.technicians[index]),
                  );
                },
                childCount: state.technicians.length,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: crossAxisCount == 3 ? 1.55 : 1.7,
              ),
            ),
          ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
              ),
            ),
          if (state.hasReachedEnd && state.technicians.isNotEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    '— All technicians loaded —',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showTechnicianDetail(BuildContext context, TechnicianEntity tech) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TechnicianDetailSheet(technician: tech),
    );
  }
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────────

class _TechnicianDetailSheet extends StatelessWidget {
  final TechnicianEntity technician;

  const _TechnicianDetailSheet({required this.technician});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(99)),
                ),
                const SizedBox(height: 24),
                TechnicianAvatar(initials: technician.avatarInitials, radius: 34),
                const SizedBox(height: 14),
                Text(technician.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(technician.skill, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                TechStatusBadge(status: technician.status),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      _DetailRow(Icons.phone_rounded, 'Phone', technician.phone),
                      _DetailRow(Icons.work_history_rounded, 'Experience', technician.experience),
                      _DetailRow(Icons.task_alt_rounded, 'Assigned Tasks', '${technician.assignedTasksCount} jobs'),
                      _DetailRow(Icons.star_rounded, 'Rating', '${technician.rating.toStringAsFixed(1)} / 5.0'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.message_outlined, size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF6366F1),
                            side: const BorderSide(color: Color(0xFF6366F1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
                          label: const Text('Assign Job'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
