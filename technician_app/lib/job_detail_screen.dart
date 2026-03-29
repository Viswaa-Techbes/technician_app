import 'package:flutter/material.dart';
import 'dart:async';
import 'models.dart';
import 'widgets.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late JobStatus _currentStatus;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.job.status;
    if (_currentStatus == JobStatus.inProgress) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isRunning = false);
    _timer?.cancel();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 150),
                  child: Column(
                    children: [
                      _buildTimerSection(),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 32),
                            _buildCustomerCard(),
                            _buildSectionHeader('Project Site Location'),
                            _buildMapCard(),
                            _buildSectionHeader('Technical Documentation'),
                            _buildPhotoGrid(),
                            _buildSectionHeader('Field Observations'),
                            _buildNotesArea(),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          _buildBottomActionDock(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      title: Hero(
        tag: 'job-id-${widget.job.id}',
        child: Material(
          color: Colors.transparent,
          child: Text(
            'PROJECT #${widget.job.id}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF0F172A),
              fontSize: 14,
            ),
          ),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildTimerSection() {
    final hours = _elapsed.inHours.toString().padLeft(2, '0');
    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Hero(
      tag: 'job-card-${widget.job.id}',
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(44)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 48),
          child: Column(
            children: [
              StatusChip(status: _currentStatus),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _buildTimeSegment(hours, "HRS"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(minutes, "MIN"),
                  _buildTimeSeparator(),
                  _buildTimeSegment(seconds, "SEC"),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _isRunning ? "TASK SESSION ACTIVE" : "SESSION PAUSED",
                style: TextStyle(
                  color: _isRunning ? const Color(0xFF2563EB) : const Color(0xFFF59E0B),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSegment(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: _isRunning ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
            letterSpacing: -1,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade400,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 24),
      child: Text(
        ":",
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade200,
        ),
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: Color(0xFF1E3A8A), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.job.customerName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const Text(
                      "Corporate Client",
                      style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.phone_in_talk_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F9FF),
                  foregroundColor: const Color(0xFF0369A1),
                  padding: const EdgeInsets.all(14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 40, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF94A3B8),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.explore_rounded, size: 80, color: Colors.blue.shade900),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: CustomButton(
              label: "NAVIGATION",
              onPressed: () {},
              isFullWidth: false,
              icon: Icons.near_me_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Row(
      children: [
        Expanded(child: _buildPhotoBox("SITE BEFORE", Icons.history_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildPhotoBox("SITE AFTER", Icons.verified_rounded)),
      ],
    );
  }

  Widget _buildPhotoBox(String label, IconData icon) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 24),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildNotesArea() {
    return TextField(
      maxLines: 4,
      decoration: InputDecoration(
        hintText: "Enter detailed site observations...",
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: const Color(0xFFF1F5F9))),
        contentPadding: const EdgeInsets.all(24),
      ),
    );
  }

  Widget _buildBottomActionDock() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 30, offset: const Offset(0, -10)),
          ],
        ),
        child: _buildActionButtonForStatus(),
      ),
    );
  }

  Widget _buildActionButtonForStatus() {
    switch (_currentStatus) {
      case JobStatus.pendingApproval:
        return CustomButton(
          label: "WAITING FOR APPROVAL",
          onPressed: () {},
          color: const Color(0xFF8B5CF6),
          icon: Icons.hourglass_bottom_rounded,
        );
      case JobStatus.completed:
        return CustomButton(
          label: "PROJECT COMPLETED",
          onPressed: () {},
          color: const Color(0xFF10B981),
          icon: Icons.verified_rounded,
        );
      case JobStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: _isRunning
                  ? CustomButton(label: "PAUSE", onPressed: _pauseTimer, color: const Color(0xFFF59E0B), icon: Icons.pause_circle_rounded)
                  : CustomButton(label: "START", onPressed: _startTimer, color: const Color(0xFF2563EB), icon: Icons.play_circle_rounded),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                label: "REQUEST COMPLETION",
                onPressed: () {
                  _pauseTimer();
                  setState(() => _currentStatus = JobStatus.pendingApproval);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Completion request sent to manager.")),
                  );
                },
                color: const Color(0xFF8B5CF6),
                icon: Icons.send_rounded,
              ),
            ),
          ],
        );
      case JobStatus.assigned:
        return CustomButton(
          label: "START SESSION",
          onPressed: () => setState(() {
            _currentStatus = JobStatus.inProgress;
            _startTimer();
          }),
          color: const Color(0xFF2563EB),
          icon: Icons.play_circle_rounded,
        );
    }
  }
}
