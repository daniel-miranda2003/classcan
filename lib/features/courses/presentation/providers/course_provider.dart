import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/course_entity.dart';
import '../../domain/usecases/add_course_usecase.dart';
import '../../domain/usecases/delete_course_usecase.dart';
import '../../domain/usecases/get_courses_usecase.dart';

class CourseNotifier extends AsyncNotifier<List<CourseEntity>> {
  int _userId = 0;

  @override
  Future<List<CourseEntity>> build() async => const [];

  Future<void> loadCourses(int userId) async {
    _userId = userId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => sl<GetCoursesUseCase>()(userId));
  }

  Future<void> loadCoursesIfNeeded(int userId) async {
    final current = switch (state) {
      AsyncData(:final value) when value.isNotEmpty => value,
      _ => null,
    };
    if (current != null) {
      _userId = userId;
      return;
    }
    if (state is AsyncLoading) return;
    return loadCourses(userId);
  }

  Future<String?> addCourse({
    required String subject,
    required String grade,
    required String color,
  }) async {
    try {
      final created = await sl<AddCourseUseCase>()(
        AddCourseParams(
          subject: subject,
          grade: grade,
          color: color,
          userId: _userId,
        ),
      );
      state = state.whenData((courses) => [created, ...courses]);
      return null;
    } catch (e) {
      return _humanize(e);
    }
  }

  Future<String?> deleteCourse(int courseId) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const <CourseEntity>[],
    };
    state = AsyncData(previous.where((c) => c.id != courseId).toList());
    try {
      await sl<DeleteCourseUseCase>()(courseId);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _humanize(e);
    }
  }

  void retry() {
    if (_userId > 0) loadCourses(_userId);
  }

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
      'CourseValidationException: ',
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

final courseProvider =
    AsyncNotifierProvider<CourseNotifier, List<CourseEntity>>(
      CourseNotifier.new,
    );
