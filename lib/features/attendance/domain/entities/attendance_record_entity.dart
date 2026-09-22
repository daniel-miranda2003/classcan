import 'package:equatable/equatable.dart';

class AttendanceRecordEntity extends Equatable {
  final int? id;
  final int studentId;
  final int courseId;
  final String date;
  final String status;

  const AttendanceRecordEntity({
    this.id,
    required this.studentId,
    required this.courseId,
    required this.date,
    required this.status,
  });

  @override
  List<Object?> get props => [id, studentId, courseId, date, status];
}
