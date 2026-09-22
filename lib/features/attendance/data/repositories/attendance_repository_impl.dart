import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../datasources/attendance_local_data_source.dart';
import '../models/attendance_record_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceLocalDataSource localDataSource;

  const AttendanceRepositoryImpl({required this.localDataSource});

  @override
  Future<List<AttendanceRecordEntity>> getAttendanceByCourseAndDate({
    required int courseId,
    required String date,
  }) {
    return localDataSource.getAttendanceByCourseAndDate(courseId, date);
  }

  @override
  Future<void> saveAttendanceBatch(List<AttendanceRecordEntity> records) {
    return localDataSource.saveAttendanceBatch(records.map(_toModel).toList());
  }

  AttendanceRecordModel _toModel(AttendanceRecordEntity e) =>
      AttendanceRecordModel(
        id: e.id,
        studentId: e.studentId,
        courseId: e.courseId,
        date: e.date,
        status: e.status,
      );
}
