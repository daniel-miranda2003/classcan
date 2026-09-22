import '../entities/assessment_entity.dart';

abstract class AssessmentRepository {
  Future<List<AssessmentEntity>> getAssessments(int courseId, String type);
  Future<AssessmentEntity> addAssessment(AssessmentEntity assessment);
  Future<void> deleteAssessment(int id);
}
