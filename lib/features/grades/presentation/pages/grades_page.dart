import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../assessments/domain/entities/assessment_entity.dart';
import '../../../courses/domain/entities/course_entity.dart';
import '../../../courses/presentation/providers/course_provider.dart';
import '../providers/grades_provider.dart';

class GradesPage extends ConsumerStatefulWidget {
  final int userId;
  final int initialCourseId;
  final int initialAssessmentId;

  const GradesPage({
    super.key,
    required this.userId,
    this.initialCourseId = 0,
    this.initialAssessmentId = 0,
  });

  @override
  ConsumerState<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends ConsumerState<GradesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(courseProvider.notifier)
          .loadCoursesIfNeeded(widget.userId);
      if (widget.initialCourseId > 0 && mounted) {
        await ref
            .read(gradesProvider.notifier)
            .selectCourse(widget.initialCourseId);
        if (widget.initialAssessmentId > 0 && mounted) {
          await ref
              .read(gradesProvider.notifier)
              .selectAssessment(widget.initialAssessmentId);
        }
      }
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = await ref.read(gradesProvider.notifier).submit();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error ?? 'Notas guardadas'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(courseProvider);
    final grades = ref.watch(gradesProvider);
    final notifier = ref.read(gradesProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          _FiltersCard(
            coursesAsync: coursesAsync,
            assessments: grades.assessments,
            courseId: grades.courseId,
            assessmentId: grades.assessmentId,
            isLoadingFilters: grades.isLoading && grades.rows.isEmpty,
            onCourseChanged: notifier.selectCourse,
            onAssessmentChanged: notifier.selectAssessment,
            onRetryCourses: () =>
                ref.read(courseProvider.notifier).loadCourses(widget.userId),
          ),
          Expanded(child: _GradesBody(onRetry: notifier.retry)),
        ],
      ),
      floatingActionButton: grades.assessmentId == null || grades.rows.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: grades.isSaving ? null : _submit,
              icon: grades.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar Notas'),
            ),
    );
  }
}

class _FiltersCard extends StatelessWidget {
  final AsyncValue<List<CourseEntity>> coursesAsync;
  final List<AssessmentEntity> assessments;
  final int courseId;
  final int? assessmentId;
  final bool isLoadingFilters;
  final ValueChanged<int> onCourseChanged;
  final ValueChanged<int> onAssessmentChanged;
  final VoidCallback onRetryCourses;

  const _FiltersCard({
    required this.coursesAsync,
    required this.assessments,
    required this.courseId,
    required this.assessmentId,
    required this.isLoadingFilters,
    required this.onCourseChanged,
    required this.onAssessmentChanged,
    required this.onRetryCourses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            coursesAsync.when(
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (_, _) => Row(
                children: [
                  const Expanded(child: Text('Error al cargar cursos')),
                  TextButton(
                    onPressed: onRetryCourses,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
              data: (courses) {
                if (courses.isEmpty) {
                  return const Text(
                    'Primero crea un curso en la pestaña Cursos',
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) => DropdownMenu<int>(
                    width: constraints.maxWidth,
                    initialSelection: courses.any((c) => c.id == courseId)
                        ? courseId
                        : null,
                    hintText: 'Elige un curso',
                    label: const Text('1. Curso'),
                    leadingIcon: Icon(
                      Icons.class_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    dropdownMenuEntries: [
                      for (final c in courses)
                        DropdownMenuEntry(
                          value: c.id ?? 0,
                          label: '${c.subject} · ${c.grade}',
                        ),
                    ],
                    onSelected: (id) {
                      if (id != null && id != courseId) onCourseChanged(id);
                    },
                  ),
                );
              },
            ),
            if (courseId > 0) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) => DropdownMenu<int>(
                  width: constraints.maxWidth,
                  enabled: assessments.isNotEmpty,
                  initialSelection: assessments.any((a) => a.id == assessmentId)
                      ? assessmentId
                      : null,
                  hintText: 'Elige una evaluación',
                  label: const Text('2. Evaluación'),
                  leadingIcon: Icon(
                    Icons.assignment_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  dropdownMenuEntries: [
                    for (final a in assessments)
                      DropdownMenuEntry(
                        value: a.id ?? 0,
                        label: a.title,
                        leadingIcon: Icon(
                          a.type == 'TASK'
                              ? Icons.assignment_outlined
                              : Icons.quiz_outlined,
                        ),
                        trailingIcon: Text(
                          'máx. ${_fmt(a.maxScore)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                  onSelected: (id) {
                    if (id != null && id != assessmentId) {
                      onAssessmentChanged(id);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : '$v';
}

class _GradesBody extends ConsumerWidget {
  final Future<void> Function() onRetry;

  const _GradesBody({required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradesProvider);
    final theme = Theme.of(context);

    if (state.courseId == 0) {
      return _HintView(
        icon: Icons.touch_app_outlined,
        title: 'Elige un curso para empezar',
        subtitle: 'Luego selecciona la evaluación a calificar.',
      );
    }
    if (state.isLoading && state.rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.rows.isEmpty) {
      return _ErrorView(message: state.errorMessage!, onRetry: onRetry);
    }
    if (state.assessmentId == null) {
      return _HintView(
        icon: Icons.assignment_outlined,
        title: state.assessments.isEmpty
            ? 'Este curso aún no tiene evaluaciones'
            : 'Selecciona una evaluación',
        subtitle: state.assessments.isEmpty
            ? 'Créalas en la pestaña Evaluaciones.'
            : 'Verás la lista de estudiantes para calificar.',
      );
    }
    if (state.rows.isEmpty) {
      return _EmptyStudentsView(onRefresh: onRetry);
    }

    final max = state.selectedAssessment?.maxScore;
    final notifier = ref.read(gradesProvider.notifier);
    final graded = state.rows.where((r) => r.savedScore != null).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Calificados: $graded de ${state.rows.length}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
            itemCount: state.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final row = state.rows[i];
              final id = row.student.id;
              final controller = id == null
                  ? TextEditingController()
                  : notifier.controllers.putIfAbsent(
                      id,
                      TextEditingController.new,
                    );
              return _GradeCard(
                name: row.student.displayName,
                savedScore: row.savedScore,
                max: max,
                controller: controller,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GradeCard extends StatelessWidget {
  final String name;
  final double? savedScore;
  final double? max;
  final TextEditingController controller;

  const _GradeCard({
    required this.name,
    required this.savedScore,
    required this.max,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      savedScore == null
                          ? 'Sin calificar'
                          : 'Guardada: ${_fmt(savedScore!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 118,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  hintText: '—',
                  suffixText: max == null ? null : '/ ${_fmt(max!)}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : '$v';
}

class _HintView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _HintView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStudentsView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyStudentsView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sin estudiantes para calificar',
                      style: theme.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Si ya registraste estudiantes y siguen sin aparecer, desliza hacia abajo para recargar.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.swipe_down_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
