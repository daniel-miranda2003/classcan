import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

class GetCoursesUseCase implements UseCase<List<CourseEntity>, int> {
  final CourseRepository repository;

  const GetCoursesUseCase(this.repository);

  @override
  Future<List<CourseEntity>> call(int userId) async {
    if (userId <= 0) {
      throw const CourseValidationException(
        'Sesión inválida: falta el usuario',
      );
    }
    return repository.getCoursesByUserId(userId);
  }
}
