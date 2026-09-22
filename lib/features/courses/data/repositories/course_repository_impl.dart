import '../../domain/entities/course_entity.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_local_data_source.dart';
import '../models/course_model.dart';

class CourseRepositoryImpl implements CourseRepository {
  final CourseLocalDataSource localDataSource;

  const CourseRepositoryImpl({required this.localDataSource});

  @override
  Future<CourseEntity> createCourse(CourseEntity course) {
    return localDataSource.createCourse(_toModel(course));
  }

  @override
  Future<List<CourseEntity>> getCoursesByUserId(int userId) {
    return localDataSource.getCoursesByUserId(userId);
  }

  @override
  Future<void> deleteCourse(int courseId) {
    return localDataSource.deleteCourse(courseId);
  }

  CourseModel _toModel(CourseEntity e) => CourseModel(
    id: e.id,
    subject: e.subject,
    grade: e.grade,
    color: e.color,
    userId: e.userId,
  );
}
