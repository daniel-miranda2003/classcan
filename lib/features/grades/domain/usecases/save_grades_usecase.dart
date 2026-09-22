import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/grade_entity.dart';
import '../repositories/grade_repository.dart';

class SaveGradesParams extends Equatable {
  final int assessmentId;
  final double maxScore;
  final List<GradeEntity> grades;

  const SaveGradesParams({
    required this.assessmentId,
    required this.maxScore,
    required this.grades,
  });

  @override
  List<Object> get props => [assessmentId, maxScore, grades];
}

class SaveGradesUseCase implements UseCase<void, SaveGradesParams> {
  final GradeRepository repository;

  const SaveGradesUseCase(this.repository);

  @override
  Future<void> call(SaveGradesParams params) async {
    if (params.assessmentId <= 0) {
      throw const GradeValidationException('Evaluación inválida');
    }
    if (params.grades.isEmpty) {
      throw const GradeValidationException('No hay notas que guardar');
    }

    for (final g in params.grades) {
      if (g.studentId <= 0 || g.assessmentId != params.assessmentId) {
        throw const GradeValidationException(
          'El lote mezcla evaluaciones distintas',
        );
      }
      if (g.score.isNaN || g.score < 0 || g.score > params.maxScore) {
        throw GradeValidationException(
          'Nota fuera de rango (0–${params.maxScore}): ${g.score}',
        );
      }
    }

    return repository.saveGradeBatch(params.grades);
  }
}
