import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_repository.dart';
import '../../domain/usecases/technician_usecases.dart';
import '../../data/datasources/technician_remote_datasource.dart';
import '../../data/repositories/technician_repository_impl.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class TechniciansState {
  final List<TechnicianEntity> technicians;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasReachedEnd;
  final int currentPage;
  final GetTechniciansParams params;
  final List<String> skillCategories;

  const TechniciansState({
    this.technicians = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasReachedEnd = false,
    this.currentPage = 1,
    this.params = const GetTechniciansParams(),
    this.skillCategories = const [],
  });

  TechniciansState copyWith({
    List<TechnicianEntity>? technicians,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasReachedEnd,
    int? currentPage,
    GetTechniciansParams? params,
    List<String>? skillCategories,
  }) {
    return TechniciansState(
      technicians: technicians ?? this.technicians,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentPage: currentPage ?? this.currentPage,
      params: params ?? this.params,
      skillCategories: skillCategories ?? this.skillCategories,
    );
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class TechniciansNotifier extends StateNotifier<TechniciansState> {
  final GetTechniciansUseCase _getTechnicians;
  final GetSkillCategoriesUseCase _getSkillCategories;

  TechniciansNotifier(this._getTechnicians, this._getSkillCategories)
      : super(const TechniciansState()) {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([loadTechnicians(), loadSkillCategories()]);
  }

  Future<void> loadTechnicians({bool refresh = false}) async {
    if (state.isLoading) return;

    final params = refresh
        ? const GetTechniciansParams(page: 1)
        : state.params;

    state = state.copyWith(
      isLoading: true,
      error: null,
      currentPage: 1,
      hasReachedEnd: false,
    );

    try {
      final results = await _getTechnicians(params);
      state = state.copyWith(
        technicians: results,
        isLoading: false,
        currentPage: 1,
        params: params,
        hasReachedEnd: results.length < params.pageSize,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('TechnicianApiException: ', ''),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isLoading) return;

    final nextPage = state.currentPage + 1;
    final params = state.params.copyWith(page: nextPage);

    state = state.copyWith(isLoadingMore: true);

    try {
      final results = await _getTechnicians(params);
      state = state.copyWith(
        technicians: [...state.technicians, ...results],
        isLoadingMore: false,
        currentPage: nextPage,
        params: params,
        hasReachedEnd: results.length < params.pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> loadSkillCategories() async {
    try {
      final skills = await _getSkillCategories();
      state = state.copyWith(skillCategories: skills);
    } catch (_) {}
  }

  void search(String query) {
    final params = state.params.copyWith(searchQuery: query, page: 1);
    state = state.copyWith(params: params);
    loadTechnicians();
  }

  void filterBySkill(String? skill) {
    final params = state.params.copyWith(skillFilter: skill, page: 1);
    state = state.copyWith(params: params);
    loadTechnicians();
  }

  void filterByStatus(TechnicianStatus? status) {
    final params = state.params.copyWith(statusFilter: status, page: 1);
    state = state.copyWith(params: params);
    loadTechnicians();
  }

  void clearFilters() {
    state = state.copyWith(params: const GetTechniciansParams());
    loadTechnicians();
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

// Swap TechnicianMockDataSource() → TechnicianRemoteDataSourceImpl(client: http.Client())
// when connecting to a real backend.
final technicianRepositoryProvider = Provider<TechnicianRepository>((ref) {
  final dataSource = TechnicianMockDataSource();
  return TechnicianRepositoryImpl(dataSource);
});

final techniciansProvider =
    StateNotifierProvider<TechniciansNotifier, TechniciansState>((ref) {
  final repo = ref.watch(technicianRepositoryProvider);
  return TechniciansNotifier(
    GetTechniciansUseCase(repo),
    GetSkillCategoriesUseCase(repo),
  );
});
