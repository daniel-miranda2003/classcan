import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/assessments/domain/entities/assessment_entity.dart';
import '../../features/assessments/presentation/providers/assessment_provider.dart';
import '../../features/courses/domain/entities/course_entity.dart';
import '../../features/courses/presentation/providers/course_provider.dart';

class AssessmentBoard extends ConsumerStatefulWidget {
  final int userId;
  final String type;
  final String itemLabel;
  final AsyncNotifierProvider<AssessmentNotifier, List<AssessmentEntity>>
  provider;
  final void Function(AssessmentEntity item, int courseId)? onTap;

  const AssessmentBoard({
    super.key,
    required this.userId,
    required this.type,
    required this.itemLabel,
    required this.provider,
    this.onTap,
  });

  @override
  ConsumerState<AssessmentBoard> createState() => _AssessmentBoardState();
}

class _AssessmentBoardState extends ConsumerState<AssessmentBoard> {
  int _courseId = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref
          .read(courseProvider.notifier)
          .loadCoursesIfNeeded(widget.userId);
      if (!mounted || _courseId != 0) return;
      final courses = switch (ref.read(courseProvider)) {
        AsyncData(:final value) => value,
        _ => const <CourseEntity>[],
      };
      if (courses.isNotEmpty) {
        _selectCourse(courses.first.id ?? 0);
      }
    });
  }

  void _selectCourse(int courseId) {
    setState(() => _courseId = courseId);
    ref
        .read(widget.provider.notifier)
        .load(courseId: courseId, type: widget.type);
  }

  /*
  Future<void> _confirmDelete(AssessmentEntity item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${widget.itemLabel}'),
        content: Text(
          '¿Eliminar "${item.title}"?\nTambién se borrarán sus notas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref.read(widget.provider.notifier).delete(item.id ?? 0);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
    }
  }
  */

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(courseProvider);
    final itemsAsync = ref.watch(widget.provider);
    ref.listen<AsyncValue<List<CourseEntity>>>(courseProvider, (_, next) {
      final courses = switch (next) {
        AsyncData(:final value) => value,
        _ => null,
      };
      if (_courseId == 0 && courses != null && courses.isNotEmpty && mounted) {
        _selectCourse(courses.first.id ?? 0);
      }
    });

    return Column(
      children: [
        _CourseSelector(
          coursesAsync: coursesAsync,
          selectedId: _courseId,
          onChanged: _selectCourse,
          onRetry: () =>
              ref.read(courseProvider.notifier).loadCourses(widget.userId),
        ),
        Expanded(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.read(widget.provider.notifier).retry(),
            ),
            data: (items) {
              if (_courseId == 0) {
                return const _EmptyCoursesView();
              }
              if (items.isEmpty) {
                return const _EmptyItemsView();
              }
              return RefreshIndicator(
                onRefresh: () => ref
                    .read(widget.provider.notifier)
                    .load(courseId: _courseId, type: widget.type),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AssessmentCard(
                    item: items[i],
                    icon: widget.type == 'TASK'
                        ? Icons.assignment_outlined
                        : Icons.quiz_outlined,
                    onDelete: () {},
                    onTap: widget.onTap == null
                        ? null
                        : () => widget.onTap!(items[i], _courseId),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CourseSelector extends StatelessWidget {
  final AsyncValue<List<CourseEntity>> coursesAsync;
  final int selectedId;
  final ValueChanged<int> onChanged;
  final VoidCallback onRetry;

  const _CourseSelector({
    required this.coursesAsync,
    required this.selectedId,
    required this.onChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: theme.colorScheme.surfaceContainer,
      child: coursesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, _) => Row(
          children: [
            const Expanded(child: Text('No se pudieron cargar los cursos')),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const Text('Primero crea un curso en la pestaña Cursos');
          }
          final validId = courses.any((c) => c.id == selectedId)
              ? selectedId
              : null;
          return LayoutBuilder(
            builder: (context, constraints) => DropdownMenu<int>(
              width: constraints.maxWidth,
              initialSelection: validId,
              hintText: 'Elige un curso',
              label: const Text('Curso activo'),
              leadingIcon: const Icon(Icons.class_outlined),
              dropdownMenuEntries: [
                for (final c in courses)
                  DropdownMenuEntry(
                    value: c.id ?? 0,
                    label: '${c.subject} · ${c.grade}',
                  ),
              ],
              onSelected: (id) {
                if (id != null) onChanged(id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final AssessmentEntity item;
  final IconData icon;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const _AssessmentCard({
    required this.item,
    required this.icon,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_prettyDate(item.date)} · Máx. ${_fmt(item.maxScore)}',
        ),
        trailing: FilledButton.tonalIcon(
          onPressed: onTap,
          icon: const Icon(Icons.edit_note, size: 18),
          label: const Text('Calificar'),
        ),
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.truncateToDouble() ? '${v.toInt()}' : '$v';

  static String _prettyDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}

class _EmptyCoursesView extends StatelessWidget {
  const _EmptyCoursesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Crea primero un curso en la pestaña Cursos',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _EmptyItemsView extends StatelessWidget {
  const _EmptyItemsView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Sin registros todavía',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón + para agregar el primero',
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
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

class AddAssessmentSheet extends StatefulWidget {
  final String itemLabel;
  final Future<String?> Function({
    required String title,
    required double maxScore,
    required String date,
  })
  onSave;

  const AddAssessmentSheet({
    super.key,
    required this.itemLabel,
    required this.onSave,
  });

  @override
  State<AddAssessmentSheet> createState() => AddAssessmentSheetState();
}

class AddAssessmentSheetState extends State<AddAssessmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _maxController = TextEditingController(text: '100');
  DateTime _date = DateTime.now();
  String? _formError;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  String get _isoDate =>
      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final max = double.tryParse(_maxController.text.replaceAll(',', '.')) ?? 0;
    final error = await widget.onSave(
      title: _titleController.text,
      maxScore: max,
      date: _isoDate,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _formError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nueva ${widget.itemLabel}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_formError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formError!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Título *',
                hintText: widget.itemLabel == 'tarea'
                    ? 'Ej. Ejercicios pág. 42'
                    : 'Ej. Parcial 1',
                prefixIcon: const Icon(Icons.title_outlined),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El título es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nota máxima *',
                      prefixIcon: Icon(Icons.star_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return (n == null || n <= 0) ? 'Debe ser > 0' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_isoDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
