import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/student_entity.dart';
import '../providers/student_provider.dart';

class StudentsPage extends ConsumerStatefulWidget {
  final int? courseId;

  const StudentsPage({super.key, this.courseId});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  @override
  void initState() {
    super.initState();
    final courseId = widget.courseId;
    Future.microtask(
      () => courseId == null
          ? ref.read(studentProvider.notifier).loadStudents()
          : ref.read(studentProvider.notifier).loadStudentsByCourse(courseId),
    );
  }

  Future<void> _reload() {
    final courseId = widget.courseId;
    final notifier = ref.read(studentProvider.notifier);
    return courseId == null
        ? notifier.loadStudents()
        : notifier.loadStudentsByCourse(courseId);
  }

  void _showAddSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AddStudentSheet(),
    );
  }

  Future<void> _confirmDelete(StudentEntity student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar estudiante'),
        content: Text(
          '¿Eliminar a ${student.displayName}?\n'
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
        .read(studentProvider.notifier)
        .deleteStudent(student.id ?? 0);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
    }
  }

  void _showDetail(StudentEntity student) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (_) => _StudentDetailSheet(
        student: student,
        onDelete: () => _confirmDelete(student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentProvider);
    final username = ref.watch(
      authProvider.select((auth) => auth.user?.username ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudiantes'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            position: PopupMenuPosition.under,
            offset: const Offset(0, 8),
            onSelected: (_) => ref.read(authProvider.notifier).logout(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_outlined,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    const Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_outlined),
                  const SizedBox(width: 6),
                  Text(
                    username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => _reload(),
        ),
        data: (students) {
          if (students.isEmpty) {
            return const _EmptyView();
          }
          return RefreshIndicator(
            onRefresh: () => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: students.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _StudentCard(
                student: students[i],
                onDelete: () => _confirmDelete(students[i]),
                onTap: () => _showDetail(students[i]),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        tooltip: 'Nuevo estudiante',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _StudentCard({
    required this.student,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: student.isFailing
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: student.isFailing
            ? BorderSide(color: theme.colorScheme.error, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        title: Text(
          student.displayName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: student.isFailing
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.absences == 0
                  ? 'Sin ausencias'
                  : student.absences == 1
                  ? '1 ausencia'
                  : '${student.absences} ausencias',
            ),
            if (student.averagePercentage != null)
              Text(
                'Promedio: ${student.averagePercentage!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: student.isFailing
                      ? theme.colorScheme.error
                      : Colors.green.shade800,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (student.averagePercentage != null)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: student.isFailing
                      ? theme.colorScheme.errorContainer
                      : Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  student.isFailing
                      ? 'Reprobado'
                      : 'Aprobado',
                  style: TextStyle(
                    color: student.isFailing
                        ? theme.colorScheme.onErrorContainer
                        : Colors.green.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentDetailSheet extends StatelessWidget {
  final StudentEntity student;
  final VoidCallback onDelete;

  const _StudentDetailSheet({required this.student, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      student.attendanceStatus.isEmpty
                          ? 'Sin estado registrado'
                          : 'Estado: ${student.attendanceStatus}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: student.isFailing
                  ? theme.colorScheme.errorContainer
                  : student.isPassing
                  ? Colors.green.shade100
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  student.isFailing
                      ? Icons.warning_amber_rounded
                      : student.isPassing
                      ? Icons.check_circle_outline
                      : Icons.grade_outlined,
                  color: student.isFailing
                      ? theme.colorScheme.onErrorContainer
                      : student.isPassing
                      ? Colors.green.shade900
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.averagePercentage == null
                            ? 'Sin calificaciones en evaluaciones'
                            : student.isFailing
                            ? 'Reprobado (${student.averagePercentage!.toStringAsFixed(1)}%)'
                            : 'Aprobado (${student.averagePercentage!.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: student.isFailing
                              ? theme.colorScheme.onErrorContainer
                              : student.isPassing
                              ? Colors.green.shade900
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (student.averagePercentage != null)
                        Text(
                          'Nota mínima de aprobación: 51.0%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: student.isFailing
                                ? theme.colorScheme.onErrorContainer.withValues(alpha: 0.8)
                                : Colors.green.shade800,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  student.absences == 0
                      ? 'Sin ausencias acumuladas'
                      : student.absences == 1
                      ? '1 ausencia acumulada'
                      : '${student.absences} ausencias acumuladas',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar estudiante'),
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
              Icons.people_outline,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Sin estudiantes todavía', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Registra al primer estudiante con el botón +',
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

class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({super.key});

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _paternalController = TextEditingController();
  final _maternalController = TextEditingController();
  String? _formError;
  bool _saving = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _paternalController.dispose();
    _maternalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _formError = null;
    });
    final error = await ref
        .read(studentProvider.notifier)
        .addStudent(
          firstName: _firstNameController.text,
          middleName: _middleNameController.text,
          paternalLastName: _paternalController.text,
          maternalLastName: _maternalController.text,
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
            Text('Nuevo estudiante', style: theme.textTheme.titleLarge),
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
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'Ej. Ana',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middleNameController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Segundo Nombre',
                hintText: 'Ej. María (opcional)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _paternalController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Apellido Paterno *',
                hintText: 'Ej. García',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El apellido paterno es obligatorio'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maternalController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Apellido Materno',
                hintText: 'Ej. López (opcional)',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
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
                  : const Text('Guardar estudiante'),
            ),
          ],
        ),
      ),
    );
  }
}
