import 'package:equatable/equatable.dart';

class CourseEntity extends Equatable {
  final int? id;
  final String subject;
  final String grade;
  final String color;
  final int userId;

  const CourseEntity({
    this.id,
    required this.subject,
    required this.grade,
    required this.color,
    required this.userId,
  });

  @override
  List<Object?> get props => [id, subject, grade, color, userId];
}
