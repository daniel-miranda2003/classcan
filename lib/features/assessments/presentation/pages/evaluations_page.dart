import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/assessment_board.dart';
import '../../../grades/presentation/pages/grades_page.dart';
import '../../domain/entities/assessment_entity.dart';
import '../providers/assessment_provider.dart';
import '../../../courses/presentation/providers/course_provider.dart';

class EvaluationsPage extends ConsumerStatefulWidget {
  final int userId;

  const EvaluationsPage({super.key, required this.userId});

  @override
  ConsumerState<EvaluationsPage> createState() => _EvaluationsPageState();
}

class _EvaluationsPageState extends ConsumerState<EvaluationsPage> {
  String _type = 'TASK';

  bool get _isTask => _type == 'TASK';

  void _showAddSheet() {
    final provider = _isTask ? tasksProvider : examsProvider;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddAssessmentSheet(
        itemLabel: _isTask ? 'tarea' : 'examen',
        onSave:
            ({
              required String title,
              required double maxScore,
              required String date,
            }) => ref
                .read(provider.notifier)
                .add(title: title, maxScore: maxScore, date: date),
      ),
    );
  }

  void _openGrades(AssessmentEntity item, int courseId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GradesPage(
          userId: widget.userId,
          initialCourseId: courseId,
          initialAssessmentId: item.id ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coursesAsync = ref.watch(courseProvider);
    final hasCourses = switch (coursesAsync) {
      AsyncData(:final value) => value.isNotEmpty,
      _ => false,
    };
    final activeProvider = _isTask ? tasksProvider : examsProvider;
    final count = switch (ref.watch(activeProvider)) {
      AsyncData(:final value) => value.length,
      _ => 0,
    };

    return Scaffold(
      body: Column(
        children: [
          Card(
            elevation: 0,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            color: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: 'TASK',
                          icon: Icon(Icons.assignment_outlined),
                          label: Text('Tareas'),
                        ),
                        ButtonSegment(
                          value: 'EXAM',
                          icon: Icon(Icons.quiz_outlined),
                          label: Text('Exámenes'),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (set) =>
                          setState(() => _type = set.single),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AssessmentBoard(
              key: ValueKey(_type),
              userId: widget.userId,
              type: _type,
              itemLabel: _isTask ? 'tarea' : 'examen',
              provider: activeProvider,
              onTap: _openGrades,
            ),
          ),
        ],
      ),
      floatingActionButton: hasCourses
          ? FloatingActionButton(
              onPressed: _showAddSheet,
              tooltip: _isTask ? 'Nueva tarea' : 'Nuevo examen',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
