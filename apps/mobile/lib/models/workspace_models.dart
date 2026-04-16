import 'shared_models.dart';
import 'task.dart';

export 'shared_models.dart';

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

const List<ResidentEntryType> residentEntryTypesForNewNotes = [
  ResidentEntryType.personalCare,
  ResidentEntryType.observation,
  ResidentEntryType.nutritionHydration,
  ResidentEntryType.mobilityRepositioning,
  ResidentEntryType.medicationNote,
  ResidentEntryType.escalation,
];

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

enum PersonalCareSubtype { shower, continence, footCare, skinCare }

extension PersonalCareSubtypeX on PersonalCareSubtype {
  String get apiValue {
    switch (this) {
      case PersonalCareSubtype.shower:
        return 'SHOWER';
      case PersonalCareSubtype.continence:
        return 'CONTINENCE';
      case PersonalCareSubtype.footCare:
        return 'FOOT_CARE';
      case PersonalCareSubtype.skinCare:
        return 'SKIN_CARE';
    }
  }

  String get label {
    switch (this) {
      case PersonalCareSubtype.shower:
        return 'Shower';
      case PersonalCareSubtype.continence:
        return 'Continence';
      case PersonalCareSubtype.footCare:
        return 'Foot care';
      case PersonalCareSubtype.skinCare:
        return 'Skin care';
    }
  }

  static PersonalCareSubtype fromApiValue(String value) {
    switch (value) {
      case 'CONTINENCE':
        return PersonalCareSubtype.continence;
      case 'FOOT_CARE':
        return PersonalCareSubtype.footCare;
      case 'SKIN_CARE':
        return PersonalCareSubtype.skinCare;
      case 'SHOWER':
      default:
        return PersonalCareSubtype.shower;
    }
  }
}

enum IncidentSeverity { amber, red }

extension IncidentSeverityX on IncidentSeverity {
  String get apiValue {
    switch (this) {
      case IncidentSeverity.amber:
        return 'AMBER';
      case IncidentSeverity.red:
        return 'RED';
    }
  }

  String get label {
    switch (this) {
      case IncidentSeverity.amber:
        return 'Amber';
      case IncidentSeverity.red:
        return 'Red';
    }
  }

  static IncidentSeverity fromApiValue(String value) {
    switch (value) {
      case 'RED':
        return IncidentSeverity.red;
      case 'AMBER':
      default:
        return IncidentSeverity.amber;
    }
  }
}

enum IncidentStatus { open, acknowledged, resolved }

extension IncidentStatusX on IncidentStatus {
  String get apiValue {
    switch (this) {
      case IncidentStatus.open:
        return 'OPEN';
      case IncidentStatus.acknowledged:
        return 'ACKNOWLEDGED';
      case IncidentStatus.resolved:
        return 'RESOLVED';
    }
  }

  String get label {
    switch (this) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.acknowledged:
        return 'Acknowledged';
      case IncidentStatus.resolved:
        return 'Resolved';
    }
  }

  static IncidentStatus fromApiValue(String value) {
    switch (value) {
      case 'ACKNOWLEDGED':
        return IncidentStatus.acknowledged;
      case 'RESOLVED':
        return IncidentStatus.resolved;
      case 'OPEN':
      default:
        return IncidentStatus.open;
    }
  }
}

enum IncidentCategory { fall, medication, behaviour, injury, other }

extension IncidentCategoryX on IncidentCategory {
  String get apiValue {
    switch (this) {
      case IncidentCategory.fall:
        return 'FALL';
      case IncidentCategory.medication:
        return 'MEDICATION';
      case IncidentCategory.behaviour:
        return 'BEHAVIOUR';
      case IncidentCategory.injury:
        return 'INJURY';
      case IncidentCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case IncidentCategory.fall:
        return 'Fall';
      case IncidentCategory.medication:
        return 'Medication';
      case IncidentCategory.behaviour:
        return 'Behaviour';
      case IncidentCategory.injury:
        return 'Injury';
      case IncidentCategory.other:
        return 'Other';
    }
  }

