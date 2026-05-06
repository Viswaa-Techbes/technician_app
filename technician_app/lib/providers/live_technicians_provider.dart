import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../services/api_service.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

final liveTechniciansProvider = StreamProvider.autoDispose<List<Technician>>((ref) async* {
  final api = ref.watch(apiServiceProvider);
  final user = ref.watch(authProvider);

  Future<List<Technician>> fetch() async {
    if (user?.role == Role.manager || user?.role == Role.admin) {
      return await api.getTrackingData();
    }
    return await api.getTechnicians();
  }

  yield await fetch();

  yield* Stream.periodic(const Duration(seconds: 8))
      .asyncMap((_) => fetch());
});
