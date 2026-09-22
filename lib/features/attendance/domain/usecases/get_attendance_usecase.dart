import 'package:equatable/equatable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/attendance_record_entity.dart';
import '../repositories/attendance_repository.dart';

class GetAttendanceParams extends Equatable {
  final int courseId;
  final String date;

  const GetAttendanceParams({required this.courseId, required this.date});

  @override
  List<Object> get props => [courseId, date];
}

class GetAttendanceUseCase
    implements UseCase<List<AttendanceRecordEntity>, GetAttendanceParams> {
  final AttendanceRepository repository;

  const GetAttendanceUseCase(this.repository);

  @override
  Future<List<AttendanceRecordEntity>> call(GetAttendanceParams params) async {
    if (params.courseId <= 0) {
      throw const AttendanceValidationException('Curso inválido');
    }
    if (DateTime.tryParse(params.date) == null) {
      throw const AttendanceValidationException('Fecha inválida');
    }
    return repository.getAttendanceByCourseAndDate(
      courseId: params.courseId,
      date: params.date,
    );
  }
}
