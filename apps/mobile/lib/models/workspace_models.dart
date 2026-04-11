import 'task.dart';

enum PriorityBand { urgentNow, dueWithinHour, reminders }

enum ResidentEntryType {
  careGiven,
  observation,
  personalCare,
  nutritionHydration,
  mobilityRepositioning,
  medicationNote,
  escalation,
  photoEvidence,
}

class PriorityItem {
  const PriorityItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.band,
    required this.timeStateLabel,
    required this.residentName,
    required this.room,
    required this.status,
    this.sourceTask,
  });

  factory PriorityItem.fromTask(ShiftTask task, DateTime now) {
    final normalizedStatus = task.status.toLowerCase();
    final dueAt = task.dueAt;

    if (normalizedStatus == 'overdue' || normalizedStatus == 'escalated') {
      return PriorityItem(
        id: task.id,
        title: task.title,
        summary: task.description ?? 'Needs immediate attention this shift.',
        band: PriorityBand.urgentNow,
        timeStateLabel: normalizedStatus == 'escalated'
            ? 'Escalated for review'
            : _formatOverdueLabel(dueAt, now),
        residentName: task.residentName ?? 'Assigned resident',
        room: task.room ?? 'Room pending',
        status: task.status,
        sourceTask: task,
      );
    }

    if (dueAt != null) {
      final difference = dueAt.difference(now);
      if (!difference.isNegative && difference.inMinutes <= 60) {
        return PriorityItem(
          id: task.id,
          title: task.title,
          summary: task.description ?? 'Coming up within the next hour.',
          band: PriorityBand.dueWithinHour,
          timeStateLabel: _formatDueSoonLabel(difference),
          residentName: task.residentName ?? 'Assigned resident',
          room: task.room ?? 'Room pending',
          status: task.status,
          sourceTask: task,
        );
      }

      if (difference.isNegative) {
        return PriorityItem(
          id: task.id,
          title: task.title,
          summary: task.description ?? 'Needs a quick check-in now.',
          band: PriorityBand.urgentNow,
          timeStateLabel: _formatOverdueLabel(dueAt, now),
          residentName: task.residentName ?? 'Assigned resident',
          room: task.room ?? 'Room pending',
          status: task.status,
          sourceTask: task,
        );
      }
    }

    return PriorityItem(
      id: task.id,
      title: task.title,
      summary: task.description ?? 'Reminder for later in the shift.',
      band: PriorityBand.reminders,
      timeStateLabel: dueAt == null
          ? 'Reminder for today'
          : _formatReminderLabel(dueAt.difference(now)),
      residentName: task.residentName ?? 'Assigned resident',
      room: task.room ?? 'Room pending',
      status: task.status,
      sourceTask: task,
    );
  }

  static String _formatDueSoonLabel(Duration difference) {
    if (difference.inMinutes <= 1) return 'Due in under a minute';
    return 'Due in ${difference.inMinutes} min';
  }

  static String _formatReminderLabel(Duration difference) {
    if (difference.inHours >= 1) {
      return 'Due in ${difference.inHours} hr';
    }
    if (difference.inMinutes > 0) {
      return 'Due in ${difference.inMinutes} min';
    }
    return 'Reminder for today';
  }

  static String _formatOverdueLabel(DateTime? dueAt, DateTime now) {
    if (dueAt == null) return 'Needs review now';
    final overdueBy = now.difference(dueAt);
    if (overdueBy.inMinutes < 1) return 'Needs review now';
    return 'Overdue by ${overdueBy.inMinutes} min';
  }

  final String id;
  final String title;
  final String summary;
  final PriorityBand band;
  final String timeStateLabel;
  final String residentName;
  final String room;
  final String status;
  final ShiftTask? sourceTask;
}

class ResidentProfile {
  const ResidentProfile({
    required this.id,
    required this.name,
    required this.room,
    required this.photoAssetPath,
    required this.assignmentContext,
    required this.todaySummary,
    required this.contextLine,
    required this.alerts,
    required this.timeline,
  });

  ResidentProfile copyWith({
    String? id,
    String? name,
    String? room,
    String? photoAssetPath,
    String? assignmentContext,
    String? todaySummary,
    String? contextLine,
    List<String>? alerts,
    List<ResidentTimelineEntry>? timeline,
  }) {
    return ResidentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      room: room ?? this.room,
      photoAssetPath: photoAssetPath ?? this.photoAssetPath,
      assignmentContext: assignmentContext ?? this.assignmentContext,
      todaySummary: todaySummary ?? this.todaySummary,
      contextLine: contextLine ?? this.contextLine,
      alerts: alerts ?? this.alerts,
      timeline: timeline ?? this.timeline,
    );
  }

  final String id;
  final String name;
  final String room;
  final String photoAssetPath;
  final String assignmentContext;
  final String todaySummary;
  final String contextLine;
  final List<String> alerts;
  final List<ResidentTimelineEntry> timeline;
}

