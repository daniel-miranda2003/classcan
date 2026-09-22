import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:classcan/features/assessments/presentation/pages/evaluations_page.dart';
import 'package:classcan/features/attendance/presentation/pages/attendance_page.dart';
import 'package:classcan/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:classcan/features/auth/presentation/pages/login_page.dart';
import 'package:classcan/features/courses/domain/entities/course_entity.dart';
import 'package:classcan/features/courses/presentation/providers/course_provider.dart';
import 'package:classcan/features/students/domain/entities/student_entity.dart';
import 'package:classcan/features/students/presentation/pages/students_page.dart';
import 'package:classcan/features/students/presentation/providers/student_provider.dart';
import 'package:classcan/shared/widgets/home_shell.dart';

class _FakeStudentNotifier extends StudentNotifier {
  @override
  Future<List<StudentEntity>> build() async => [];

  @override
  Future<void> loadStudents() async {
    state = const AsyncData([]);
  }
}

class _FakeCourseNotifier extends CourseNotifier {
  @override
  Future<List<CourseEntity>> build() async => [];

  @override
  Future<void> loadCourses(int userId) async {
    state = const AsyncData([]);
  }
}

class _FakeAttendanceNotifier extends AttendanceNotifier {
  @override
  AttendanceState build() => AttendanceState(date: todayAttendanceDate());

  @override
  Future<void> load({required int courseId, required String date}) async {
    state = AttendanceState(
      courseId: courseId,
      date: date,
      rows: const [
        AttendanceRow(
          student: StudentEntity(firstName: 'Ana', paternalLastName: 'García'),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('LoginPage renderiza formulario sin tocar la DB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('StudentsPage renderiza lista vacia sin tocar la DB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studentProvider.overrideWith(_FakeStudentNotifier.new),
        ],
        child: const MaterialApp(home: StudentsPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Estudiantes'), findsOneWidget);
    expect(find.text('Sin estudiantes todavía'), findsOneWidget);
  });

  testWidgets('HomeShell alterna entre Cursos y Evaluaciones',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseProvider.overrideWith(_FakeCourseNotifier.new),
          studentProvider.overrideWith(_FakeStudentNotifier.new),
        ],
        child: const MaterialApp(home: HomeShell(userId: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('Cursos'), findsWidgets);
    await tester.tap(find.text('Evaluaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Primero crea un curso en la pestaña Cursos'), findsOneWidget);
  });

  testWidgets('HomeShell expone las 3 tabs sin dashboard intermedio',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseProvider.overrideWith(_FakeCourseNotifier.new),
          studentProvider.overrideWith(_FakeStudentNotifier.new),
        ],
        child: const MaterialApp(home: HomeShell(userId: 1)),
      ),
    );
    await tester.pump();

    for (final label in ['Cursos', 'Evaluaciones', 'Notas']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('Notas'));
    await tester.pumpAndSettle();

    expect(find.text('Elige un curso para empezar'), findsOneWidget);
  });

  testWidgets('EvaluationsPage conmuta Tareas y Examenes sin DB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courseProvider.overrideWith(_FakeCourseNotifier.new),
        ],
        child: const MaterialApp(home: EvaluationsPage(userId: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('Tareas'), findsWidgets);
    expect(find.text('Exámenes'), findsWidgets);
    expect(find.text('Primero crea un curso en la pestaña Cursos'), findsOneWidget);
    await tester.tap(find.text('Exámenes'));
    await tester.pump();
    expect(find.byType(SegmentedButton<String>), findsOneWidget);
  });

  testWidgets('AttendancePage muestra lista y control de estados sin DB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          attendanceProvider.overrideWith(_FakeAttendanceNotifier.new),
        ],
        child: const MaterialApp(
          home: AttendancePage(courseId: 1, courseName: 'Matemáticas'),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Matemáticas'), findsOneWidget);
    expect(find.text('Ana García'), findsOneWidget);
    expect(find.text('Presente'), findsWidgets);
    expect(find.text('Tarde'), findsWidgets);
    expect(find.text('Ausente'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });
}
