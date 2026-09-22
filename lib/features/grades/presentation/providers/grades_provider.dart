import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../assessments/domain/entities/assessment_entity.dart';
import '../../../assessments/domain/usecases/get_assessments_usecase.dart';
import '../../../students/domain/entities/student_entity.dart';
import '../../../students/domain/usecases/get_students_by_course_usecase.dart';
import '../../../students/domain/usecases/get_students_usecase.dart';
import '../../domain/entities/grade_entity.dart';
import '../../domain/usecases/get_grades_usecase.dart';
import '../../domain/usecases/save_grades_usecase.dart';

class GradeRow extends Equatable {
  final StudentEntity student;
  final double? savedScore;

  const GradeRow({required this.student, this.savedScore});

  @override
  List<Object?> get props => [student, savedScore];
}

class GradesState extends Equatable {
  final int courseId;
  final List<AssessmentEntity> assessments;
  final int? assessmentId;
  final List<GradeRow> rows;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const GradesState({
    this.courseId = 0,
    this.assessments = const [],
    this.assessmentId,
    this.rows = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  AssessmentEntity? get selectedAssessment {
    for (final a in assessments) {
      if (a.id == assessmentId) return a;
    }
    return null;
  }

  GradesState copyWith({
    int? courseId,
    List<AssessmentEntity>? assessments,
    int? Function()? assessmentId,
    List<GradeRow>? rows,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return GradesState(
      courseId: courseId ?? this.courseId,
      assessments: assessments ?? this.assessments,
      assessmentId: assessmentId != null ? assessmentId() : this.assessmentId,
      rows: rows ?? this.rows,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    courseId,
    assessments,
    assessmentId,
    rows,
    isLoading,
    isSaving,
    errorMessage,
  ];
}

class GradesNotifier extends Notifier<GradesState> {
  final Map<int, TextEditingController> controllers = {};

  @override
  GradesState build() {
    ref.onDispose(_disposeControllers);
    return const GradesState();
  }

  void _disposeControllers() {
    for (final c in controllers.values) {
      c.dispose();
    }
    controllers.clear();
  }

  void _resetControllers(Map<int, double> initial) {
    _disposeControllers();
    for (final entry in initial.entries) {
      controllers[entry.key] = TextEditingController(
        text: _formatScore(entry.value),
      );
    }
  }

  static String _formatScore(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : '$v';

  Future<void> selectCourse(int courseId) async {
    _resetControllers(const {});
    state = state.copyWith(
      courseId: courseId,
      assessments: [],
      assessmentId: () => null,
      rows: [],
      isLoading: true,
      errorMessage: null,
    );
    try {
      final results = await Future.wait([
        sl<GetAssessmentsUseCase>()(
          GetAssessmentsParams(courseId: courseId, type: 'TASK'),
        ),
        sl<GetAssessmentsUseCase>()(
          GetAssessmentsParams(courseId: courseId, type: 'EXAM'),
        ),
      ]);
      final all = [...results[0], ...results[1]]
        ..sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(isLoading: false, assessments: all);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _humanize(e));
    }
  }

  Future<void> selectAssessment(int assessmentId) async {
    _resetControllers(const {});
    state = state.copyWith(
      assessmentId: () => assessmentId,
      rows: [],
      isLoading: true,
      errorMessage: null,
    );
    try {
      final studentsFuture = state.courseId > 0
          ? sl<GetStudentsByCourseUseCase>()(state.courseId)
          : sl<GetStudentsUseCase>()(NoParams());
      final results = await Future.wait([
        studentsFuture,
        sl<GetGradesUseCase>()(assessmentId),
      ]);
      final students = results[0] as List<StudentEntity>;
      final grades = results[1] as List<GradeEntity>;
      final byStudent = {for (final g in grades) g.studentId: g.score};

      _resetControllers({
        for (final s in students)
          if (s.id != null && byStudent[s.id] != null) s.id!: byStudent[s.id]!,
      });
      for (final s in students) {
        if (s.id != null) {
          controllers.putIfAbsent(s.id!, TextEditingController.new);
        }
      }

      state = state.copyWith(
        isLoading: false,
        rows: [
          for (final s in students)
            GradeRow(
              student: s,
              savedScore: s.id == null ? null : byStudent[s.id],
            ),
        ],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _humanize(e));
    }
  }

  Future<String?> submit() async {
    final assessment = state.selectedAssessment;
    if (assessment == null || assessment.id == null) {
      return 'Selecciona una evaluación';
    }
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      final grades = <GradeEntity>[];
      for (final row in state.rows) {
        final id = row.student.id;
        if (id == null) continue;
        final raw = controllers[id]?.text.trim() ?? '';
        if (raw.isEmpty) continue;
        final score = double.tryParse(raw.replaceAll(',', '.'));
        if (score == null) {
          throw GradeValidationException(
            'Nota inválida para ${row.student.shortName}',
          );
        }
        grades.add(
          GradeEntity(
            assessmentId: assessment.id!,
            studentId: id,
            score: score,
          ),
        );
      }
      await sl<SaveGradesUseCase>()(
        SaveGradesParams(
          assessmentId: assessment.id!,
          maxScore: assessment.maxScore,
          grades: grades,
        ),
      );
      state = state.copyWith(
        isSaving: false,
        rows: [
          for (final row in state.rows)
            GradeRow(
              student: row.student,
              savedScore: _savedValue(row, grades),
            ),
        ],
      );
      return null;
    } catch (e) {
      final message = _humanize(e);
      state = state.copyWith(isSaving: false, errorMessage: message);
      return message;
    }
  }

  double? _savedValue(GradeRow row, List<GradeEntity> grades) {
    for (final g in grades) {
      if (g.studentId == row.student.id) return g.score;
    }
    return row.savedScore;
  }

  Future<void> retry() {
    final id = state.assessmentId;
    if (id != null) {
      return selectAssessment(id);
    } else if (state.courseId > 0) {
      return selectCourse(state.courseId);
    }
    return Future.value();
  }

  String _humanize(Object e) {
    final raw = e.toString();
    const prefixes = [
      'GradeValidationException: ',
      'AssessmentValidationException: ',
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

final gradesProvider = NotifierProvider<GradesNotifier, GradesState>(
  GradesNotifier.new,
);
