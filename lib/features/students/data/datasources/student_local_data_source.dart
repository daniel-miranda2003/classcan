import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/student_model.dart';

abstract class StudentLocalDataSource {
  Future<StudentModel> createStudent(StudentModel student);
  Future<List<StudentModel>> getStudents();

  Future<List<StudentModel>> getStudentsByCourse(int courseId);

  Future<void> enrollStudent({required int studentId, required int courseId});

  Future<Map<int, int>> getStudentCountsByCourse();
  Future<void> deleteStudent(int id);
}

class StudentLocalDataSourceImpl implements StudentLocalDataSource {
  final DatabaseHelper dbHelper;

  const StudentLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<StudentModel> createStudent(StudentModel student) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableStudent,
        student.toMap()..remove('id'),
      );
      return student.copyWith(id: id);
    } catch (e) {
      throw LocalDatabaseException('Error al registrar el estudiante: $e');
    }
  }

  @override
  Future<List<StudentModel>> getStudents() async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery(
        'SELECT s.*, AVG((g.score / a.maxScore) * 100.0) AS averagePercentage '
        'FROM ${DatabaseHelper.tableStudent} s '
        'LEFT JOIN ${DatabaseHelper.tableGrade} g ON g.studentId = s.id '
        'LEFT JOIN ${DatabaseHelper.tableAssessment} a ON a.id = g.assessmentId '
        'GROUP BY s.id '
        'ORDER BY s.firstName COLLATE NOCASE ASC, s.paternalLastName COLLATE NOCASE ASC',
      );
      return rows.map(StudentModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar los estudiantes: $e');
    }
  }

  @override
  Future<List<StudentModel>> getStudentsByCourse(int courseId) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery(
        'SELECT s.*, AVG((g.score / a.maxScore) * 100.0) AS averagePercentage '
        'FROM ${DatabaseHelper.tableStudent} s '
        'INNER JOIN ${DatabaseHelper.tableEnrollment} e ON e.studentId = s.id '
        'LEFT JOIN ${DatabaseHelper.tableAssessment} a ON a.courseId = e.courseId '
        'LEFT JOIN ${DatabaseHelper.tableGrade} g ON g.assessmentId = a.id AND g.studentId = s.id '
        'WHERE e.courseId = ? '
        'GROUP BY s.id '
        'ORDER BY s.firstName COLLATE NOCASE ASC, s.paternalLastName COLLATE NOCASE ASC',
        [courseId],
      );
      return rows.map(StudentModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar los estudiantes: $e');
    }
  }

  @override
  Future<void> enrollStudent({
    required int studentId,
    required int courseId,
  }) async {
    try {
      final db = await dbHelper.database;
      await db.insert(
        DatabaseHelper.tableEnrollment,
        {'studentId': studentId, 'courseId': courseId},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      throw LocalDatabaseException('Error al matricular al estudiante: $e');
    }
  }

  @override
  Future<Map<int, int>> getStudentCountsByCourse() async {
    try {
      final db = await dbHelper.database;
      final rows = await db.rawQuery(
        'SELECT courseId, COUNT(*) AS total '
        'FROM ${DatabaseHelper.tableEnrollment} '
        'GROUP BY courseId',
      );
      return {
        for (final r in rows)
          (r['courseId'] as int): (r['total'] as int),
      };
    } catch (e) {
      throw LocalDatabaseException('Error al contar estudiantes: $e');
    }
  }

  @override
  Future<void> deleteStudent(int id) async {
    try {
      final db = await dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableStudent,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw NotFoundException('El estudiante no existe (id: $id)');
      }
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al eliminar el estudiante: $e');
    }
  }
}
