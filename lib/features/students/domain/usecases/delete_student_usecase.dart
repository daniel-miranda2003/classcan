import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/student_repository.dart';

class DeleteStudentUseCase implements UseCase<void, int> {
  final StudentRepository repository;

  const DeleteStudentUseCase(this.repository);

  @override
  Future<void> call(int id) async {
    if (id <= 0) {
      throw const StudentValidationException('Estudiante inválido');
    }
    return repository.deleteStudent(id);
  }
}
