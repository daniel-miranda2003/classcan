import 'package:equatable/equatable.dart';

class GradeEntity extends Equatable {
  final int? id;
  final int assessmentId;
  final int studentId;
  final double score;

  const GradeEntity({
    this.id,
    required this.assessmentId,
    required this.studentId,
    required this.score,
  });

  @override
  List<Object?> get props => [id, assessmentId, studentId, score];
}
