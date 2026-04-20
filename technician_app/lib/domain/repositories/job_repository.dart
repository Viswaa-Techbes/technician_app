import '../../domain/entities/job_entity.dart';

abstract class JobRepository {
  Future<List<JobEntity>> getJobs({String? status});
  Future<JobEntity> createJob(Map<String, dynamic> jobData);
  Future<void> updateJobStatus(String jobId, String status, {String? notes});
  Future<void> assignJob(String jobId, String technicianId);
}