class ResidentTimelineEntry {
  const ResidentTimelineEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.authorName,
    required this.timestamp,
  });

  final String id;
  final ResidentEntryType type;
  final String title;
  final String details;
  final String authorName;
  final DateTime timestamp;
}

class ShiftRotaEntry {
  const ShiftRotaEntry({
    required this.id,
    required this.label,
    required this.startsAt,
    required this.endsAt,
    required this.unit,
  });

  final String id;
  final String label;
  final DateTime startsAt;
  final DateTime endsAt;
  final String unit;
}

List<ResidentProfile> buildDemoResidents() {
  final now = DateTime.now();
  return [
    ResidentProfile(
      id: 'resident-evans',
      name: 'Mrs Evans',
      room: 'Room 12A',
      photoAssetPath: 'assets/images/Resident.png',
      assignmentContext: 'Assigned to Willow Floor this morning',
      todaySummary:
          'Medication due within the hour and a hygiene reminder noted.',
      contextLine: 'Medication due in 54 min · 3 days since shower logged',
      alerts: const ['Medication due', 'Personal care reminder'],
      timeline: [
        ResidentTimelineEntry(
          id: 'evans-1',
          type: ResidentEntryType.personalCare,
          title: 'Morning wash completed',
          details:
              'Supported with fresh clothing and oral care before breakfast.',
          authorName: 'Alex Carer',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 20)),
        ),
        ResidentTimelineEntry(
          id: 'evans-2',
          type: ResidentEntryType.nutritionHydration,
          title: 'Hydration check',
          details:
              'Encouraged fluids and logged half a jug taken with breakfast.',
          authorName: 'Alex Carer',
          timestamp: now.subtract(const Duration(minutes: 48)),
        ),
      ],
    ),
    ResidentProfile(
      id: 'resident-patel',
      name: 'Mr Patel',
      room: 'Room 7B',
      photoAssetPath: 'assets/images/Resident.png',
      assignmentContext: 'Assigned to Willow Floor this morning',
      todaySummary:
          'Observation follow-up and mobility reassurance remain in focus.',
      contextLine:
          'Observation follow-up later today · Mobility review shared in handover',
      alerts: const ['Observation follow-up', 'Mobility watch'],
      timeline: [
        ResidentTimelineEntry(
          id: 'patel-1',
          type: ResidentEntryType.observation,
          title: 'Mood observed as settled',
          details:
              'More relaxed after breakfast, still prefers one-to-one reassurance.',
          authorName: 'Jordan Senior Carer',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 10)),
        ),
        ResidentTimelineEntry(
          id: 'patel-2',
          type: ResidentEntryType.mobilityRepositioning,
          title: 'Mobility support given',
          details:
              'Assisted to chair with walking frame and supervised transfer.',
          authorName: 'Alex Carer',
          timestamp: now.subtract(const Duration(minutes: 34)),
        ),
      ],
    ),
    ResidentProfile(
      id: 'resident-johnson',
      name: 'Ms Johnson',
      room: 'Room 4C',
      photoAssetPath: 'assets/images/Resident.png',
      assignmentContext: 'Shared across Willow Floor for this shift',
      todaySummary:
          'Repositioning timer and skin-integrity photo review are due this afternoon.',
      contextLine:
          'Reposition due in 18 min · Photo evidence governance placeholder',
      alerts: const ['Reposition due', 'Skin integrity review'],
      timeline: [
        ResidentTimelineEntry(
          id: 'johnson-1',
          type: ResidentEntryType.mobilityRepositioning,
          title: 'Last reposition recorded',
          details:
              'Turn completed with pillow support and pressure area check.',
          authorName: 'Night Team',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 42)),
        ),
        ResidentTimelineEntry(
          id: 'johnson-2',
          type: ResidentEntryType.photoEvidence,
          title: 'Photo evidence placeholder recorded',
          details:
              'Future wound-progress photos will require consent, audit, and secure storage controls.',
          authorName: 'System note',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 5)),
        ),
      ],
    ),
  ];
}

List<ShiftRotaEntry> buildDemoRota(DateTime reference) {
  final dayStart = DateTime(reference.year, reference.month, reference.day);
  return [
    ShiftRotaEntry(
      id: 'rota-today',
      label: 'Today',
      startsAt: dayStart.add(const Duration(hours: 7)),
      endsAt: dayStart.add(const Duration(hours: 15, minutes: 30)),
      unit: 'Willow Floor',
    ),
    ShiftRotaEntry(
      id: 'rota-tomorrow',
      label: 'Tomorrow',
      startsAt: dayStart.add(const Duration(days: 1, hours: 13)),
      endsAt: dayStart.add(const Duration(days: 1, hours: 21)),
      unit: 'Willow Floor',
    ),
    ShiftRotaEntry(
      id: 'rota-next',
      label: 'Monday',
      startsAt: dayStart.add(const Duration(days: 2, hours: 7)),
      endsAt: dayStart.add(const Duration(days: 2, hours: 15, minutes: 30)),
      unit: 'Oak Unit',
    ),
  ];
}
