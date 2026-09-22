import 'package:equatable/equatable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/student_entity.dart';
import '../repositories/student_repository.dart';

class AddStudentParams extends Equatable {
  final String firstName;
  final String middleName;
  final String paternalLastName;
  final String maternalLastName;
  final int? courseId;

  const AddStudentParams({
    required this.firstName,
    this.middleName = '',
    required this.paternalLastName,
    this.maternalLastName = '',
    this.courseId,
  });

  @override
  List<Object?> get props => [
        firstName,
        middleName,
        paternalLastName,
        maternalLastName,
        courseId,
      ];
}

class AddStudentUseCase implements UseCase<StudentEntity, AddStudentParams> {
  final StudentRepository repository;

  const AddStudentUseCase(this.repository);

  @override
  Future<StudentEntity> call(AddStudentParams params) async {
    final firstName = params.firstName.trim();
    final paternalLastName = params.paternalLastName.trim();

    if (firstName.isEmpty) {
      throw const StudentValidationException('El nombre es obligatorio');
    }
    if (paternalLastName.isEmpty) {
      throw const StudentValidationException('El apellido paterno es obligatorio');
    }

    final created = await repository.createStudent(
      StudentEntity(
        firstName: firstName,
        middleName: params.middleName.trim(),
        paternalLastName: paternalLastName,
        maternalLastName: params.maternalLastName.trim(),
        attendanceStatus: '',
        absences: 0,
      ),
    );
    final courseId = params.courseId;
    if (courseId != null && courseId > 0 && created.id != null) {
      await repository.enrollStudent(
        studentId: created.id!,
        courseId: courseId,
      );
    }
    return created;
  }
}
