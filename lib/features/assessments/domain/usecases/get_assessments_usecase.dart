import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assessment_entity.dart';
import '../repositories/assessment_repository.dart';

class GetAssessmentsParams extends Equatable {
  final int courseId;
  final String type;

  const GetAssessmentsParams({required this.courseId, required this.type});

  @override
  List<Object> get props => [courseId, type];
}

class GetAssessmentsUseCase
    implements UseCase<List<AssessmentEntity>, GetAssessmentsParams> {
  final AssessmentRepository repository;

  const GetAssessmentsUseCase(this.repository);

  @override
  Future<List<AssessmentEntity>> call(GetAssessmentsParams params) async {
    if (params.courseId <= 0) {
      throw const AssessmentValidationException('Curso inválido');
    }
    if (!AssessmentTypes.contains(params.type)) {
      throw AssessmentValidationException('Tipo inválido: ${params.type}');
    }
    return repository.getAssessments(params.courseId, params.type);
  }
}

class AssessmentTypes {
  static const values = ['TASK', 'EXAM'];
  static bool contains(String type) => values.contains(type);
}
