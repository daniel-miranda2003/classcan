import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/course_model.dart';

abstract class CourseLocalDataSource {
  Future<CourseModel> createCourse(CourseModel course);
  Future<List<CourseModel>> getCoursesByUserId(int userId);
  Future<void> deleteCourse(int courseId);
}

class CourseLocalDataSourceImpl implements CourseLocalDataSource {
  final DatabaseHelper dbHelper;

  const CourseLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<CourseModel> createCourse(CourseModel course) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableCourse,
        course.toMap()..remove('id'),
      );
      return course.copyWith(id: id);
    } catch (e) {
      throw LocalDatabaseException('Error al crear el curso: $e');
    }
  }

  @override
  Future<List<CourseModel>> getCoursesByUserId(int userId) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableCourse,
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'id DESC',
      );
      return rows.map(CourseModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar los cursos: $e');
    }
  }

  @override
  Future<void> deleteCourse(int courseId) async {
    try {
      final db = await dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableCourse,
        where: 'id = ?',
        whereArgs: [courseId],
      );
      if (count == 0) {
        throw NotFoundException('El curso no existe (id: $courseId)');
      }
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al eliminar el curso: $e');
    }
  }
}
