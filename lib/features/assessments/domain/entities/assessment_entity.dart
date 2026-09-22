import 'package:equatable/equatable.dart';

class AssessmentEntity extends Equatable {
  final int? id;
  final int courseId;
  final String title;
  final String type;
  final double maxScore;
  final String date;

  const AssessmentEntity({
    this.id,
    required this.courseId,
    required this.title,
    required this.type,
    this.maxScore = 10,
    required this.date,
  });

  @override
  List<Object?> get props => [id, courseId, title, type, maxScore, date];
}
