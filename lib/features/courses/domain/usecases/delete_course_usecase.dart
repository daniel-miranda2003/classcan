import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/course_repository.dart';

class DeleteCourseUseCase implements UseCase<void, int> {
  final CourseRepository repository;

  const DeleteCourseUseCase(this.repository);

  @override
  Future<void> call(int courseId) async {
    if (courseId <= 0) {
      throw const CourseValidationException('Curso inválido');
    }
    return repository.deleteCourse(courseId);
  }
}
