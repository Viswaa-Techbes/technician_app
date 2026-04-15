import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models.dart';
import '../services/api_service.dart';

final jobsProvider = FutureProvider.family<List<Job>, String?>((ref, status) async {
  final api = ref.watch(apiServiceProvider);
  return api.getJobs(status: status);
});

// Real-time listener that invalidates the jobsProvider
final jobsUpdateListenerProvider = Provider<void>((ref) {
  // We'll hook this up in the app to listen for socket events
});
