class LocalDatabaseException implements Exception {
  final String message;
  const LocalDatabaseException(this.message);

  @override
  String toString() => 'LocalDatabaseException: $message';
}

class NotFoundException implements Exception {
  final String message;
  const NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

class DuplicateUserException implements Exception {
  final String message;
  const DuplicateUserException(this.message);

  @override
  String toString() => 'DuplicateUserException: $message';
}

class InvalidCredentialsException implements Exception {
  final String message;
  const InvalidCredentialsException([
    this.message = 'Usuario o contraseña incorrectos',
  ]);

  @override
  String toString() => 'InvalidCredentialsException: $message';
}

class AuthValidationException implements Exception {
  final String message;
  const AuthValidationException(this.message);

  @override
  String toString() => 'AuthValidationException: $message';
}

class CourseValidationException implements Exception {
  final String message;
  const CourseValidationException(this.message);

  @override
  String toString() => 'CourseValidationException: $message';
}

class StudentValidationException implements Exception {
  final String message;
  const StudentValidationException(this.message);

  @override
  String toString() => 'StudentValidationException: $message';
}

class AttendanceValidationException implements Exception {
  final String message;
  const AttendanceValidationException(this.message);

  @override
  String toString() => 'AttendanceValidationException: $message';
}

class AssessmentValidationException implements Exception {
  final String message;
  const AssessmentValidationException(this.message);

  @override
  String toString() => 'AssessmentValidationException: $message';
}

class GradeValidationException implements Exception {
  final String message;
  const GradeValidationException(this.message);

  @override
  String toString() => 'GradeValidationException: $message';
}