  static IncidentCategory fromApiValue(String value) {
    switch (value) {
      case 'MEDICATION':
        return IncidentCategory.medication;
      case 'BEHAVIOUR':
        return IncidentCategory.behaviour;
      case 'INJURY':
        return IncidentCategory.injury;
      case 'OTHER':
        return IncidentCategory.other;
      case 'FALL':
      default:
        return IncidentCategory.fall;
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
    final dueAt = task.dueAt;

    if (task.status == TaskStatus.overdue ||
        task.status == TaskStatus.escalated) {
      return PriorityItem(
        id: task.id,
        title: task.title,
        summary: task.description ?? 'Needs immediate attention this shift.',
        band: PriorityBand.urgentNow,
        timeStateLabel: task.status == TaskStatus.escalated
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
  final TaskStatus status;
  final String? residentId;
  final ShiftTask? sourceTask;
}

class ResidentListItem extends ResidentProfile {
  const ResidentListItem({
    required super.id,
    required super.fullName,
    required super.roomLabel,
    required super.floorNumber,
    required super.unitLabel,
    required super.recognitionImageKey,
    required super.todaySummary,
    required super.assignmentContext,
    required super.contextLine,
    required super.alerts,
    required super.baselinePriority,
    required super.effectivePriority,
    required super.prioritySource,
    required super.activeIncidentCount,
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
      baselinePriority: ResidentPriorityLevelX.fromApiValue(
        json['baselinePriority'] as String,
      ),
      effectivePriority: ResidentPriorityLevelX.fromApiValue(
        json['effectivePriority'] as String,
      ),
      prioritySource: ResidentPrioritySourceX.fromApiValue(
        json['prioritySource'] as String,
      ),
      activeIncidentCount: json['activeIncidentCount'] as int? ?? 0,
    );
  }
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
    this.personalCareSubtype,
  });

  factory ResidentTimelineEntry.fromJson(Map<String, dynamic> json) {
    return ResidentTimelineEntry(
      id: json['id'] as String,
      type: ResidentEntryTypeX.fromApiValue(json['type'] as String),
      personalCareSubtype: json['personalCareSubtype'] == null
          ? null
          : PersonalCareSubtypeX.fromApiValue(
              json['personalCareSubtype'] as String,
            ),
      title: json['title'] as String,
      details: json['details'] as String,
      authorName: json['authorName'] as String,
      timestamp: parseApiDateTime(json['timestamp'] as String),
      media: (json['media'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ResidentTimelineMediaItem.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final ResidentEntryType type;
  final PersonalCareSubtype? personalCareSubtype;
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
      createdAt: parseApiDateTime(json['createdAt'] as String),
    );
  }

  final String id;
  final String originalFileName;
  final String mediaType;
  final int byteSize;
  final String downloadPath;
  final DateTime createdAt;
}

class ResidentIncidentMediaItem {
  const ResidentIncidentMediaItem({
    required this.id,
    required this.originalFileName,
    required this.mediaType,
    required this.byteSize,
    required this.createdAt,
  });

  factory ResidentIncidentMediaItem.fromJson(Map<String, dynamic> json) {
    return ResidentIncidentMediaItem(
      id: json['id'] as String,
      originalFileName: json['originalFileName'] as String,
      mediaType: json['mediaType'] as String,
      byteSize: json['byteSize'] as int,
      createdAt: parseApiDateTime(json['createdAt'] as String),
    );
  }

  final String id;
  final String originalFileName;
  final String mediaType;
  final int byteSize;
  final DateTime createdAt;
}

class ResidentIncident {
  const ResidentIncident({
    required this.id,
    required this.severity,
    required this.status,
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.details,
    required this.occurredAt,
    required this.createdAt,
    required this.createdByName,
    required this.evidence,
    this.acknowledgedAt,
    this.acknowledgedByName,
    this.resolvedAt,
    this.resolvedByName,
  });

  factory ResidentIncident.fromJson(Map<String, dynamic> json) {
    return ResidentIncident(
      id: json['id'] as String,
      severity: IncidentSeverityX.fromApiValue(json['severity'] as String),
      status: IncidentStatusX.fromApiValue(json['status'] as String),
      category: IncidentCategoryX.fromApiValue(json['category'] as String),
      categoryLabel:
          json['categoryLabel'] as String? ??
          IncidentCategoryX.fromApiValue(json['category'] as String).label,
      title: json['title'] as String,
      details: json['details'] as String,
      occurredAt: parseApiDateTime(json['occurredAt'] as String),
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : parseApiDateTime(json['acknowledgedAt'] as String),
      acknowledgedByName: json['acknowledgedByName'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : parseApiDateTime(json['resolvedAt'] as String),
      resolvedByName: json['resolvedByName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String),
      createdByName: json['createdByName'] as String,
      evidence: (json['evidence'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ResidentIncidentMediaItem.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final IncidentCategory category;
  final String categoryLabel;
  final String title;
  final String details;
  final DateTime occurredAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedByName;
  final DateTime? resolvedAt;
  final String? resolvedByName;
  final DateTime createdAt;
  final String createdByName;
  final List<ResidentIncidentMediaItem> evidence;
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

class ResidentTaskSummary extends TaskRecord {
  const ResidentTaskSummary({
    required super.id,
    required super.title,
    super.description,
    required super.status,
    super.dueAt,
    super.residentId,
    super.residentName,
    super.room,
  });

  factory ResidentTaskSummary.fromJson(Map<String, dynamic> json) {
    return ResidentTaskSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: TaskStatusX.fromApiValue(json['status'] as String),
      dueAt: json['dueAt'] == null
          ? null
          : parseApiDateTime(json['dueAt'] as String),
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
    );
  }
}

class ResidentDetail extends ResidentProfile {
  const ResidentDetail({
    required super.id,
    required super.fullName,
    required super.roomLabel,
    required super.floorNumber,
    required super.unitLabel,
    required super.recognitionImageKey,
    required super.todaySummary,
    required super.assignmentContext,
    required super.contextLine,
    required super.alerts,
    required super.baselinePriority,
    required super.effectivePriority,
    required super.prioritySource,
    required super.activeIncidentCount,
    required this.activeIncidents,
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
      baselinePriority: ResidentPriorityLevelX.fromApiValue(
        json['baselinePriority'] as String,
      ),
      effectivePriority: ResidentPriorityLevelX.fromApiValue(
        json['effectivePriority'] as String,
      ),
      prioritySource: ResidentPrioritySourceX.fromApiValue(
        json['prioritySource'] as String,
      ),
      activeIncidentCount: json['activeIncidentCount'] as int? ?? 0,
      activeIncidents: (json['activeIncidents'] as List<dynamic>? ?? const [])
          .map(
            (incident) =>
                ResidentIncident.fromJson(incident as Map<String, dynamic>),
          )
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

  final List<ResidentIncident> activeIncidents;
  final List<ResidentTaskSummary> currentTasks;
  final List<ResidentTimelineEntry> timeline;
}

class ResidentTimelineEntryDraft {
  const ResidentTimelineEntryDraft({
    required this.type,
    required this.details,
    this.personalCareSubtype,
    this.evidence,
  });

  final ResidentEntryType type;
  final String details;
  final PersonalCareSubtype? personalCareSubtype;
  final TimelineEvidenceFile? evidence;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'details': details,
      if (personalCareSubtype != null)
        'personalCareSubtype': personalCareSubtype!.apiValue,
    };
  }
}

class ResidentIncidentDraft {
  const ResidentIncidentDraft({
    required this.severity,
    required this.category,
    required this.title,
    required this.details,
    this.evidence,
  });

  final IncidentSeverity severity;
  final IncidentCategory category;
  final String title;
  final String details;
  final TimelineEvidenceFile? evidence;

  Map<String, dynamic> toJson() {
    return {
      'severity': severity.apiValue,
      'category': category.apiValue,
      'title': title,
      'details': details,
    };
  }
}

class ShiftAssignment extends ShiftPeriod {
  const ShiftAssignment({
    required super.id,
    required super.name,
    required super.startsAt,
    required super.endsAt,
    required super.status,
    required super.floorNumber,
    required super.unitLabel,
    this.handoverAcknowledged = false,
    this.handoverAcknowledgedAt,
  });

  factory ShiftAssignment.fromJson(Map<String, dynamic> json) {
    return ShiftAssignment(
      id: json['id'] as String,
      name: json['name'] as String,
      startsAt: parseApiDateTime(json['startsAt'] as String),
      endsAt: parseApiDateTime(json['endsAt'] as String),
      status: ShiftStatusX.fromApiValue(json['status'] as String),
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      handoverAcknowledged: json['handoverAcknowledged'] as bool? ?? false,
      handoverAcknowledgedAt: json['handoverAcknowledgedAt'] == null
          ? null
          : parseApiDateTime(json['handoverAcknowledgedAt'] as String),
    );
  }
  final bool handoverAcknowledged;
  final DateTime? handoverAcknowledgedAt;
}

class ShiftOverview {
  const ShiftOverview({required this.currentShift, required this.assignments});

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
