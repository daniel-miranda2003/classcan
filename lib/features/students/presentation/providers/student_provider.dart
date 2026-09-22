import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/student_entity.dart';
import '../../domain/usecases/add_student_usecase.dart';
import '../../domain/usecases/delete_student_usecase.dart';
import '../../domain/usecases/get_students_by_course_usecase.dart';
import '../../domain/usecases/get_students_usecase.dart';

class StudentNotifier extends AsyncNotifier<List<StudentEntity>> {
  int? _courseId;

  @override
  Future<List<StudentEntity>> build() async => const [];

  Future<void> loadStudents() async {
    _courseId = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => sl<GetStudentsUseCase>()(NoParams()));
  }

  Future<void> loadStudentsByCourse(int courseId) async {
    _courseId = courseId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => sl<GetStudentsByCourseUseCase>()(courseId),
    );
  }

  Future<String?> addStudent({
    required String firstName,
    String middleName = '',
    required String paternalLastName,
    String maternalLastName = '',
  }) async {
    try {
      final created = await sl<AddStudentUseCase>()(
        AddStudentParams(
          firstName: firstName,
          middleName: middleName,
          paternalLastName: paternalLastName,
          maternalLastName: maternalLastName,
          courseId: _courseId,
        ),
      );
      final current = switch (state) {
        AsyncData(:final value) => value,
        _ => const <StudentEntity>[],
      };
      final updated = [...current, created];
      updated.sort((a, b) {
        final byName = a.firstName.toLowerCase().compareTo(
              b.firstName.toLowerCase(),
            );
        return byName != 0
            ? byName
            : a.paternalLastName.toLowerCase().compareTo(
                  b.paternalLastName.toLowerCase(),
                );
      });
      state = AsyncData(updated);
      return null;
    } catch (e) {
      return _humanize(e);
    }
  }

  Future<String?> deleteStudent(int id) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const <StudentEntity>[],
    };
    state = AsyncData(previous.where((s) => s.id != id).toList());
    try {
      await sl<DeleteStudentUseCase>()(id);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _humanize(e);
    }
  }

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
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

final studentProvider =
    AsyncNotifierProvider<StudentNotifier, List<StudentEntity>>(
      StudentNotifier.new,
    );
