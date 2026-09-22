import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/grade_model.dart';

abstract class GradeLocalDataSource {
  Future<List<GradeModel>> getGrades(int assessmentId);
  Future<void> saveGradeBatch(List<GradeModel> grades);
}

class GradeLocalDataSourceImpl implements GradeLocalDataSource {
  final DatabaseHelper dbHelper;

  const GradeLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<GradeModel>> getGrades(int assessmentId) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableGrade,
        where: 'assessmentId = ?',
        whereArgs: [assessmentId],
        orderBy: 'studentId ASC',
      );
      return rows.map(GradeModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar las notas: $e');
    }
  }

  @override
  Future<void> saveGradeBatch(List<GradeModel> grades) async {
    if (grades.isEmpty) return;

    try {
      final db = await dbHelper.database;
      await db.transaction((txn) async {
        for (final grade in grades) {
          final updated = await txn.update(
            DatabaseHelper.tableGrade,
            {'score': grade.score},
            where: 'assessmentId = ? AND studentId = ?',
            whereArgs: [grade.assessmentId, grade.studentId],
          );
          if (updated == 0) {
            await txn.insert(
              DatabaseHelper.tableGrade,
              grade.toMap()..remove('id'),
            );
          }
        }
      });
    } catch (e) {
      throw LocalDatabaseException('Error al guardar las notas: $e');
    }
  }
}
