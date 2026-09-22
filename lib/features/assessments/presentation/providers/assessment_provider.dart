import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/assessment_entity.dart';
import '../../domain/usecases/add_assessment_usecase.dart';
import '../../domain/usecases/delete_assessment_usecase.dart';
import '../../domain/usecases/get_assessments_usecase.dart';

class AssessmentNotifier extends AsyncNotifier<List<AssessmentEntity>> {
  int _courseId = 0;
  String _type = 'TASK';

  @override
  Future<List<AssessmentEntity>> build() async => const [];

  Future<void> load({required int courseId, required String type}) async {
    _courseId = courseId;
    _type = type;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => sl<GetAssessmentsUseCase>()(
        GetAssessmentsParams(courseId: courseId, type: type),
      ),
    );
  }

  Future<String?> add({
    required String title,
    required double maxScore,
    required String date,
  }) async {
    try {
      final created = await sl<AddAssessmentUseCase>()(
        AddAssessmentParams(
          courseId: _courseId,
          title: title,
          type: _type,
          maxScore: maxScore,
          date: date,
        ),
      );
      state = state.whenData((items) => [created, ...items]);
      return null;
    } catch (e) {
      return _humanize(e);
    }
  }

  Future<String?> delete(int id) async {
    final previous = switch (state) {
      AsyncData(:final value) => value,
      _ => const <AssessmentEntity>[],
    };
    state = AsyncData(previous.where((a) => a.id != id).toList());
    try {
      await sl<DeleteAssessmentUseCase>()(id);
      return null;
    } catch (e) {
      state = AsyncData(previous);
      return _humanize(e);
    }
  }

  void retry() {
    if (_courseId > 0) load(courseId: _courseId, type: _type);
  }

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
      'AssessmentValidationException: ',
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

final tasksProvider =
    AsyncNotifierProvider<AssessmentNotifier, List<AssessmentEntity>>(
      AssessmentNotifier.new,
    );

final examsProvider =
    AsyncNotifierProvider<AssessmentNotifier, List<AssessmentEntity>>(
      AssessmentNotifier.new,
    );
