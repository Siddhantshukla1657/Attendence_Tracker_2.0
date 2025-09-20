import 'package:attendence_tracker/models/subject.dart';

enum AttendanceStatus {
  free, // Default state - lecture not conducted
  present, // Student was present
  absent, // Student was absent
}

class AttendanceRecord {
  final String id;
  final String subjectId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final AttendanceStatus status;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = AttendanceStatus.free,
    this.location,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert AttendanceRecord to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status.toString(),
      'location': location,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create AttendanceRecord from JSON
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => AttendanceStatus.free,
      ),
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Check if lecture was conducted (not in free state)
  bool get wasConducted => status != AttendanceStatus.free;

  // Check if student was present
  bool get wasPresent => status == AttendanceStatus.present;

  // Check if student was absent
  bool get wasAbsent => status == AttendanceStatus.absent;

  // Get duration of the session
  Duration get duration => endTime.difference(startTime);

  // Copy with method for updating attendance
  AttendanceRecord copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    AttendanceStatus? status,
    String? location,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AttendanceRecord(id: $id, subjectId: $subjectId, date: $date, status: $status)';
  }
}

// Helper class for attendance statistics
class AttendanceStats {
  final int totalLectures;
  final int conductedLectures;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;

  AttendanceStats({
    required this.totalLectures,
    required this.conductedLectures,
    required this.presentCount,
    required this.absentCount,
  }) : attendancePercentage = conductedLectures > 0
           ? (presentCount / conductedLectures) * 100
           : 0.0;

  factory AttendanceStats.fromRecords(List<AttendanceRecord> records) {
    final conducted = records.where((r) => r.wasConducted).toList();
    final present = records.where((r) => r.wasPresent).length;
    final absent = records.where((r) => r.wasAbsent).length;

    return AttendanceStats(
      totalLectures: records.length,
      conductedLectures: conducted.length,
      presentCount: present,
      absentCount: absent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalLectures': totalLectures,
      'conductedLectures': conductedLectures,
      'presentCount': presentCount,
      'absentCount': absentCount,
      'attendancePercentage': attendancePercentage,
    };
  }
}
