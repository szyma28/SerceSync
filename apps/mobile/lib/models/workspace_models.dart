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
}

extension ResidentEntryTypeX on ResidentEntryType {
  String get apiValue {
    switch (this) {
      case ResidentEntryType.careGiven:
        return 'CARE_GIVEN';
      case ResidentEntryType.observation:
        return 'OBSERVATION';
      case ResidentEntryType.personalCare:
        return 'PERSONAL_CARE';
      case ResidentEntryType.nutritionHydration:
        return 'NUTRITION_HYDRATION';
      case ResidentEntryType.mobilityRepositioning:
        return 'MOBILITY_REPOSITIONING';
      case ResidentEntryType.medicationNote:
        return 'MEDICATION_NOTE';
      case ResidentEntryType.escalation:
        return 'ESCALATION';
    }
  }

  String get label {
    switch (this) {
      case ResidentEntryType.careGiven:
        return 'Care Given';
      case ResidentEntryType.observation:
        return 'Observation';
      case ResidentEntryType.personalCare:
        return 'Personal Care';
      case ResidentEntryType.nutritionHydration:
        return 'Nutrition / Hydration';
      case ResidentEntryType.mobilityRepositioning:
        return 'Mobility / Repositioning';
      case ResidentEntryType.medicationNote:
        return 'Medication Note';
      case ResidentEntryType.escalation:
        return 'Escalation';
    }
  }

  static ResidentEntryType fromApiValue(String value) {
    switch (value) {
      case 'CARE_GIVEN':
        return ResidentEntryType.careGiven;
      case 'OBSERVATION':
        return ResidentEntryType.observation;
      case 'PERSONAL_CARE':
        return ResidentEntryType.personalCare;
      case 'NUTRITION_HYDRATION':
        return ResidentEntryType.nutritionHydration;
      case 'MOBILITY_REPOSITIONING':
        return ResidentEntryType.mobilityRepositioning;
      case 'MEDICATION_NOTE':
        return ResidentEntryType.medicationNote;
      case 'ESCALATION':
      default:
        return ResidentEntryType.escalation;
    }
  }
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
    required this.residentId,
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
        residentId: task.residentId,
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
          residentId: task.residentId,
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
          residentId: task.residentId,
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
      residentId: task.residentId,
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
  final String? residentId;
  final ShiftTask? sourceTask;
}

class ResidentListItem {
  const ResidentListItem({
    required this.id,
    required this.fullName,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.todaySummary,
    required this.assignmentContext,
    required this.contextLine,
    required this.alerts,
  });

  factory ResidentListItem.fromJson(Map<String, dynamic> json) {
    return ResidentListItem(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      recognitionImageKey: json['recognitionImageKey'] as String,
      todaySummary: json['todaySummary'] as String,
      assignmentContext: json['assignmentContext'] as String,
      contextLine: json['contextLine'] as String,
      alerts: (json['alerts'] as List<dynamic>? ?? const [])
          .map((alert) => alert as String)
          .toList(),
    );
  }

  final String id;
  final String fullName;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String todaySummary;
  final String assignmentContext;
  final String contextLine;
  final List<String> alerts;

  String get photoAssetPath => residentPhotoAssetPath(recognitionImageKey);
}

