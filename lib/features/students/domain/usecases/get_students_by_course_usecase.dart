import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class GetStudentsByCourseUseCase implements UseCase<List<StudentEntity>, int> {
  final StudentRepository repository;

  const GetStudentsByCourseUseCase(this.repository);

  @override
  Future<List<StudentEntity>> call(int courseId) async {
    if (courseId <= 0) {
      throw const StudentValidationException('Curso inválido');
    }
    return repository.getStudentsByCourse(courseId);
  }
}
