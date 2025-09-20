import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:attendence_tracker/models/timetable.dart';
import 'package:attendence_tracker/models/subject.dart';
import 'package:attendence_tracker/models/attendance.dart';
import 'package:attendence_tracker/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ScheduleCard extends StatelessWidget {
  final TimeSlot timeSlot;
  final Subject? subject;
  final AttendanceRecord? attendanceRecord;
  final Function(AttendanceStatus)? onAttendanceUpdate;

  const ScheduleCard({
    super.key,
    required this.timeSlot,
    this.subject,
    this.attendanceRecord,
    this.onAttendanceUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isFreePeriod = timeSlot.isFree || subject == null;
    final attendanceStatus = attendanceRecord?.status ?? AttendanceStatus.free;
    final statusColor = _getStatusColor(attendanceStatus);

    // Debug logging
    print('ScheduleCard: Building card for ${subject?.name ?? "Free Period"}');
    print('ScheduleCard: isFreePeriod = $isFreePeriod');
    print('ScheduleCard: subject = ${subject?.name} (${subject?.type})');
    print('ScheduleCard: attendanceRecord = ${attendanceRecord?.id}');
    print('ScheduleCard: onAttendanceUpdate = ${onAttendanceUpdate != null}');
    print(
      'ScheduleCard: Will show attendance buttons = ${onAttendanceUpdate != null && !isFreePeriod}',
    );

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.largeBorderRadius),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and Status Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      timeSlot.timeRange,
                      style: AppTheme.bodyTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(attendanceStatus),
                      style: AppTheme.captionTextStyle.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Subject Information
              if (isFreePeriod)
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.coffee(),
                      color: AppTheme.freeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Free Period',
                      style: AppTheme.subheadingTextStyle.copyWith(
                        color: AppTheme.freeColor,
                      ),
                    ),
                  ],
                )
              else ...[
                // Subject Name and Code
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse(subject!.color.replaceFirst('#', '0xff')),
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject!.name,
                            style: AppTheme.subheadingTextStyle.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Teacher: ${subject!.teacherName}',
                            style: AppTheme.captionTextStyle,
                          ),
                          if (subject!.classroom.isNotEmpty)
                            Text(
                              'Room: ${subject!.classroom}',
                              style: AppTheme.captionTextStyle,
                            ),
                        ],
                      ),
                    ),
                    // Subject Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.getSubjectTypeColor(
                          subject!.type.toString(),
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject!.type == SubjectType.lecture
                            ? 'Lecture (1h)'
                            : 'Lab (2h)',
                        style: AppTheme.captionTextStyle.copyWith(
                          color: AppTheme.getSubjectTypeColor(
                            subject!.type.toString(),
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                // Location (if available)
                if (timeSlot.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        PhosphorIcons.mapPin(),
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeSlot.location!,
                        style: AppTheme.captionTextStyle.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ],

                // Attendance Actions
                if (onAttendanceUpdate != null && !isFreePeriod) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceButton(
                          context,
                          'Present',
                          PhosphorIcons.check(),
                          AppTheme.presentColor,
                          AttendanceStatus.present,
                          attendanceStatus == AttendanceStatus.present,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildAttendanceButton(
                          context,
                          'Absent',
                          PhosphorIcons.x(),
                          AppTheme.absentColor,
                          AttendanceStatus.absent,
                          attendanceStatus == AttendanceStatus.absent,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    AttendanceStatus status,
    bool isSelected,
  ) {
    print(
      'ScheduleCard: Building attendance button $label (selected: $isSelected)',
    );

    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: () {
          print('ScheduleCard: Attendance button $label pressed');
          onAttendanceUpdate?.call(status);
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : color.withOpacity(0.1),
          foregroundColor: isSelected ? Colors.white : color,
          elevation: isSelected ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color, width: isSelected ? 0 : 1),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppTheme.presentColor;
      case AttendanceStatus.absent:
        return AppTheme.absentColor;
      case AttendanceStatus.free:
      default:
        return AppTheme.freeColor;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.free:
      default:
        return 'Free';
    }
  }
}
