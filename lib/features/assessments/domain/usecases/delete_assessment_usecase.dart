import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/assessment_repository.dart';

class DeleteAssessmentUseCase implements UseCase<void, int> {
  final AssessmentRepository repository;

  const DeleteAssessmentUseCase(this.repository);

  @override
  Future<void> call(int id) async {
    if (id <= 0) {
      throw const AssessmentValidationException('Evaluación inválida');
    }
    return repository.deleteAssessment(id);
  }
}
