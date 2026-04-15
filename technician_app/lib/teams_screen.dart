import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'providers/live_technicians_provider.dart';
import 'technician_detail_screen.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync = ref.watch(liveTechniciansProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text("FIELD TEAMS")),
      body: techniciansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Failed to load teams: $error')),
        data: (allTechs) {
          if (allTechs.isEmpty) {
            return const Center(child: Text("No technicians registered", style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(liveTechniciansProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: allTechs.length,
              itemBuilder: (context, index) {
                final tech = allTechs[index];
                return _buildTechnicianCard(context, tech);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTechnicianCard(BuildContext context, Technician tech) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TechnicianDetailScreen(technician: tech)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            _buildStatusAvatar(tech),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tech.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  _buildSubInfo(tech),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TechnicianDetailScreen(technician: tech)),
              ),
              icon: const Icon(Icons.chevron_right_rounded),
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusAvatar(Technician tech) {
    Color color = Colors.grey;
    if (tech.isOnline) color = const Color(0xFF10B981);
    if (tech.status == TechnicianStatus.busy) color = const Color(0xFFEA580C);

    return Stack(
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFF1F5F9),
          child: Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 30),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubInfo(Technician tech) {
    String text = "Offline";
    Color color = Colors.grey;

    if (tech.status == TechnicianStatus.busy) {
      text = "Working on #${tech.currentJobId}";
      color = const Color(0xFFEA580C);
    } else if (tech.isOnline) {
      text = "Available for job";
      color = const Color(0xFF10B981);
    }

    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12),
    );
  }
}