class ResidentTimelineEntry {
  const ResidentTimelineEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.details,
    required this.authorName,
    required this.timestamp,
    required this.media,
  });

  factory ResidentTimelineEntry.fromJson(Map<String, dynamic> json) {
    return ResidentTimelineEntry(
      id: json['id'] as String,
      type: ResidentEntryTypeX.fromApiValue(json['type'] as String),
      title: json['title'] as String,
      details: json['details'] as String,
      authorName: json['authorName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      media: (json['media'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ResidentTimelineMediaItem.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String id;
  final ResidentEntryType type;
  final String title;
  final String details;
  final String authorName;
  final DateTime timestamp;
  final List<ResidentTimelineMediaItem> media;
}

class ResidentTimelineMediaItem {
  const ResidentTimelineMediaItem({
    required this.id,
    required this.originalFileName,
    required this.mediaType,
    required this.byteSize,
    required this.downloadPath,
    required this.createdAt,
  });

  factory ResidentTimelineMediaItem.fromJson(Map<String, dynamic> json) {
    return ResidentTimelineMediaItem(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      mediaType: json['mediaType'] as String,
      byteSize: json['byteSize'] as int,
      downloadPath: json['downloadPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final String originalFileName;
  final String mediaType;
  final int byteSize;
  final String downloadPath;
  final DateTime createdAt;
}

class TimelineEvidenceFile {
  const TimelineEvidenceFile({
    required this.fileName,
    required this.bytes,
    required this.mediaType,
  });

  final String fileName;
  final List<int> bytes;
  final String mediaType;
}

class ResidentTaskSummary {
  const ResidentTaskSummary({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.dueAt,
    this.residentId,
    this.residentName,
    this.room,
  });

  factory ResidentTaskSummary.fromJson(Map<String, dynamic> json) {
    return ResidentTaskSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: json['status'] as String,
      dueAt: json['dueAt'] == null
          ? null
          : DateTime.parse(json['dueAt'] as String),
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
    );
  }

  final String id;
  final String title;
  final String? description;
  final String status;
  final DateTime? dueAt;
  final String? residentId;
  final String? residentName;
  final String? room;
}

class ResidentDetail {
  const ResidentDetail({
    required this.id,
    required this.fullName,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.todaySummary,
    required this.assignmentContext,
    required this.contextLine,
    required this.alerts,
    required this.currentTasks,
    required this.timeline,
  });

  factory ResidentDetail.fromJson(Map<String, dynamic> json) {
    return ResidentDetail(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      recognitionImageKey: json['recognitionImageKey'] as String,
      todaySummary: json['todaySummary'] as String,
      assignmentContext: json['assignmentContext'] as String,
      contextLine: json['contextLine'] as String,
      alerts: (json['alerts'] as List<dynamic>? ?? const [])
          .map((alert) => alert as String)
          .toList(),
      currentTasks: (json['currentTasks'] as List<dynamic>? ?? const [])
          .map(
            (task) =>
                ResidentTaskSummary.fromJson(task as Map<String, dynamic>),
          )
          .toList(),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ResidentTimelineEntry.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final String id;
  final String fullName;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String todaySummary;
  final String assignmentContext;
  final String contextLine;
  final List<String> alerts;
  final List<ResidentTaskSummary> currentTasks;
  final List<ResidentTimelineEntry> timeline;

  String get photoAssetPath => residentPhotoAssetPath(recognitionImageKey);
}

class ResidentTimelineEntryDraft {
  const ResidentTimelineEntryDraft({
    required this.type,
    required this.details,
    this.evidence,
  });

  final ResidentEntryType type;
  final String details;
  final TimelineEvidenceFile? evidence;

  Map<String, dynamic> toJson() {
    return {'type': type.apiValue, 'details': details};
  }
}

class ShiftAssignment {
  const ShiftAssignment({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.floorNumber,
    required this.unitLabel,
    this.handoverAcknowledged = false,
    this.handoverAcknowledgedAt,
  });

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    return ShiftAssignment(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      status: json['status'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      handoverAcknowledged: json['handoverAcknowledged'] as bool? ?? false,
      handoverAcknowledgedAt: json['handoverAcknowledgedAt'] == null
          ? null
          : DateTime.parse(json['handoverAcknowledgedAt'] as String),
    );
  }

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final String status;
  final int floorNumber;
  final String unitLabel;
  final bool handoverAcknowledged;
  final DateTime? handoverAcknowledgedAt;
}

class ShiftOverview {
  const ShiftOverview({
    required this.currentShift,
    required this.assignments,
  });

  factory ShiftOverview.fromJson(Map<String, dynamic> json) {
    return ShiftOverview(
      currentShift: json['currentShift'] == null
          ? null
          : ShiftAssignment.fromJson(
              json['currentShift'] as Map<String, dynamic>,
            ),
      assignments: (json['assignments'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ShiftAssignment.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  final ShiftAssignment? currentShift;
  final List<ShiftAssignment> assignments;
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

String residentPhotoAssetPath(String recognitionImageKey) {
  switch (recognitionImageKey) {
    case 'resident-a':
    case 'resident-b':
    case 'resident-c':
    case 'resident-d':
    default:
      return 'assets/images/Resident.png';
  }
}

List<ShiftRotaEntry> buildDemoRota(
  DateTime reference, {
  String unit = 'Willow Floor',
}) {
  final dayStart = DateTime(reference.year, reference.month, reference.day);
  return [
    ShiftRotaEntry(
      id: 'rota-today',
      label: 'Today',
      startsAt: dayStart.add(const Duration(hours: 7)),
      endsAt: dayStart.add(const Duration(hours: 15, minutes: 30)),
      unit: unit,
    ),
    ShiftRotaEntry(
      id: 'rota-tomorrow',
      label: 'Tomorrow',
      startsAt: dayStart.add(const Duration(days: 1, hours: 7)),
      endsAt: dayStart.add(const Duration(days: 1, hours: 15, minutes: 30)),
      unit: unit,
    ),
    ShiftRotaEntry(
      id: 'rota-next',
      label: 'Next Scheduled',
      startsAt: dayStart.add(const Duration(days: 2, hours: 13)),
      endsAt: dayStart.add(const Duration(days: 2, hours: 21)),
      unit: unit,
    ),
  ];
}
