import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/incoming_requests_provider.dart';
import 'services/api_service.dart';
import 'providers/job_providers.dart';

class JobRequestScreen extends ConsumerStatefulWidget {
  const JobRequestScreen({super.key});

  @override
  ConsumerState<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends ConsumerState<JobRequestScreen> {
  Timer? _expiryCheckTimer;

  @override
  void initState() {
    super.initState();
    // Periodically prune expired requests and rebuild
    _expiryCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      ref.read(incomingRequestsProvider.notifier).clearExpired();
    });
  }

  @override
  void dispose() {
    _expiryCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _acceptRequest(IncomingJobRequest req) async {
    final api = ref.read(apiServiceProvider);
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      await api.acceptJobRequest(req.jobId);
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Job request accepted successfully!'), backgroundColor: Colors.green),
        );
        ref.read(incomingRequestsProvider.notifier).removeRequest(req.jobId);
        ref.invalidate(jobsProvider(null));
        Navigator.pop(context); // Return to dashboard
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(IncomingJobRequest req) async {
    final api = ref.read(apiServiceProvider);
    try {
      await api.rejectJobRequest(req.jobId, reason: 'Declined by technician');
      ref.read(incomingRequestsProvider.notifier).removeRequest(req.jobId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job request declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to decline request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(incomingRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Incoming Job Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_find_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Waiting for new job dispatches...', style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _JobRequestCard(
                  request: req,
                  onAccept: () => _acceptRequest(req),
                  onReject: () => _rejectRequest(req),
                );
              },
            ),
    );
  }
}

class _JobRequestCard extends StatefulWidget {
  final IncomingJobRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _JobRequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_JobRequestCard> createState() => _JobRequestCardState();
}

class _JobRequestCardState extends State<_JobRequestCard> {
  late Timer _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _calculateSecondsLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateSecondsLeft();
        });
      }
    });
  }

  void _calculateSecondsLeft() {
    final diff = widget.request.expiresAt.difference(DateTime.now()).inSeconds;
    _secondsLeft = diff > 0 ? diff : 0;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'NEW REQUEST',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_secondsLeft}s left',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.request.serviceName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.map_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.request.address} (${widget.request.distanceKm} km away)',
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  '${widget.request.date} · ${widget.request.timeSlot}',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL EARNINGS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Text(
                      '₹${widget.request.amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.black, color: Colors.black),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: widget.onReject,
                      child: const Text('DECLINE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: widget.onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('ACCEPT', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
