import '../entities/attendance_record_entity.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecordEntity>> getAttendanceByCourseAndDate({
    required int courseId,
    required String date,
  });

  Future<void> saveAttendanceBatch(List<AttendanceRecordEntity> records);
}
