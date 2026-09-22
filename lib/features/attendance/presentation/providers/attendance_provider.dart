import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/usecases/get_students_by_course_usecase.dart';
import '../../domain/entities/attendance_record_entity.dart';
import '../../domain/usecases/get_attendance_usecase.dart';
import '../../domain/usecases/save_attendance_usecase.dart';

String formatAttendanceDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}-$m-$d';
}

String todayAttendanceDate() => formatAttendanceDate(DateTime.now());

class AttendanceRow extends Equatable {
  final StudentEntity student;
  final String status;

  const AttendanceRow({required this.student, this.status = 'PRESENT'});

  AttendanceRow copyWith({StudentEntity? student, String? status}) {
    return AttendanceRow(
      student: student ?? this.student,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [student, status];
}

class AttendanceState extends Equatable {
  final int courseId;
  final String date;
  final List<AttendanceRow> rows;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const AttendanceState({
    this.courseId = 0,
    this.date = '',
    this.rows = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  int get presentCount => rows.where((r) => r.status == 'PRESENT').length;
  int get absentCount => rows.where((r) => r.status == 'ABSENT').length;
  int get lateCount => rows.where((r) => r.status == 'LATE').length;

  AttendanceState copyWith({
    int? courseId,
    String? date,
    List<AttendanceRow>? rows,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return AttendanceState(
      courseId: courseId ?? this.courseId,
      date: date ?? this.date,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    courseId,
    date,
    rows,
    isLoading,
    isSaving,
    errorMessage,
  ];
}

class AttendanceNotifier extends Notifier<AttendanceState> {
  @override
  AttendanceState build() => AttendanceState(date: todayAttendanceDate());

  Future<void> load({required int courseId, required String date}) async {
    state = state.copyWith(
      courseId: courseId,
      date: date,
      isLoading: true,
      errorMessage: null,
    );
    try {
      final results = await Future.wait([
        sl<GetStudentsByCourseUseCase>()(courseId),
        sl<GetAttendanceUseCase>()(
          GetAttendanceParams(courseId: courseId, date: date),
        ),
      ]);
      final students = results[0] as List<StudentEntity>;
      final records = results[1] as List<AttendanceRecordEntity>;
      final byStudent = {for (final r in records) r.studentId: r.status};

      state = state.copyWith(
        isLoading: false,
        rows: [
          for (final s in students)
            AttendanceRow(student: s, status: byStudent[s.id] ?? 'PRESENT'),
        ],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _humanize(e));
    }
  }

  Future<void> changeDate(String date) {
    return load(courseId: state.courseId, date: date);
  }

  void setStatus({required int studentId, required String status}) {
    if (!SaveAttendanceUseCase.allowedStatuses.contains(status)) return;
    state = state.copyWith(
      rows: [
        for (final row in state.rows)
          if (row.student.id == studentId)
            row.copyWith(status: status)
          else
            row,
      ],
      errorMessage: null,
    );
  }

  Future<String?> submit() async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await sl<SaveAttendanceUseCase>()([
        for (final row in state.rows)
          AttendanceRecordEntity(
            studentId: row.student.id ?? 0,
            courseId: state.courseId,
            date: state.date,
            status: row.status,
          ),
      ]);
      List<StudentEntity> fresh = const [];
      try {
        fresh = await sl<GetStudentsByCourseUseCase>()(state.courseId);
      } catch (_) {
        fresh = const [];
      }
      final byId = {for (final s in fresh) s.id: s};
      state = state.copyWith(
        isSaving: false,
        rows: [
          for (final row in state.rows)
            row.copyWith(student: byId[row.student.id] ?? row.student),
        ],
      );
      return null;
    } catch (e) {
      final message = _humanize(e);
      state = state.copyWith(isSaving: false, errorMessage: message);
      return message;
    }
  }

  void retry() => load(courseId: state.courseId, date: state.date);

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
      'AttendanceValidationException: ',
      'StudentValidationException: ',
      'LocalDatabaseException: ',
      'NotFoundException: ',
      'Exception: ',
    ];
    for (final p in prefixes) {
      if (raw.startsWith(p)) return raw.substring(p.length);
    }
    return raw;
  }
}

final attendanceProvider =
    NotifierProvider<AttendanceNotifier, AttendanceState>(
      AttendanceNotifier.new,
    );
