import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/attendance_provider.dart';

class AttendancePage extends ConsumerStatefulWidget {
  final int courseId;
  final String? courseName;

  const AttendancePage({super.key, required this.courseId, this.courseName});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(attendanceProvider.notifier)
          .load(courseId: widget.courseId, date: todayAttendanceDate()),
    );
  }

  Future<void> _pickDate(String current) async {
    final initial = DateTime.tryParse(current) ?? DateTime.now();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null && mounted) {
      await ref
          .read(attendanceProvider.notifier)
          .changeDate(formatAttendanceDate(picked));
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = await ref.read(attendanceProvider.notifier).submit();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
        );
      return;
    }
    final state = ref.read(attendanceProvider);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => _AttendanceSummaryDialog(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attendanceProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.courseName ?? 'Pase de lista'),
            Text(
              _prettyDate(state.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cambiar fecha',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: state.isLoading ? null : () => _pickDate(state.date),
          ),
        ],
      ),
      body: _Body(
        state: state,
        onRetry: () => ref.read(attendanceProvider.notifier).retry(),
      ),
      floatingActionButton: state.isLoading || state.rows.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: state.isSaving ? null : _submit,
              icon: state.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar'),
            ),
    );
  }

  String _prettyDate(String iso) {
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

class _Body extends ConsumerWidget {
  final AttendanceState state;
  final VoidCallback onRetry;

  const _Body({required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.rows.isEmpty) {
      return _ErrorView(message: state.errorMessage!, onRetry: onRetry);
    }
    if (state.rows.isEmpty) {
      return const _EmptyView();
    }
    return Column(
      children: [
        _SummaryBar(state: state),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: state.rows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final row = state.rows[i];
              return _StudentRow(
                row: row,
                onChanged: (status) => ref
                    .read(attendanceProvider.notifier)
                    .setStatus(studentId: row.student.id ?? 0, status: status),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final AttendanceState state;

  const _SummaryBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _Counter(
            label: 'Presentes',
            value: state.presentCount,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          _Counter(
            label: 'Tarde',
            value: state.lateCount,
            color: AppColors.late,
          ),
          const SizedBox(width: 8),
          _Counter(
            label: 'Ausentes',
            value: state.absentCount,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  final AttendanceRow row;
  final ValueChanged<String> onChanged;

  const _StudentRow({required this.row, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.student.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatusOption(
                  selected: row.status == 'PRESENT',
                  color: const Color(0xFF16A34A),
                  icon: Icons.check,
                  label: 'Presente',
                  onTap: () => onChanged('PRESENT'),
                ),
                const SizedBox(width: 8),
                _StatusOption(
                  selected: row.status == 'LATE',
                  color: const Color(0xFFF59E0B),
                  icon: Icons.schedule,
                  label: 'Tarde',
                  onTap: () => onChanged('LATE'),
                ),
                const SizedBox(width: 8),
                _StatusOption(
                  selected: row.status == 'ABSENT',
                  color: theme.colorScheme.error,
                  icon: Icons.close,
                  label: 'Ausente',
                  onTap: () => onChanged('ABSENT'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOption extends StatelessWidget {
  final bool selected;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _StatusOption({
    required this.selected,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected ? Colors.white : color;
    return Expanded(
      child: Material(
        color: selected ? color : color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: selected
                ? null
                : BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(14),
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Text('Sin estudiantes', style: theme.textTheme.titleLarge),
            Text(
              'Registra estudiantes para pasar lista',
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

class _AttendanceSummaryDialog extends StatelessWidget {
  final AttendanceState state;

  const _AttendanceSummaryDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absentToday = state.rows.where((r) => r.status == 'ABSENT').toList();
    final recurrent = state.rows.where((r) => r.student.absences >= 2).toList()
      ..sort((a, b) => b.student.absences.compareTo(a.student.absences));

    return AlertDialog(
      backgroundColor: Colors.white,
      icon: CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.primaryContainer,
        foregroundColor: theme.colorScheme.onPrimaryContainer,
        child: const Icon(Icons.check, size: 32),
      ),
      title: const Text('¡Registrado con éxito!', textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Faltas de hoy: ${absentToday.length}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estudiantes con faltas recurrentes:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (recurrent.isEmpty)
              Text(
                'Ninguno por el momento.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: recurrent.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (_, i) {
                      final row = recurrent[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          row.student.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${row.student.absences} faltas',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Editar'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Continuar'),
        ),
      ],
    );
  }
}
