import '../../domain/entities/grade_entity.dart';

class GradeModel extends GradeEntity {
  const GradeModel({
    super.id,
    required super.assessmentId,
    required super.studentId,
    required super.score,
  });

  factory GradeModel.fromMap(Map<String, dynamic> map) {
    return GradeModel(
      id: map['id'] as int?,
      assessmentId: map['assessmentId'] as int,
      studentId: map['studentId'] as int,
      score: (map['score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'assessmentId': assessmentId,
      'studentId': studentId,
      'score': score,
    };
  }

  GradeModel copyWith({
    int? id,
    int? assessmentId,
    int? studentId,
    double? score,
  }) {
    return GradeModel(
      id: id ?? this.id,
      assessmentId: assessmentId ?? this.assessmentId,
      studentId: studentId ?? this.studentId,
      score: score ?? this.score,
    );
  }
}
