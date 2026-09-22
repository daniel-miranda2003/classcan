import '../../domain/entities/course_entity.dart';

class CourseModel extends CourseEntity {
  const CourseModel({
    super.id,
    required super.subject,
    required super.grade,
    required super.color,
    required super.userId,
  });

  factory CourseModel.fromMap(Map<String, dynamic> map) {
    return CourseModel(
      id: map['id'] as int?,
      subject: map['subject'] as String,
      grade: map['grade'] as String,
      color: map['color'] as String,
      userId: map['userId'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'subject': subject,
      'grade': grade,
      'color': color,
      'userId': userId,
    };
  }

  CourseModel copyWith({
    int? id,
    String? subject,
    String? grade,
    String? color,
    int? userId,
  }) {
    return CourseModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}
