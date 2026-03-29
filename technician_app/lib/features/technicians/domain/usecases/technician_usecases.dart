import '../entities/technician_entity.dart';
import '../repositories/technician_repository.dart';

class GetTechniciansUseCase {
  final TechnicianRepository _repository;

  const GetTechniciansUseCase(this._repository);

  Future<List<TechnicianEntity>> call(GetTechniciansParams params) {
    return _repository.getTechnicians(params);
  }
}

class GetSkillCategoriesUseCase {
  final TechnicianRepository _repository;

  const GetSkillCategoriesUseCase(this._repository);

  Future<List<String>> call() {
    return _repository.getSkillCategories();
  }
}
