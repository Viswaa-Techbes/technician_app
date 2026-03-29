import '../entities/technician_entity.dart';

/// Filter parameters for the technician query
class GetTechniciansParams {
  final String? searchQuery;
  final String? skillFilter;
  final TechnicianStatus? statusFilter;
  final int page;
  final int pageSize;

  const GetTechniciansParams({
    this.searchQuery,
    this.skillFilter,
    this.statusFilter,
    this.page = 1,
    this.pageSize = 10,
  });

  GetTechniciansParams copyWith({
    String? searchQuery,
    String? skillFilter,
    TechnicianStatus? statusFilter,
    int? page,
    int? pageSize,
  }) {
    return GetTechniciansParams(
      searchQuery: searchQuery ?? this.searchQuery,
      skillFilter: skillFilter ?? this.skillFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

/// Abstract repository — the contract between domain and data
abstract class TechnicianRepository {
  /// Returns paginated list of technicians or throws on failure.
  Future<List<TechnicianEntity>> getTechnicians(GetTechniciansParams params);

  /// Returns all unique skill categories available.
  Future<List<String>> getSkillCategories();
}
