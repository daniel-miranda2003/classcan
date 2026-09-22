import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class SaveAttendanceUseCase
    implements UseCase<void, List<AttendanceRecordEntity>> {
  final AttendanceRepository repository;

  const SaveAttendanceUseCase(this.repository);

  static const allowedStatuses = ['PRESENT', 'ABSENT', 'LATE'];

  @override
  Future<void> call(List<AttendanceRecordEntity> records) async {
    if (records.isEmpty) {
      throw const AttendanceValidationException(
        'No hay estudiantes que guardar',
      );
    }

    final courseId = records.first.courseId;
    final date = records.first.date;

    for (final r in records) {
      if (r.studentId <= 0 || r.courseId <= 0) {
        throw const AttendanceValidationException(
          'Registro con ids inválidos',
        );
      }
      if (!allowedStatuses.contains(r.status)) {
        throw AttendanceValidationException('Estado inválido: ${r.status}');
      }
      if (r.courseId != courseId || r.date != date) {
        throw const AttendanceValidationException(
          'El lote mezcla cursos o fechas distintos',
        );
      }
    }
    return repository.saveAttendanceBatch(records);
  }
}
