import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/job_entity.dart';
import '../../domain/repositories/job_repository.dart';
import '../../data/repositories/job_repository_impl.dart';

class JobsNotifier extends StateNotifier<AsyncValue<List<JobEntity>>> {
  final JobRepository _repository;

  JobsNotifier(this._repository) : super(const AsyncValue.loading()) {
    getJobs();
  }

  Future<void> getJobs({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final jobs = await _repository.getJobs(status: status);
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshJobs() async {
    try {
      final jobs = await _repository.getJobs();
      state = AsyncValue.data(jobs);
    } catch (e, st) {
      // Don't show loading on refresh if we already have data
      if (state.hasValue) return;
      state = AsyncValue.error(e, st);
    }
  }
}

final jobsNotifierProvider = StateNotifierProvider<JobsNotifier, AsyncValue<List<JobEntity>>>((ref) {
  return JobsNotifier(ref.watch(jobRepositoryProvider));
});
