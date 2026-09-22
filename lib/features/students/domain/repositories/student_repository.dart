import '../entities/student_entity.dart';

abstract class StudentRepository {
  Future<StudentEntity> createStudent(StudentEntity student);
  Future<List<StudentEntity>> getStudents();

  Future<List<StudentEntity>> getStudentsByCourse(int courseId);

  Future<void> enrollStudent({required int studentId, required int courseId});

  Future<Map<int, int>> getStudentCountsByCourse();
  Future<void> deleteStudent(int id);
}
