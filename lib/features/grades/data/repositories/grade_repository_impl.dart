import '../../domain/entities/grade_entity.dart';
import '../../domain/repositories/grade_repository.dart';
import '../datasources/grade_local_data_source.dart';
import '../models/grade_model.dart';

class GradeRepositoryImpl implements GradeRepository {
  final GradeLocalDataSource localDataSource;

  const GradeRepositoryImpl({required this.localDataSource});

  @override
  Future<List<GradeEntity>> getGrades(int assessmentId) {
    return localDataSource.getGrades(assessmentId);
  }

  @override
  Future<void> saveGradeBatch(List<GradeEntity> grades) {
    return localDataSource.saveGradeBatch(grades.map(_toModel).toList());
  }

  GradeModel _toModel(GradeEntity e) => GradeModel(
    id: e.id,
    assessmentId: e.assessmentId,
    studentId: e.studentId,
    score: e.score,
  );
}
