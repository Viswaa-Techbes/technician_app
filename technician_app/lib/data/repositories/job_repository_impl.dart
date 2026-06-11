import '../../core/network/api_config.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../models/job_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JobRepositoryImpl implements JobRepository {
  final DioClient _apiService;

  JobRepositoryImpl(this._apiService);

  @override
  Future<List<JobEntity>> getJobs({String? status}) async {
    final response = await _apiService.get(
      ApiConfig.jobs,
      queryParameters: status != null ? {'status': status} : null,
    );
    
    final List data = response.data['data'] ?? [];
    return data.map((json) => JobModel.fromJson(json)).toList();
  }

  @override
  Future<JobEntity> createJob(Map<String, dynamic> jobData) async {
    final response = await _apiService.post(ApiConfig.jobs, data: jobData);
    return JobModel.fromJson(response.data['data']);
  }

  @override
  Future<void> updateJobStatus(String jobId, String status, {String? notes}) async {
    await _apiService.patch(
      '${ApiConfig.updateJobStatus}/$jobId/status',
      data: {'status': status, 'notes': notes},
    );
  }

  @override
  Future<void> assignJob(String jobId, String technicianId) async {
    await _apiService.post(
      ApiConfig.assignJob,
      data: {'jobId': jobId, 'technicianId': technicianId},
    );
  }
}

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  return JobRepositoryImpl(ref.watch(dioClientProvider));
});
