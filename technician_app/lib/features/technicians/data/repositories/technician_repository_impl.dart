import '../../domain/entities/technician_entity.dart';
import '../../domain/repositories/technician_repository.dart';
import '../datasources/technician_remote_datasource.dart';

class TechnicianRepositoryImpl implements TechnicianRepository {
  final TechnicianRemoteDataSource _dataSource;

  const TechnicianRepositoryImpl(this._dataSource);

  @override
  Future<List<TechnicianEntity>> getTechnicians(GetTechniciansParams params) async {
    try {
      final models = await _dataSource.fetchTechnicians(params);
      return models.map((m) => m.toEntity()).toList();
    } on TechnicianApiException {
      rethrow;
    } catch (e) {
      throw TechnicianApiException('Unexpected error: $e');
    }
  }

  @override
  Future<List<String>> getSkillCategories() async {
    try {
      return await _dataSource.fetchSkillCategories();
    } catch (e) {
      throw TechnicianApiException('Failed to load skill categories: $e');
    }
  }
}
