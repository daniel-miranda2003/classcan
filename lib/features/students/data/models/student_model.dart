import '../../domain/entities/student_entity.dart';

class StudentModel extends StudentEntity {
  const StudentModel({
    super.id,
    required super.firstName,
    super.middleName = '',
    required super.paternalLastName,
    super.maternalLastName = '',
    super.attendanceStatus = 'PRESENT',
    super.absences = 0,
    super.averagePercentage,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    final rawAvg = map['averagePercentage'];
    final double? avg = rawAvg is num ? rawAvg.toDouble() : null;
    return StudentModel(
      id: map['id'] as int?,
      firstName: (map['firstName'] as String?) ?? '',
      middleName: (map['middleName'] as String?) ?? '',
      paternalLastName: (map['paternalLastName'] as String?) ?? '',
      maternalLastName: (map['maternalLastName'] as String?) ?? '',
      attendanceStatus: (map['attendanceStatus'] as String?) ?? 'PRESENT',
      absences: (map['absences'] as int?) ?? 0,
      averagePercentage: avg,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'firstName': firstName,
      'middleName': middleName,
      'paternalLastName': paternalLastName,
      'maternalLastName': maternalLastName,
      'attendanceStatus': attendanceStatus,
      'absences': absences,
    };
  }

  StudentModel copyWith({
    int? id,
    String? firstName,
    String? middleName,
    String? paternalLastName,
    String? maternalLastName,
    String? attendanceStatus,
    int? absences,
    double? averagePercentage,
  }) {
    return StudentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      paternalLastName: paternalLastName ?? this.paternalLastName,
      maternalLastName: maternalLastName ?? this.maternalLastName,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      absences: absences ?? this.absences,
      averagePercentage: averagePercentage ?? this.averagePercentage,
    );
  }
}
