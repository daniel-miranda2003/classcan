import 'package:flutter/material.dart';

import '../../../attendance/presentation/pages/attendance_page.dart';
import '../../../students/presentation/pages/students_page.dart';
import '../../domain/entities/course_entity.dart';

class CourseDetailPage extends StatelessWidget {
  final CourseEntity course;

  const CourseDetailPage({super.key, required this.course});

  void _openStudents(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StudentsPage(courseId: course.id ?? 0),
      ),
    );
  }

  void _openAttendance(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttendancePage(
          courseId: course.id ?? 0,
          courseName: '${course.subject} · ${course.grade}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(course.subject)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.class_,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    course.subject,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    course.grade,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.people_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Estudiantes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Ver lista y agregar estudiantes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openStudents(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Icon(
                    Icons.fact_check_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Pasar lista',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Registrar asistencia de hoy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openAttendance(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
