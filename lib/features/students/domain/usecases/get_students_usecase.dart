import '../../../../core/usecase/usecase.dart';
import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentsUseCase implements UseCase<List<StudentEntity>, NoParams> {
  final StudentRepository repository;

  const GetStudentsUseCase(this.repository);

  @override
  Future<List<StudentEntity>> call(NoParams params) {
    return repository.getStudents();
  }
}
