import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/grade_entity.dart';
import '../repositories/grade_repository.dart';

class GetGradesUseCase implements UseCase<List<GradeEntity>, int> {
  final GradeRepository repository;

  const GetGradesUseCase(this.repository);

  @override
  Future<List<GradeEntity>> call(int assessmentId) async {
    if (assessmentId <= 0) {
      throw const GradeValidationException('Evaluación inválida');
    }
    return repository.getGrades(assessmentId);
  }
}
