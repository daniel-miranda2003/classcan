import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../students/presentation/providers/student_provider.dart';
import '../../domain/entities/course_entity.dart';
import '../providers/course_provider.dart';
import '../providers/course_student_counts_provider.dart';
import 'course_detail_page.dart';

class CoursesPage extends ConsumerStatefulWidget {
  final int userId;

  const CoursesPage({super.key, required this.userId});

  @override
  ConsumerState<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends ConsumerState<CoursesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(courseProvider.notifier).loadCourses(widget.userId);
      ref.read(courseStudentCountsProvider.notifier).load();
    });
    ref.listenManual(courseProvider, (prev, next) {
      if (next is AsyncData) {
        ref.read(courseStudentCountsProvider.notifier).load();
      }
    });
    ref.listenManual(studentProvider, (_, _) {
      ref.read(courseStudentCountsProvider.notifier).load();
    });
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddCourseSheet(userId: widget.userId),
    );
  }

  void _openDetail(CourseEntity course) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => CourseDetailPage(course: course)));
  }

  Future<void> _confirmDelete(CourseEntity course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar curso'),
        content: Text(
          '¿Eliminar "${course.subject}" (${course.grade})?\n'
          'También se borrarán sus registros de asistencia.',
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

    final error = await ref
        .read(courseProvider.notifier)
        .deleteCourse(course.id ?? 0);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(courseProvider);
    final username = ref.watch(
      authProvider.select((auth) => auth.user?.username ?? ''),
    );
    final counts = switch (ref.watch(courseStudentCountsProvider)) {
      AsyncData(:final value) => value,
      _ => const <int, int>{},
    };

    return Scaffold(
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(courseProvider.notifier).retry(),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return const _EmptyView();
          }
          return Column(
            children: [
              _HeroHeader(username: username, total: courses.length),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref
                      .read(courseProvider.notifier)
                      .loadCourses(widget.userId),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                    itemCount: courses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CourseCard(
                      course: courses[i],
                      studentCount: counts[courses[i].id] ?? 0,
                      onDelete: () => _confirmDelete(courses[i]),
                      onTap: () => _openDetail(courses[i]),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        tooltip: 'Nuevo curso',
        child: const Icon(Icons.add),
      ),
    );
  }
}

Color parseCourseColor(String hex) {
  final clean = hex.trim().replaceFirst('#', '');
  final normalized = clean.length == 6 ? 'FF$clean' : clean;
  final value = int.tryParse(normalized, radix: 16);
  return value == null ? const Color(0xFF6366F1) : Color(value);
}

class _CourseCard extends StatelessWidget {
  final CourseEntity course;
  final int studentCount;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.studentCount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = parseCourseColor(course.color);

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: accent),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                onTap: onTap,
                title: Text(
                  course.subject,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.grade,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$studentCount',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String username;
  final int total;

  const _HeroHeader({required this.username, required this.total});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.seed,
            Color.lerp(AppColors.seed, Colors.black, 0.25)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username.isEmpty ? 'Hola' : 'Hola, $username',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            total == 1 ? '1 curso' : '$total cursos',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
              Icons.class_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Sin cursos todavía', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Registra la primera materia que impartes con el botón +',
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

class AddCourseSheet extends ConsumerStatefulWidget {
  final int userId;

  const AddCourseSheet({super.key, required this.userId});

  @override
  ConsumerState<AddCourseSheet> createState() => _AddCourseSheetState();
}

const _presetColors = [
  '#6366F1',
  '#0EA5E9',
  '#10B981',
  '#F59E0B',
  '#EF4444',
  '#8B5CF6',
];

class _AddCourseSheetState extends ConsumerState<AddCourseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _gradeController = TextEditingController();
  String _color = _presetColors.first;
  String? _formError;
  bool _saving = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final error = await ref
        .read(courseProvider.notifier)
        .addCourse(
          subject: _subjectController.text,
          grade: _gradeController.text,
          color: _color,
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
            Text('Nuevo curso', style: theme.textTheme.titleLarge),
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
              controller: _subjectController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Materia *',
                hintText: 'Ej. Matemáticas',
                prefixIcon: Icon(Icons.book_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La materia es obligatoria'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gradeController,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Grado / Grupo *',
                hintText: 'Ej. 3° B',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El grado es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                for (final hex in _presetColors)
                  InkWell(
                    onTap: () => setState(() => _color = hex),
                    borderRadius: BorderRadius.circular(20),
                    child: CircleAvatar(
                      backgroundColor: parseCourseColor(hex),
                      child: _color == hex
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
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
                  : const Text('Guardar curso'),
            ),
          ],
        ),
      ),
    );
  }
}
