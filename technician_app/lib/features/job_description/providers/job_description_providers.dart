import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_description_model.dart';
import '../services/job_description_service.dart';

/// Provider for the JobDescriptionService instance.
final jobDescriptionServiceProvider = Provider<JobDescriptionService>((ref) {
  return JobDescriptionService();
});

/// Fetches job description for a specific project.
final jobDescriptionProvider = FutureProvider.family
    .autoDispose<JobDescription?, String>(
  (ref, projectId) async {
    final service = ref.watch(jobDescriptionServiceProvider);
    return service.fetchJobDescription(
      projectId: projectId,
    );
  },
);

/// Manages the state for creating a job description (with file uploads).
class JobDescriptionCreateNotifier extends StateNotifier<AsyncValue<void>> {
  final JobDescriptionService _service;

  JobDescriptionCreateNotifier(this._service)
      : super(const AsyncValue.data(null));

  /// The currently selected files (not yet uploaded).
  List<File> selectedFiles = [];

  Future<bool> createWithFiles({
    required String projectId,
    required String title,
    required String description,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Step 1: Upload files
      List<String> fileUrls = [];
      if (selectedFiles.isNotEmpty) {
        fileUrls = await _service.uploadFiles(
          files: selectedFiles,
          projectId: projectId,
        );
      }

      // Step 2: Create job description document
      await _service.createJobDescription(
        projectId: projectId,
        title: title,
        description: description,
        fileUrls: fileUrls,
      );

      selectedFiles = [];
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (kDebugMode) print('createWithFiles error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final jobDescriptionCreateProvider = StateNotifierProvider.autoDispose<
    JobDescriptionCreateNotifier, AsyncValue<void>>(
  (ref) =>
      JobDescriptionCreateNotifier(ref.watch(jobDescriptionServiceProvider)),
);
