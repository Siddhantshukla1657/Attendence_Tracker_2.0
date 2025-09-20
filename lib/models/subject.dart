enum SubjectType {
  lecture, // 1 hour
  lab, // 2 hours
}

class Subject {
  final String id;
  final String name;
  final String teacherName; // Changed from code to teacherName
  final String classroom; // Added classroom location
  final SubjectType type;
  final String color; // Hex color code for UI
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.teacherName,
    required this.classroom,
    required this.type,
    required this.color,
    required this.createdAt,
  });

  // Convert Subject to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacherName': teacherName,
      'classroom': classroom,
      'type': type.toString(),
      'color': color,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create Subject from JSON
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherName:
          json['teacherName'] as String? ??
          json['code'] as String? ??
          '', // Backward compatibility
      classroom: json['classroom'] as String? ?? '',
      type: SubjectType.values.firstWhere((e) => e.toString() == json['type']),
      color: json['color'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Duration based on subject type
  Duration get duration {
    switch (type) {
      case SubjectType.lecture:
        return const Duration(hours: 1);
      case SubjectType.lab:
        return const Duration(hours: 2);
    }
  }

  // Copy with method for updating subjects
  Subject copyWith({
    String? id,
    String? name,
    String? teacherName,
    String? classroom,
    SubjectType? type,
    String? color,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherName: teacherName ?? this.teacherName,
      classroom: classroom ?? this.classroom,
      type: type ?? this.type,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, teacher: $teacherName, classroom: $classroom, type: $type)';
  }
}
