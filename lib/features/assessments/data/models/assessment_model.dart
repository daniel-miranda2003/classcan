import '../../domain/entities/assessment_entity.dart';

class AssessmentModel extends AssessmentEntity {
  const AssessmentModel({
    super.id,
    required super.courseId,
    required super.title,
    required super.type,
    super.maxScore = 10,
    required super.date,
  });

  static const allowedTypes = ['TASK', 'EXAM'];

  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    return AssessmentModel(
      id: map['id'] as int?,
      courseId: map['courseId'] as int,
      title: map['title'] as String,
      type: map['type'] as String,
      maxScore: (map['maxScore'] as num?)?.toDouble() ?? 10,
      date: map['date'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'courseId': courseId,
      'title': title,
      'type': type,
      'maxScore': maxScore,
      'date': date,
    };
  }

  AssessmentModel copyWith({
    int? id,
    int? courseId,
    String? title,
    String? type,
    double? maxScore,
    String? date,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      type: type ?? this.type,
      maxScore: maxScore ?? this.maxScore,
      date: date ?? this.date,
    );
  }
}
