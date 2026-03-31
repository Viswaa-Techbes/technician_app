import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/job_description_providers.dart';
import '../../../widgets.dart';

/// Manager screen to add a job description with file attachments.
class AddJobDescriptionScreen extends ConsumerStatefulWidget {
  final String projectId;

  const AddJobDescriptionScreen({super.key, required this.projectId});

  @override
  ConsumerState<AddJobDescriptionScreen> createState() =>
      _AddJobDescriptionScreenState();
}

class _AddJobDescriptionScreenState
    extends ConsumerState<AddJobDescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<File> _selectedFiles = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _selectedFiles.addAll(
            result.paths
                .where((p) => p != null)
                .map((p) => File(p!))
                .toList(),
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking files: $e'),
            backgroundColor: const Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(jobDescriptionCreateProvider.notifier);
    notifier.selectedFiles = _selectedFiles;

    final success = await notifier.createWithFiles(
      projectId: widget.projectId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job description added successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add job description.'),
            backgroundColor: Color(0xFFF43F5E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(jobDescriptionCreateProvider);
    final isSubmitting = createState is AsyncLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ADD JOB DESCRIPTION'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project ID badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'PROJECT #${widget.projectId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title field
              _buildSectionHeader('TITLE'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Title is required' : null,
                decoration: _inputDecoration(
                  'Enter job title',
                  Icons.title_rounded,
                ),
              ),
              const SizedBox(height: 28),

              // Description field
              _buildSectionHeader('DESCRIPTION'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Description is required' : null,
                decoration: _inputDecoration(
                  'Enter detailed job description...',
                  Icons.description_outlined,
                ),
              ),
              const SizedBox(height: 28),

              // File Upload Section
              _buildSectionHeader('ATTACHMENTS'),
              const SizedBox(height: 12),
              _buildFileUploadArea(),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._selectedFiles.asMap().entries.map((entry) {
                  return _buildFileChip(entry.value, entry.key);
                }),
              ],
              const SizedBox(height: 48),

              // Submit button
              isSubmitting
                  ? const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFF1E3A8A)),
                          SizedBox(height: 16),
                          Text(
                            'Uploading files...',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : CustomButton(
                      label: 'SAVE JOB DESCRIPTION',
                      onPressed: _submit,
                      color: const Color(0xFF1E3A8A),
                      icon: Icons.save_rounded,
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 11,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFCBD5E1),
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.5),
      ),
      contentPadding: const EdgeInsets.all(20),
    );
  }

  Widget _buildFileUploadArea() {
    return GestureDetector(
      onTap: _pickFiles,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.2),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: Color(0xFF2563EB),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap to upload files',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'PDF, images, documents',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileChip(File file, int index) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              extension,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: Color(0xFF6366F1),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              fileName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                color: Color(0xFFF43F5E), size: 18),
            onPressed: () => _removeFile(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
