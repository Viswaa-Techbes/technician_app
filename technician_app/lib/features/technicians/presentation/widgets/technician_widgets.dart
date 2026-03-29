import 'package:flutter/material.dart';
import '../../domain/entities/technician_entity.dart';

// ─── Avatar Widget ────────────────────────────────────────────────────────────

class TechnicianAvatar extends StatelessWidget {
  final String initials;
  final double radius;
  final Color? backgroundColor;

  const TechnicianAvatar({
    super.key,
    required this.initials,
    this.radius = 22,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFF10B981),
      const Color(0xFFF43F5E),
      const Color(0xFF8B5CF6),
    ];
    final color = backgroundColor ?? colors[initials.codeUnitAt(0) % colors.length];

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class TechStatusBadge extends StatelessWidget {
  final TechnicianStatus status;

  const TechStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: config.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: config.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(TechnicianStatus status) {
    switch (status) {
      case TechnicianStatus.available:
        return const _StatusConfig(
          background: Color(0xFFD1FAE5),
          text: Color(0xFF166534),
          dot: Color(0xFF10B981),
        );
      case TechnicianStatus.onJob:
        return const _StatusConfig(
          background: Color(0xFFE0F2FE),
          text: Color(0xFF0369A1),
          dot: Color(0xFF06B6D4),
        );
      case TechnicianStatus.offline:
        return const _StatusConfig(
          background: Color(0xFFE2E8F0),
          text: Color(0xFF475569),
          dot: Color(0xFF64748B),
        );
    }
  }
}

class _StatusConfig {
  final Color background;
  final Color text;
  final Color dot;
  const _StatusConfig({required this.background, required this.text, required this.dot});
}

// ─── Star Rating ──────────────────────────────────────────────────────────────

class StarRating extends StatelessWidget {
  final double rating;

  const StarRating({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}

// ─── Technician Card ──────────────────────────────────────────────────────────

class TechnicianCard extends StatelessWidget {
  final TechnicianEntity technician;
  final VoidCallback? onTap;

  const TechnicianCard({
    super.key,
    required this.technician,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF64748B).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TechnicianAvatar(initials: technician.avatarInitials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          technician.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          technician.skill,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TechStatusBadge(status: technician.status),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                color: const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MetaChip(icon: Icons.work_history_rounded, label: technician.experience),
                  const SizedBox(width: 14),
                  _MetaChip(icon: Icons.task_alt_rounded, label: '${technician.assignedTasksCount} tasks'),
                  const Spacer(),
                  StarRating(rating: technician.rating),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Filter Bar ───────────────────────────────────────────────────────────────

class TechFilterBar extends StatelessWidget {
  final String searchQuery;
  final String? selectedSkill;
  final TechnicianStatus? selectedStatus;
  final List<String> skillCategories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSkillChanged;
  final ValueChanged<TechnicianStatus?> onStatusChanged;
  final VoidCallback onClearFilters;

  const TechFilterBar({
    super.key,
    required this.searchQuery,
    required this.selectedSkill,
    required this.selectedStatus,
    required this.skillCategories,
    required this.onSearchChanged,
    required this.onSkillChanged,
    required this.onStatusChanged,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasFilters = selectedSkill != null || selectedStatus != null || searchQuery.isNotEmpty;

    return Column(
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF64748B).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            onChanged: onSearchChanged,
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: const InputDecoration(
              hintText: 'Search technicians by name or skill…',
              hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Status chips
              _StatusChip(label: 'All', selected: selectedStatus == null, onTap: () => onStatusChanged(null)),
              const SizedBox(width: 8),
              _StatusChip(
                label: TechnicianStatus.available.label,
                selected: selectedStatus == TechnicianStatus.available,
                color: const Color(0xFF10B981),
                onTap: () => onStatusChanged(selectedStatus == TechnicianStatus.available ? null : TechnicianStatus.available),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: TechnicianStatus.onJob.label,
                selected: selectedStatus == TechnicianStatus.onJob,
                color: const Color(0xFF06B6D4),
                onTap: () => onStatusChanged(selectedStatus == TechnicianStatus.onJob ? null : TechnicianStatus.onJob),
              ),
              const SizedBox(width: 8),
              _StatusChip(
                label: TechnicianStatus.offline.label,
                selected: selectedStatus == TechnicianStatus.offline,
                color: const Color(0xFF64748B),
                onTap: () => onStatusChanged(selectedStatus == TechnicianStatus.offline ? null : TechnicianStatus.offline),
              ),
              if (skillCategories.isNotEmpty) ...[
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 16),
                ...skillCategories.map((skill) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SkillChip(
                    label: skill,
                    selected: selectedSkill == skill,
                    onTap: () => onSkillChanged(selectedSkill == skill ? null : skill),
                  ),
                )),
              ],
              if (hasFilters) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Clear', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF43F5E),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.selected, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? const Color(0xFF6366F1);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? activeColor : const Color(0xFFE2E8F0)),
          boxShadow: selected
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SkillChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) const Icon(Icons.check, size: 12, color: Color(0xFF6366F1)),
            if (selected) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Stats Bar ────────────────────────────────────────────────────────

class TechniciansSummaryBar extends StatelessWidget {
  final List<TechnicianEntity> technicians;

  const TechniciansSummaryBar({super.key, required this.technicians});

  @override
  Widget build(BuildContext context) {
    final available = technicians.where((t) => t.status == TechnicianStatus.available).length;
    final onJob = technicians.where((t) => t.status == TechnicianStatus.onJob).length;
    final offline = technicians.where((t) => t.status == TechnicianStatus.offline).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _SummaryItem(count: technicians.length, label: 'Total', icon: Icons.engineering),
          _Divider(),
          _SummaryItem(count: available, label: 'Available', icon: Icons.check_circle_outline),
          _Divider(),
          _SummaryItem(count: onJob, label: 'On Job', icon: Icons.work_outline),
          _Divider(),
          _SummaryItem(count: offline, label: 'Offline', icon: Icons.power_off_outlined),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;

  const _SummaryItem({required this.count, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(height: 4),
          Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2), margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}
