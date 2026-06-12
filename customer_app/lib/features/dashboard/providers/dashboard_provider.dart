import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';
import 'package:customer_app/features/dashboard/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDashboardData();
});
