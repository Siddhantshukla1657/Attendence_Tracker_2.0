import 'package:attendence_tracker/models/subject.dart';

enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

class TimeSlot {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final String? subjectId;
  final String? location;
  final DayOfWeek dayOfWeek;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.subjectId,
    this.location,
    required this.dayOfWeek,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert TimeSlot to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime':
          '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}',
      'subjectId': subjectId,
      'location': location,
      'dayOfWeek': dayOfWeek.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create TimeSlot from JSON
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    final startTimeParts = (json['startTime'] as String).split(':');
    final endTimeParts = (json['endTime'] as String).split(':');
    final now = DateTime.now();

    return TimeSlot(
      id: json['id'] as String,
      startTime: DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(startTimeParts[0]),
        int.parse(startTimeParts[1]),
      ),
      endTime: DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(endTimeParts[0]),
        int.parse(endTimeParts[1]),
      ),
      subjectId: json['subjectId'] as String?,
      location: json['location'] as String?,
      dayOfWeek: DayOfWeek.values.firstWhere(
        (e) => e.toString() == json['dayOfWeek'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Check if this slot is free (no subject assigned)
  bool get isFree => subjectId == null;

  // Get duration of the time slot
  Duration get duration => endTime.difference(startTime);

  // Get formatted time range string
  String get timeRange {
    final startStr =
        '${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
  }

  // Copy with method for updating time slots
  TimeSlot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? subjectId,
    String? location,
    DayOfWeek? dayOfWeek,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectId: subjectId ?? this.subjectId,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TimeSlot(id: $id, timeRange: $timeRange, subjectId: $subjectId, dayOfWeek: $dayOfWeek)';
  }
}

class Timetable {
  final String id;
  final String name;
  final Map<DayOfWeek, List<TimeSlot>> schedule;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  Timetable({
    required this.id,
    required this.name,
    required this.schedule,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Convert Timetable to JSON
  Map<String, dynamic> toJson() {
    final scheduleJson = <String, dynamic>{};
    schedule.forEach((day, slots) {
      scheduleJson[day.toString()] = slots
          .map((slot) => slot.toJson())
          .toList();
    });

    return {
      'id': id,
      'name': name,
      'schedule': scheduleJson,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create Timetable from JSON
  factory Timetable.fromJson(Map<String, dynamic> json) {
    final scheduleJson = json['schedule'] as Map<String, dynamic>;
    final schedule = <DayOfWeek, List<TimeSlot>>{};

    scheduleJson.forEach((dayStr, slotsJson) {
      final day = DayOfWeek.values.firstWhere((e) => e.toString() == dayStr);
      final slots = (slotsJson as List)
          .map(
            (slotJson) => TimeSlot.fromJson(slotJson as Map<String, dynamic>),
          )
          .toList();
      // Sort slots by start time when loading from storage
      slots.sort((a, b) => a.startTime.compareTo(b.startTime));
      schedule[day] = slots;
    });

    return Timetable(
      id: json['id'] as String,
      name: json['name'] as String,
      schedule: schedule,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Get schedule for a specific day
  List<TimeSlot> getScheduleForDay(DayOfWeek day) {
    final daySlots = List<TimeSlot>.from(schedule[day] ?? []);
    // Always sort by start time to ensure consistent ordering
    daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    return daySlots;
  }

  // Get all time slots for all days
  List<TimeSlot> get allTimeSlots {
    final allSlots = <TimeSlot>[];
    schedule.values.forEach((slots) => allSlots.addAll(slots));
    return allSlots;
  }

  // Get time slots for a specific subject
  List<TimeSlot> getSlotsForSubject(String subjectId) {
    return allTimeSlots.where((slot) => slot.subjectId == subjectId).toList();
  }

  // Copy with method for updating timetable
  Timetable copyWith({
    String? id,
    String? name,
    Map<DayOfWeek, List<TimeSlot>>? schedule,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Timetable(
      id: id ?? this.id,
      name: name ?? this.name,
      schedule: schedule ?? this.schedule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Timetable && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Timetable(id: $id, name: $name, isActive: $isActive)';
  }
}

// Helper extensions
extension DayOfWeekExtension on DayOfWeek {
  String get displayName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Monday';
      case DayOfWeek.tuesday:
        return 'Tuesday';
      case DayOfWeek.wednesday:
        return 'Wednesday';
      case DayOfWeek.thursday:
        return 'Thursday';
      case DayOfWeek.friday:
        return 'Friday';
      case DayOfWeek.saturday:
        return 'Saturday';
      case DayOfWeek.sunday:
        return 'Sunday';
    }
  }

  String get shortName {
    switch (this) {
      case DayOfWeek.monday:
        return 'Mon';
      case DayOfWeek.tuesday:
        return 'Tue';
      case DayOfWeek.wednesday:
        return 'Wed';
      case DayOfWeek.thursday:
        return 'Thu';
      case DayOfWeek.friday:
        return 'Fri';
      case DayOfWeek.saturday:
        return 'Sat';
      case DayOfWeek.sunday:
        return 'Sun';
    }
  }

  static DayOfWeek fromDateTime(DateTime dateTime) {
    switch (dateTime.weekday) {
      case 1:
        return DayOfWeek.monday;
      case 2:
        return DayOfWeek.tuesday;
      case 3:
        return DayOfWeek.wednesday;
      case 4:
        return DayOfWeek.thursday;
      case 5:
        return DayOfWeek.friday;
      case 6:
        return DayOfWeek.saturday;
      case 7:
        return DayOfWeek.sunday;
      default:
        return DayOfWeek.monday;
    }
  }
}
