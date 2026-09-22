import 'package:get_it/get_it.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/courses/data/datasources/course_local_data_source.dart';
import '../../features/courses/data/repositories/course_repository_impl.dart';
import '../../features/courses/domain/repositories/course_repository.dart';
import '../../features/courses/domain/usecases/add_course_usecase.dart';
import '../../features/courses/domain/usecases/delete_course_usecase.dart';
import '../../features/courses/domain/usecases/get_courses_usecase.dart';
import '../../features/students/data/datasources/student_local_data_source.dart';
import '../../features/students/data/repositories/student_repository_impl.dart';
import '../../features/students/domain/repositories/student_repository.dart';
import '../../features/students/domain/usecases/add_student_usecase.dart';
import '../../features/students/domain/usecases/delete_student_usecase.dart';
import '../../features/students/domain/usecases/get_student_counts_usecase.dart';
import '../../features/students/domain/usecases/get_students_by_course_usecase.dart';
import '../../features/students/domain/usecases/get_students_usecase.dart';
import '../../features/attendance/data/datasources/attendance_local_data_source.dart';
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance_usecase.dart';
import '../../features/attendance/domain/usecases/save_attendance_usecase.dart';
import '../../features/assessments/data/datasources/assessment_local_data_source.dart';
import '../../features/assessments/data/repositories/assessment_repository_impl.dart';
import '../../features/assessments/domain/repositories/assessment_repository.dart';
import '../../features/assessments/domain/usecases/add_assessment_usecase.dart';
import '../../features/assessments/domain/usecases/delete_assessment_usecase.dart';
import '../../features/assessments/domain/usecases/get_assessments_usecase.dart';
import '../../features/grades/data/datasources/grade_local_data_source.dart';
import '../../features/grades/data/repositories/grade_repository_impl.dart';
import '../../features/grades/domain/repositories/grade_repository.dart';
import '../../features/grades/domain/usecases/get_grades_usecase.dart';
import '../../features/grades/domain/usecases/save_grades_usecase.dart';
import '../database/database_helper.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  sl.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton<CourseLocalDataSource>(
    () => CourseLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetCoursesUseCase(sl()));
  sl.registerLazySingleton(() => AddCourseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCourseUseCase(sl()));
  sl.registerLazySingleton<StudentLocalDataSource>(
    () => StudentLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<StudentRepository>(
    () => StudentRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetStudentsUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentsByCourseUseCase(sl()));
  sl.registerLazySingleton(() => GetStudentCountsUseCase(sl()));
  sl.registerLazySingleton(() => AddStudentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteStudentUseCase(sl()));
  sl.registerLazySingleton<AttendanceLocalDataSource>(
    () => AttendanceLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAttendanceUseCase(sl()));
  sl.registerLazySingleton(() => SaveAttendanceUseCase(sl()));
  sl.registerLazySingleton<AssessmentLocalDataSource>(
    () => AssessmentLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<AssessmentRepository>(
    () => AssessmentRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetAssessmentsUseCase(sl()));
  sl.registerLazySingleton(() => AddAssessmentUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssessmentUseCase(sl()));
  sl.registerLazySingleton<GradeLocalDataSource>(
    () => GradeLocalDataSourceImpl(dbHelper: sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<GradeRepository>(
    () => GradeRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton(() => GetGradesUseCase(sl()));
  sl.registerLazySingleton(() => SaveGradesUseCase(sl()));
}
