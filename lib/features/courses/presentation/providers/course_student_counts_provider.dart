import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../students/domain/usecases/get_student_counts_usecase.dart';

class CourseStudentCountsNotifier extends AsyncNotifier<Map<int, int>> {
  @override
  Future<Map<int, int>> build() async => const {};

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => sl<GetStudentCountsUseCase>()(NoParams()),
    );
  }
}

final courseStudentCountsProvider =
    AsyncNotifierProvider<CourseStudentCountsNotifier, Map<int, int>>(
  CourseStudentCountsNotifier.new,
);
