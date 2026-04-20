import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/attendance_provider.dart';

class AttendanceAdminScreen extends ConsumerWidget {
  const AttendanceAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Daily Attendance Overview', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: attendanceAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (users) {
                final total = users.length;
                final present = users.where((u) => u['status'] == 'present').length;
                final absent = total - present;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _SummaryCard(title: 'Total Technicians', value: '$total', color: Colors.blue)),
                        const SizedBox(width: 16),
                        Expanded(child: _SummaryCard(title: 'Present Today', value: '$present', color: Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(child: _SummaryCard(title: 'Absent Today', value: '$absent', color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
                          ],
                        ),
                        child: ListView.separated(
                          itemCount: users.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final u = users[index];
                            final isPresent = u['status'] == 'present';
                            final loginStr = u['loginTime'] != null ? _formatTime(u['loginTime']) : 'N/A';
                            final logoutStr = u['logoutTime'] != null ? _formatTime(u['logoutTime']) : '--';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isPresent ? Colors.green.shade100 : Colors.red.shade100,
                                child: Icon(
                                  isPresent ? Icons.check_circle : Icons.cancel,
                                  color: isPresent ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(u['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Login: $loginStr  |  Logout: $logoutStr'),
                              trailing: Chip(
                                backgroundColor: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                                label: Text(
                                  isPresent ? 'PRESENT' : 'ABSENT',
                                  style: TextStyle(
                                    color: isPresent ? Colors.green.shade700 : Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final d = DateTime.parse(isoString).toLocal();
      int hr = d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour);
      final mn = d.minute.toString().padLeft(2, '0');
      final amPm = d.hour >= 12 ? 'PM' : 'AM';
      return '$hr:$mn $amPm';
    } catch (_) {
      return isoString;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
