import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/course_entity.dart';
import '../repositories/course_repository.dart';

class AddCourseParams extends Equatable {
  final String subject;
  final String grade;
  final String color;
  final int userId;

  const AddCourseParams({
    required this.subject,
    required this.grade,
    required this.color,
    required this.userId,
  });

  @override
  List<Object> get props => [subject, grade, color, userId];
}

class AddCourseUseCase implements UseCase<CourseEntity, AddCourseParams> {
  final CourseRepository repository;

  const AddCourseUseCase(this.repository);

  @override
  Future<CourseEntity> call(AddCourseParams params) async {
    final subject = params.subject.trim();
    final grade = params.grade.trim();

    if (subject.isEmpty) {
      throw const CourseValidationException('La materia es obligatoria');
    }
    if (grade.isEmpty) {
      throw const CourseValidationException('El grado/grupo es obligatorio');
    }
    if (params.userId <= 0) {
      throw const CourseValidationException(
        'Sesión inválida: falta el usuario',
      );
    }

    return repository.createCourse(
      CourseEntity(
        subject: subject,
        grade: grade,
        color: params.color.isEmpty ? '#6366F1' : params.color,
        userId: params.userId,
      ),
    );
  }
}
