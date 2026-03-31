import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/job_description_providers.dart';
import '../models/job_description_model.dart';

/// Embeddable section that displays a job description with file list.
/// Used inside the Technician's job detail and Manager's project detail screens.
class JobDescriptionSection extends ConsumerWidget {
  final String projectId;

  const JobDescriptionSection({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobDescAsync = ref.watch(jobDescriptionProvider(projectId));

    return jobDescAsync.when(
      loading: () => _buildShimmerPlaceholder(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (jobDesc) {
        if (jobDesc == null) return const SizedBox.shrink();
        return _buildContent(context, jobDesc);
      },
    );
  }

  Widget _buildContent(BuildContext context, JobDescription jobDesc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Text(
          'JOB DESCRIPTION',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: Color(0xFF94A3B8),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobDesc.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Project #${jobDesc.projectId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  jobDesc.description,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    height: 1.6,
                  ),
                ),
              ),

              // File attachments
              if (jobDesc.fileUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'ATTACHMENTS (${jobDesc.fileUrls.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                ...jobDesc.fileUrls.asMap().entries.map((entry) {
                  return _buildFileItem(context, entry.value, entry.key);
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileItem(BuildContext context, String url, int index) {
    final fileName = _extractFileName(url);
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          // Extension badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              extension,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 9,
                color: Color(0xFF2563EB),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // File name
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Open button
          _buildFileAction(
            icon: Icons.open_in_new_rounded,
            color: const Color(0xFF2563EB),
            tooltip: 'Open',
            onTap: () => _openFile(context, url),
          ),
          const SizedBox(width: 4),
          // Download button
          _buildFileAction(
            icon: Icons.download_rounded,
            color: const Color(0xFF10B981),
            tooltip: 'Download',
            onTap: () => _downloadFile(context, url),
          ),
        ],
      ),
    );
  }

  Widget _buildFileAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open file'),
            backgroundColor: Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(BuildContext context, String url) async {
    // Open in browser for download
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not download file'),
            backgroundColor: Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return Uri.decodeComponent(pathSegments.last);
      }
    } catch (_) {}
    return 'Document ${url.hashCode.abs() % 1000}';
  }

  Widget _buildShimmerPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
