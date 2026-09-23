import 'package:equatable/equatable.dart';

class StudentEntity extends Equatable {
  final int? id;
  final String firstName;
  final String middleName;
  final String paternalLastName;
  final String maternalLastName;
  final String attendanceStatus;
  final int absences;
  final double? averagePercentage;

  const StudentEntity({
    this.id,
    required this.firstName,
    this.middleName = '',
    required this.paternalLastName,
    this.maternalLastName = '',
    this.attendanceStatus = 'PRESENT',
    this.absences = 0,
    this.averagePercentage,
  });

  String get displayName => [
        firstName,
        middleName,
        paternalLastName,
        maternalLastName,
      ].where((p) => p.trim().isNotEmpty).join(' ');

  String get shortName => '$firstName $paternalLastName'.trim();

  bool get isFailing => averagePercentage != null && averagePercentage! < 51.0;
  bool get isPassing => averagePercentage != null && averagePercentage! >= 51.0;

  @override
  List<Object?> get props => [
        id,
        firstName,
        middleName,
        paternalLastName,
        maternalLastName,
        attendanceStatus,
        absences,
        averagePercentage,
      ];
}
