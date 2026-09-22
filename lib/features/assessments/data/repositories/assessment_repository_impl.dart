import '../../domain/entities/assessment_entity.dart';
import '../../domain/repositories/assessment_repository.dart';
import '../datasources/assessment_local_data_source.dart';
import '../models/assessment_model.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final AssessmentLocalDataSource localDataSource;

  const AssessmentRepositoryImpl({required this.localDataSource});

  @override
  Future<List<AssessmentEntity>> getAssessments(int courseId, String type) {
    return localDataSource.getAssessments(courseId, type);
  }

  @override
  Future<AssessmentEntity> addAssessment(AssessmentEntity assessment) {
    return localDataSource.addAssessment(_toModel(assessment));
  }

  @override
  Future<void> deleteAssessment(int id) {
    return localDataSource.deleteAssessment(id);
  }

  AssessmentModel _toModel(AssessmentEntity e) => AssessmentModel(
    id: e.id,
    courseId: e.courseId,
    title: e.title,
    type: e.type,
    maxScore: e.maxScore,
    date: e.date,
  );
}
