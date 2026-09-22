import 'package:equatable/equatable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/assessment_entity.dart';
import '../repositories/assessment_repository.dart';
import 'get_assessments_usecase.dart';

class AddAssessmentParams extends Equatable {
  final int courseId;
  final String title;
  final String type;
  final double maxScore;
  final String date;

  const AddAssessmentParams({
    required this.courseId,
    required this.title,
    required this.type,
    this.maxScore = 100,
    required this.date,
  });

  @override
  List<Object> get props => [courseId, title, type, maxScore, date];
}

class AddAssessmentUseCase
    implements UseCase<AssessmentEntity, AddAssessmentParams> {
  final AssessmentRepository repository;

  const AddAssessmentUseCase(this.repository);

  @override
  Future<AssessmentEntity> call(AddAssessmentParams params) async {
    final title = params.title.trim();

    if (params.courseId <= 0) {
      throw const AssessmentValidationException('Curso inválido');
    }
    if (title.isEmpty) {
      throw const AssessmentValidationException('El título es obligatorio');
    }
    if (!AssessmentTypes.contains(params.type)) {
      throw AssessmentValidationException('Tipo inválido: ${params.type}');
    }
    if (params.maxScore <= 0) {
      throw const AssessmentValidationException(
        'La nota máxima debe ser mayor a 0',
      );
    }
    if (DateTime.tryParse(params.date) == null) {
      throw const AssessmentValidationException('Fecha inválida');
    }

    return repository.addAssessment(
      AssessmentEntity(
        courseId: params.courseId,
        title: title,
        type: params.type,
        maxScore: params.maxScore,
        date: params.date,
      ),
    );
  }
}
