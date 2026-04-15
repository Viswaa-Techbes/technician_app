import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../services/api_service.dart';

final liveTechniciansProvider = StreamProvider.autoDispose<List<Technician>>((ref) async* {
  final api = ref.watch(apiServiceProvider);

  Future<List<Technician>> fetch() async {
    final technicians = await api.getTechnicians();
    return technicians;
  }

  yield await fetch();

  yield* Stream.periodic(const Duration(seconds: 8))
      .asyncMap((_) => fetch());
});
