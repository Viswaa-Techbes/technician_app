import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

enum TimerStatus { pending, inProgress, paused, completed }

class JobTimerWidget extends ConsumerStatefulWidget {
  final String jobId;
  final String initialStatus; // pending, in_progress, paused, completed
  final int initialDurationSeconds;

  const JobTimerWidget({
    super.key,
    required this.jobId,
    required this.initialStatus,
    this.initialDurationSeconds = 0,
  });

  @override
  ConsumerState<JobTimerWidget> createState() => _JobTimerWidgetState();
}

class _JobTimerWidgetState extends ConsumerState<JobTimerWidget> {
  late TimerStatus _status;
  late int _elapsedSeconds;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _elapsedSeconds = widget.initialDurationSeconds;
    
    switch (widget.initialStatus) {
      case 'in_progress':
        _status = TimerStatus.inProgress;
        _startLocalTimer();
        break;
      case 'paused':
        _status = TimerStatus.paused;
        break;
      case 'completed':
        _status = TimerStatus.completed;
        break;
      default:
        _status = TimerStatus.pending;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopLocalTimer() {
    _timer?.cancel();
  }

  Future<bool> _updateJobBackend(String action) async {
    setState(() => _isLoading = true);
    try {
      final session = ref.read(authProvider);
      if (session == null || session.token.isEmpty) {
        throw const ApiException('Please log in again to update the task.');
      }

      final nextStatus = switch (action) {
        'start' || 'resume' => 'in_progress',
        'pause' => 'pending',
        'complete' => 'completed',
        _ => throw const ApiException('Unsupported timer action.'),
      };

      await ref.read(apiClientProvider).patchJson(
            '/technician/tasks/${widget.jobId}/status',
            token: session.token,
            body: <String, dynamic>{'status': nextStatus},
          );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onStart() async {
    final updated = await _updateJobBackend('start');
    if (!updated || !mounted) return;
    setState(() {
      _status = TimerStatus.inProgress;
    });
    _startLocalTimer();
  }

  void _onPause() async {
    final updated = await _updateJobBackend('pause');
    if (!updated || !mounted) return;
    setState(() {
      _status = TimerStatus.paused;
    });
    _stopLocalTimer();
  }

  void _onResume() async {
    final updated = await _updateJobBackend('resume');
    if (!updated || !mounted) return;
    setState(() {
      _status = TimerStatus.inProgress;
    });
    _startLocalTimer();
  }

  void _onComplete() async {
    final updated = await _updateJobBackend('complete');
    if (!updated || !mounted) return;
    setState(() {
      _status = TimerStatus.completed;
    });
    _stopLocalTimer();
  }

  String _formatDuration(int seconds) {
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor() {
    switch (_status) {
      case TimerStatus.pending:
        return const Color(0xFF94A3B8); // Gray
      case TimerStatus.inProgress:
        return const Color(0xFF10B981); // Green
      case TimerStatus.paused:
        return const Color(0xFFF59E0B); // Orange
      case TimerStatus.completed:
        return const Color(0xFF3B82F6); // Blue
    }
  }

  String _getStatusText() {
    switch (_status) {
      case TimerStatus.pending:
        return "READY TO START";
      case TimerStatus.inProgress:
        return "IN PROGRESS";
      case TimerStatus.paused:
        return "PAUSED";
      case TimerStatus.completed:
        return "COMPLETED";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header / Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusText(),
              style: TextStyle(
                color: _getStatusColor(),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Digital Timer
          Text(
            _formatDuration(_elapsedSeconds),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontVariations: [FontVariation('tnum', 1)], // requires matching font or relies on system
              letterSpacing: 2,
              color: Color(0xFF1E293B),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Controls
          if (_isLoading)
            const CircularProgressIndicator()
          else
            _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    if (_status == TimerStatus.completed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: _getStatusColor(), size: 24),
          const SizedBox(width: 8),
          Text(
            "JOB RECORDED",
            style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.w800),
          )
        ],
      );
    }

    if (_status == TimerStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _onStart,
          icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
          label: const Text("START JOB", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _status == TimerStatus.inProgress 
              ? _buildControlButton("PAUSE", Icons.pause_rounded, const Color(0xFFF59E0B), _onPause)
              : _buildControlButton("RESUME", Icons.play_arrow_rounded, const Color(0xFF10B981), _onResume),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildControlButton("COMPLETE", Icons.stop_rounded, const Color(0xFF3B82F6), _onComplete),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ActionChip(
      onPressed: onPressed,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      label: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }
}
