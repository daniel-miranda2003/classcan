import '../entities/grade_entity.dart';

abstract class GradeRepository {
  Future<List<GradeEntity>> getGrades(int assessmentId);
  Future<void> saveGradeBatch(List<GradeEntity> grades);
}
