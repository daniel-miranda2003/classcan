import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import '../models/assessment_model.dart';

abstract class AssessmentLocalDataSource {
  Future<List<AssessmentModel>> getAssessments(int courseId, String type);
  Future<AssessmentModel> addAssessment(AssessmentModel assessment);
  Future<void> deleteAssessment(int id);
}

class AssessmentLocalDataSourceImpl implements AssessmentLocalDataSource {
  final DatabaseHelper dbHelper;
  const AssessmentLocalDataSourceImpl({required this.dbHelper});

  @override
  Future<List<AssessmentModel>> getAssessments(
    int courseId,
    String type,
  ) async {
    try {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseHelper.tableAssessment,
        where: 'courseId = ? AND type = ?',
        whereArgs: [courseId, type],
        orderBy: 'date DESC, id DESC',
      );
      return rows.map(AssessmentModel.fromMap).toList();
    } catch (e) {
      throw LocalDatabaseException('Error al cargar las evaluaciones: $e');
    }
  }

  @override
  Future<AssessmentModel> addAssessment(AssessmentModel assessment) async {
    try {
      final db = await dbHelper.database;
      final id = await db.insert(
        DatabaseHelper.tableAssessment,
        assessment.toMap()..remove('id'),
      );
      return assessment.copyWith(id: id);
    } catch (e) {
      throw LocalDatabaseException('Error al registrar la evaluación: $e');
    }
  }

  @override
  Future<void> deleteAssessment(int id) async {
    try {
      final db = await dbHelper.database;
      final count = await db.delete(
        DatabaseHelper.tableAssessment,
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count == 0) {
        throw NotFoundException('La evaluación no existe (id: $id)');
      }
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw LocalDatabaseException('Error al eliminar la evaluación: $e');
    }
  }
}
