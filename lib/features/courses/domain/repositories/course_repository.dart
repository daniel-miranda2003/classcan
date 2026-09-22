import '../entities/course_entity.dart';

abstract class CourseRepository {
  Future<CourseEntity> createCourse(CourseEntity course);
  Future<List<CourseEntity>> getCoursesByUserId(int userId);
  Future<void> deleteCourse(int courseId);
}
