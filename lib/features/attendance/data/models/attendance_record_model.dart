import '../../domain/entities/attendance_record_entity.dart';

class AttendanceRecordModel extends AttendanceRecordEntity {
  const AttendanceRecordModel({
    super.id,
    required super.studentId,
    required super.courseId,
    required super.date,
    required super.status,
  });

  static const allowedStatuses = ['PRESENT', 'ABSENT', 'LATE'];

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    return AttendanceRecordModel(
      id: map['id'] as int?,
      studentId: map['studentId'] as int,
      courseId: map['courseId'] as int,
      date: map['date'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    assert(
      allowedStatuses.contains(status),
      'status debe ser PRESENT, ABSENT o LATE',
    );
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'courseId': courseId,
      'date': date,
      'status': status,
    };
  }

  AttendanceRecordModel copyWith({
    int? id,
    int? studentId,
    int? courseId,
    String? date,
    String? status,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
