import '../../domain/entities/student_entity.dart';
import '../../domain/repositories/student_repository.dart';
import '../datasources/student_local_data_source.dart';
import '../models/student_model.dart';

class StudentRepositoryImpl implements StudentRepository {
  final StudentLocalDataSource localDataSource;
  const StudentRepositoryImpl({required this.localDataSource});

  @override
  Future<StudentEntity> createStudent(StudentEntity student) {
    return localDataSource.createStudent(_toModel(student));
  }

  @override
  Future<List<StudentEntity>> getStudents() {
    return localDataSource.getStudents();
  }

  @override
  Future<List<StudentEntity>> getStudentsByCourse(int courseId) {
    return localDataSource.getStudentsByCourse(courseId);
  }

  @override
  Future<void> enrollStudent({
    required int studentId,
    required int courseId,
  }) {
    return localDataSource.enrollStudent(
      studentId: studentId,
      courseId: courseId,
    );
  }

  @override
  Future<Map<int, int>> getStudentCountsByCourse() {
    return localDataSource.getStudentCountsByCourse();
  }

  @override
  Future<void> deleteStudent(int id) {
    return localDataSource.deleteStudent(id);
  }

  StudentModel _toModel(StudentEntity e) => StudentModel(
        id: e.id,
        firstName: e.firstName,
        middleName: e.middleName,
        paternalLastName: e.paternalLastName,
        maternalLastName: e.maternalLastName,
        attendanceStatus: e.attendanceStatus,
        absences: e.absences,
        averagePercentage: e.averagePercentage,
      );
}
