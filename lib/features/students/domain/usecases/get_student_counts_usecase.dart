import '../../../../core/usecase/usecase.dart';
import '../repositories/student_repository.dart';

class GetStudentCountsUseCase implements UseCase<Map<int, int>, NoParams> {
  final StudentRepository repository;

  const GetStudentCountsUseCase(this.repository);

  @override
  Future<Map<int, int>> call(NoParams params) {
    return repository.getStudentCountsByCourse();
  }
}
