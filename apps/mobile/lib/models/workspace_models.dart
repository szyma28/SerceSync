import 'shared_models.dart';
import 'task.dart';

export 'shared_models.dart';

enum PriorityBand { urgentNow, dueWithinHour, reminders }

enum OfflineSyncStatus { synced, pending, failed, conflict }

extension OfflineSyncStatusX on OfflineSyncStatus {
  String get storageValue {
    switch (this) {
      case OfflineSyncStatus.synced:
        return 'synced';
      case OfflineSyncStatus.pending:
        return 'pending';
      case OfflineSyncStatus.failed:
        return 'failed';
      case OfflineSyncStatus.conflict:
        return 'conflict';
    }
  }

  String get label {
    switch (this) {
      case OfflineSyncStatus.synced:
        return 'Synced';
      case OfflineSyncStatus.pending:
        return 'Pending sync';
      case OfflineSyncStatus.failed:
        return 'Failed';
      case OfflineSyncStatus.conflict:
        return 'Needs review';
    }
  }

  static OfflineSyncStatus fromStorageValue(String value) {
    switch (value) {
      case 'pending':
        return OfflineSyncStatus.pending;
      case 'failed':
        return OfflineSyncStatus.failed;
      case 'conflict':
        return OfflineSyncStatus.conflict;
      case 'synced':
      default:
        return OfflineSyncStatus.synced;
    }
  }
}

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

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get apiValue {
    switch (this) {
      case MealType.breakfast:
        return 'BREAKFAST';
      case MealType.lunch:
        return 'LUNCH';
      case MealType.dinner:
        return 'DINNER';
      case MealType.snack:
        return 'SNACK';
    }
  }

  String get label {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  static MealType fromApiValue(String value) {
    switch (value) {
      case 'LUNCH':
        return MealType.lunch;
      case 'DINNER':
        return MealType.dinner;
      case 'SNACK':
        return MealType.snack;
      case 'BREAKFAST':
      default:
        return MealType.breakfast;
    }
  }
}

enum MealIntakeAmount { none, quarter, half, most, all }

extension MealIntakeAmountX on MealIntakeAmount {
  String get apiValue {
    switch (this) {
      case MealIntakeAmount.none:
        return 'NONE';
      case MealIntakeAmount.quarter:
        return 'QUARTER';
      case MealIntakeAmount.half:
        return 'HALF';
      case MealIntakeAmount.most:
        return 'MOST';
      case MealIntakeAmount.all:
        return 'ALL';
    }
  }

  String get label {
    switch (this) {
      case MealIntakeAmount.none:
        return 'None eaten';
      case MealIntakeAmount.quarter:
        return 'Quarter eaten';
      case MealIntakeAmount.half:
        return 'Half eaten';
      case MealIntakeAmount.most:
        return 'Most eaten';
      case MealIntakeAmount.all:
        return 'All eaten';
    }
  }

  static MealIntakeAmount fromApiValue(String value) {
    switch (value) {
      case 'QUARTER':
        return MealIntakeAmount.quarter;
      case 'HALF':
        return MealIntakeAmount.half;
      case 'MOST':
        return MealIntakeAmount.most;
      case 'ALL':
        return MealIntakeAmount.all;
      case 'NONE':
      default:
        return MealIntakeAmount.none;
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
    this.opensMedicationRound = false,
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

  factory PriorityItem.fromMedicationResidentSummary(
    MedicationResidentOperationalSummary residentSummary,
    DateTime now,
  ) {
    final resident = residentSummary.resident;
    final openDoses = residentSummary.openDoses;
    final exceptions = residentSummary.exceptions;
    final overdueCount = openDoses.overdue;
    final dueSoonCount = openDoses.dueWithinHour;
    final exceptionCount = exceptions.total;

    final hasOverdue = overdueCount > 0;
    final hasExceptions = exceptionCount > 0;
    final isDueSoon = dueSoonCount > 0;
    final nextDueAt = openDoses.nextDueAt;

    final band = hasOverdue || hasExceptions
        ? PriorityBand.urgentNow
        : isDueSoon
        ? PriorityBand.dueWithinHour
        : PriorityBand.reminders;

    final syntheticTask = ShiftTask(
      id: 'med-priority-${resident.id}-${band.name}',
      title: hasOverdue
          ? 'Medication round overdue'
          : hasExceptions
          ? 'Medication variance recorded'
          : isDueSoon
          ? 'Medication due soon'
          : 'Medication later this shift',
      description: _buildMedicationResidentSummary(residentSummary, band),
      dueAt: nextDueAt,
      status: hasOverdue || hasExceptions
          ? TaskStatus.overdue
          : TaskStatus.pending,
      focus: TaskFocus.medication,
      clinicalPriority: hasOverdue
          ? TaskClinicalPriority.timeCritical
          : hasExceptions ||
                residentSummary.taskSummaryCompatible.highPriority > 0
          ? TaskClinicalPriority.priority
          : TaskClinicalPriority.routine,
      residentId: resident.id,
      residentName: resident.fullName,
      room: resident.roomLabel,
      canComplete: false,
      canDefer: false,
      canEscalate: false,
      actionRestrictionReason:
          'Open the shift medication round to record outcomes.',
    );

    final nextDueDifference = nextDueAt?.difference(now);
    final timeStateLabel = hasOverdue
        ? '$overdueCount overdue now'
        : hasExceptions
        ? '$exceptionCount exception${exceptionCount == 1 ? '' : 's'} open'
        : nextDueDifference != null &&
              band == PriorityBand.dueWithinHour &&
              !nextDueDifference.isNegative
        ? _formatDueSoonLabel(nextDueDifference)
        : nextDueDifference != null &&
              band == PriorityBand.reminders &&
              !nextDueDifference.isNegative
        ? _formatReminderLabel(nextDueDifference)
        : band == PriorityBand.dueWithinHour
        ? '$dueSoonCount due within 1 hr'
        : 'Later this shift';

    return PriorityItem(
      id: syntheticTask.id,
      title: syntheticTask.title,
      summary: syntheticTask.description ?? 'Medication attention is needed.',
      band: band,
      timeStateLabel: timeStateLabel,
      residentName: resident.fullName,
      room: resident.roomLabel,
      status: syntheticTask.status,
      residentId: resident.id,
      opensMedicationRound: true,
      sourceTask: syntheticTask,
    );
  }

  static String _buildMedicationResidentSummary(
    MedicationResidentOperationalSummary residentSummary,
    PriorityBand band,
  ) {
    final resident = residentSummary.resident;
    final openDoses = residentSummary.openDoses;
    final exceptions = residentSummary.exceptions;
    final summaryParts = <String>[];

    if (band == PriorityBand.urgentNow && openDoses.overdue > 0) {
      summaryParts.add(
        '${resident.fullName} has ${openDoses.overdue} overdue medication${openDoses.overdue == 1 ? '' : 's'} to review.',
      );
    } else if (band == PriorityBand.urgentNow && exceptions.total > 0) {
      summaryParts.add(
        'Review ${resident.fullName}: ${_formatMedicationExceptionSummary(exceptions)}.',
      );
    } else if (band == PriorityBand.dueWithinHour) {
      summaryParts.add(
        '${resident.fullName} has ${openDoses.dueWithinHour} medication${openDoses.dueWithinHour == 1 ? '' : 's'} due within the next hour.',
      );
    } else {
      summaryParts.add(
        '${resident.fullName} still has ${openDoses.due} medication${openDoses.due == 1 ? '' : 's'} due later this shift.',
      );
    }

    if (exceptions.total > 0 && band != PriorityBand.urgentNow) {
      summaryParts.add(_formatMedicationExceptionSummary(exceptions));
    }

    return summaryParts.join(' ');
  }

  static String _formatMedicationExceptionSummary(
    MedicationOperationalExceptionSummary exceptions,
  ) {
    final parts = <String>[];

    if (exceptions.refused > 0) {
      parts.add('${exceptions.refused} refused');
    }
    if (exceptions.omitted > 0) {
      parts.add('${exceptions.omitted} omitted');
    }
    if (exceptions.delayed > 0) {
      parts.add('${exceptions.delayed} delayed');
    }
    if (exceptions.notAvailable > 0) {
      parts.add('${exceptions.notAvailable} not available');
    }
    if (exceptions.held > 0) {
      parts.add('${exceptions.held} held');
    }

    if (parts.isEmpty) {
      return 'Medication variance needs review';
    }

    return parts.join(' · ');
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
  final bool opensMedicationRound;
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
    required super.aboutMe,
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
      aboutMe: (json['aboutMe'] as String?) ?? '',
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
    this.mealType,
    this.mealIntakeAmount,
    this.syncStatus = OfflineSyncStatus.synced,
    this.syncMessage,
    this.localMutationId,
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
      mealType: json['mealType'] == null
          ? null
          : MealTypeX.fromApiValue(json['mealType'] as String),
      mealIntakeAmount: json['mealIntakeAmount'] == null
          ? null
          : MealIntakeAmountX.fromApiValue(json['mealIntakeAmount'] as String),
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
      syncStatus: json['syncStatus'] == null
          ? OfflineSyncStatus.synced
          : OfflineSyncStatusX.fromStorageValue(json['syncStatus'] as String),
      syncMessage: json['syncMessage'] as String?,
      localMutationId: json['localMutationId'] as String?,
    );
  }

  final String id;
  final ResidentEntryType type;
  final PersonalCareSubtype? personalCareSubtype;
  final MealType? mealType;
  final MealIntakeAmount? mealIntakeAmount;
  final String title;
  final String details;
  final String authorName;
  final DateTime timestamp;
  final List<ResidentTimelineMediaItem> media;
  final OfflineSyncStatus syncStatus;
  final String? syncMessage;
  final String? localMutationId;

  ResidentTimelineEntry copyWith({
    String? id,
    ResidentEntryType? type,
    PersonalCareSubtype? personalCareSubtype,
    MealType? mealType,
    MealIntakeAmount? mealIntakeAmount,
    String? title,
    String? details,
    String? authorName,
    DateTime? timestamp,
    List<ResidentTimelineMediaItem>? media,
    OfflineSyncStatus? syncStatus,
    String? syncMessage,
    String? localMutationId,
  }) {
    return ResidentTimelineEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      personalCareSubtype: personalCareSubtype ?? this.personalCareSubtype,
      mealType: mealType ?? this.mealType,
      mealIntakeAmount: mealIntakeAmount ?? this.mealIntakeAmount,
      title: title ?? this.title,
      details: details ?? this.details,
      authorName: authorName ?? this.authorName,
      timestamp: timestamp ?? this.timestamp,
      media: media ?? this.media,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: syncMessage ?? this.syncMessage,
      localMutationId: localMutationId ?? this.localMutationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.apiValue,
      if (personalCareSubtype != null)
        'personalCareSubtype': personalCareSubtype!.apiValue,
      if (mealType != null) 'mealType': mealType!.apiValue,
      if (mealIntakeAmount != null)
        'mealIntakeAmount': mealIntakeAmount!.apiValue,
      'title': title,
      'details': details,
      'authorName': authorName,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'media': media.map((item) => item.toJson()).toList(),
      if (syncStatus != OfflineSyncStatus.synced)
        'syncStatus': syncStatus.storageValue,
      if (syncMessage != null) 'syncMessage': syncMessage,
      if (localMutationId != null) 'localMutationId': localMutationId,
    };
  }
}

class MedicationTaskSummary {
  const MedicationTaskSummary({
    this.total = 0,
    this.overdue = 0,
    this.dueWithinHour = 0,
    this.highPriority = 0,
    this.headline,
    this.warnings = const [],
  });

  factory MedicationTaskSummary.fromJson(Map<String, dynamic> json) {
    return MedicationTaskSummary(
      total: json['total'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueWithinHour: json['dueWithinHour'] as int? ?? 0,
      highPriority: json['highPriority'] as int? ?? 0,
      headline: json['headline'] as String?,
      warnings: (json['warnings'] as List<dynamic>? ?? const [])
          .map((entry) => entry as String)
          .toList(),
    );
  }

  final int total;
  final int overdue;
  final int dueWithinHour;
  final int highPriority;
  final String? headline;
  final List<String> warnings;

  bool get hasActiveMedicationTasks => total > 0;
}

class MedicationOperationalResidentIdentity {
  const MedicationOperationalResidentIdentity({
    required this.id,
    required this.fullName,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
  });

  factory MedicationOperationalResidentIdentity.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicationOperationalResidentIdentity(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
    );
  }

  final String id;
  final String fullName;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
}

class MedicationOperationalOpenDoseSummary {
  const MedicationOperationalOpenDoseSummary({
    this.due = 0,
    this.overdue = 0,
    this.dueWithinHour = 0,
    this.nextDueAt,
  });

  factory MedicationOperationalOpenDoseSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicationOperationalOpenDoseSummary(
      due: json['due'] as int? ?? 0,
      overdue: json['overdue'] as int? ?? 0,
      dueWithinHour: json['dueWithinHour'] as int? ?? 0,
      nextDueAt: json['nextDueAt'] == null
          ? null
          : parseApiDateTime(json['nextDueAt'] as String),
    );
  }

  final int due;
  final int overdue;
  final int dueWithinHour;
  final DateTime? nextDueAt;
}

class MedicationOperationalExceptionSummary {
  const MedicationOperationalExceptionSummary({
    this.refused = 0,
    this.omitted = 0,
    this.delayed = 0,
    this.notAvailable = 0,
    this.held = 0,
    this.total = 0,
  });

  factory MedicationOperationalExceptionSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicationOperationalExceptionSummary(
      refused: json['refused'] as int? ?? 0,
      omitted: json['omitted'] as int? ?? 0,
      delayed: json['delayed'] as int? ?? 0,
      notAvailable: json['notAvailable'] as int? ?? 0,
      held: json['held'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
    );
  }

  final int refused;
  final int omitted;
  final int delayed;
  final int notAvailable;
  final int held;
  final int total;
}

class MedicationResidentOperationalSummary {
  const MedicationResidentOperationalSummary({
    required this.resident,
    this.taskSummaryCompatible = const MedicationTaskSummary(),
    this.openDoses = const MedicationOperationalOpenDoseSummary(),
    this.exceptions = const MedicationOperationalExceptionSummary(),
  });

  factory MedicationResidentOperationalSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicationResidentOperationalSummary(
      resident: MedicationOperationalResidentIdentity.fromJson(
        json['resident'] as Map<String, dynamic>,
      ),
      taskSummaryCompatible: json['taskSummaryCompatible'] == null
          ? const MedicationTaskSummary()
          : MedicationTaskSummary.fromJson(
              json['taskSummaryCompatible'] as Map<String, dynamic>,
            ),
      openDoses: json['openDoses'] == null
          ? const MedicationOperationalOpenDoseSummary()
          : MedicationOperationalOpenDoseSummary.fromJson(
              json['openDoses'] as Map<String, dynamic>,
            ),
      exceptions: json['exceptions'] == null
          ? const MedicationOperationalExceptionSummary()
          : MedicationOperationalExceptionSummary.fromJson(
              json['exceptions'] as Map<String, dynamic>,
            ),
    );
  }

  final MedicationOperationalResidentIdentity resident;
  final MedicationTaskSummary taskSummaryCompatible;
  final MedicationOperationalOpenDoseSummary openDoses;
  final MedicationOperationalExceptionSummary exceptions;

  bool get hasSignal =>
      openDoses.due > 0 ||
      openDoses.overdue > 0 ||
      openDoses.dueWithinHour > 0 ||
      exceptions.total > 0;
}

class MedicationShiftOperationalSummary {
  const MedicationShiftOperationalSummary({this.residents = const []});

  factory MedicationShiftOperationalSummary.fromJson(
    Map<String, dynamic> json,
  ) {
    return MedicationShiftOperationalSummary(
      residents: (json['residents'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MedicationResidentOperationalSummary.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }

  final List<MedicationResidentOperationalSummary> residents;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalFileName': originalFileName,
      'mediaType': mediaType,
      'byteSize': byteSize,
      'downloadPath': downloadPath,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalFileName': originalFileName,
      'mediaType': mediaType,
      'byteSize': byteSize,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }
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
    this.syncStatus = OfflineSyncStatus.synced,
    this.syncMessage,
    this.localMutationId,
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
      syncStatus: json['syncStatus'] == null
          ? OfflineSyncStatus.synced
          : OfflineSyncStatusX.fromStorageValue(json['syncStatus'] as String),
      syncMessage: json['syncMessage'] as String?,
      localMutationId: json['localMutationId'] as String?,
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
  final OfflineSyncStatus syncStatus;
  final String? syncMessage;
  final String? localMutationId;

  ResidentIncident copyWith({
    String? id,
    IncidentSeverity? severity,
    IncidentStatus? status,
    IncidentCategory? category,
    String? categoryLabel,
    String? title,
    String? details,
    DateTime? occurredAt,
    DateTime? acknowledgedAt,
    String? acknowledgedByName,
    DateTime? resolvedAt,
    String? resolvedByName,
    DateTime? createdAt,
    String? createdByName,
    List<ResidentIncidentMediaItem>? evidence,
    OfflineSyncStatus? syncStatus,
    String? syncMessage,
    String? localMutationId,
  }) {
    return ResidentIncident(
      id: id ?? this.id,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      category: category ?? this.category,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      title: title ?? this.title,
      details: details ?? this.details,
      occurredAt: occurredAt ?? this.occurredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedByName: acknowledgedByName ?? this.acknowledgedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      createdAt: createdAt ?? this.createdAt,
      createdByName: createdByName ?? this.createdByName,
      evidence: evidence ?? this.evidence,
      syncStatus: syncStatus ?? this.syncStatus,
      syncMessage: syncMessage ?? this.syncMessage,
      localMutationId: localMutationId ?? this.localMutationId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.apiValue,
      'status': status.apiValue,
      'category': category.apiValue,
      'categoryLabel': categoryLabel,
      'title': title,
      'details': details,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      if (acknowledgedAt != null)
        'acknowledgedAt': acknowledgedAt!.toUtc().toIso8601String(),
      if (acknowledgedByName != null) 'acknowledgedByName': acknowledgedByName,
      if (resolvedAt != null)
        'resolvedAt': resolvedAt!.toUtc().toIso8601String(),
      if (resolvedByName != null) 'resolvedByName': resolvedByName,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'createdByName': createdByName,
      'evidence': evidence.map((item) => item.toJson()).toList(),
      if (syncStatus != OfflineSyncStatus.synced)
        'syncStatus': syncStatus.storageValue,
      if (syncMessage != null) 'syncMessage': syncMessage,
      if (localMutationId != null) 'localMutationId': localMutationId,
    };
  }
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
    super.focus,
    super.clinicalPriority,
    super.dueAt,
    super.residentId,
    super.residentName,
    super.room,
    super.canComplete,
    super.canDefer,
    super.canEscalate,
    super.actionRestrictionReason,
  });

  factory ResidentTaskSummary.fromJson(Map<String, dynamic> json) {
    return ResidentTaskSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      focus: json['focus'] == null
          ? TaskFocus.general
          : TaskFocusX.fromApiValue(json['focus'] as String),
      clinicalPriority: json['clinicalPriority'] == null
          ? TaskClinicalPriority.routine
          : TaskClinicalPriorityX.fromApiValue(
              json['clinicalPriority'] as String,
            ),
      status: TaskStatusX.fromApiValue(json['status'] as String),
      dueAt: json['dueAt'] == null
          ? null
          : parseApiDateTime(json['dueAt'] as String),
      residentId: json['residentId'] as String?,
      residentName: json['residentName'] as String?,
      room: json['room'] as String?,
      canComplete: json['canComplete'] as bool?,
      canDefer: json['canDefer'] as bool?,
      canEscalate: json['canEscalate'] as bool?,
      actionRestrictionReason: json['actionRestrictionReason'] as String?,
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
    required super.aboutMe,
    required super.baselinePriority,
    required super.effectivePriority,
    required super.prioritySource,
    required super.activeIncidentCount,
    this.medicationSummary = const MedicationTaskSummary(),
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
      aboutMe: (json['aboutMe'] as String?) ?? '',
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
      medicationSummary: json['medicationSummary'] == null
          ? const MedicationTaskSummary()
          : MedicationTaskSummary.fromJson(
              json['medicationSummary'] as Map<String, dynamic>,
            ),
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

  final MedicationTaskSummary medicationSummary;
  final List<ResidentIncident> activeIncidents;
  final List<ResidentTaskSummary> currentTasks;
  final List<ResidentTimelineEntry> timeline;

  ResidentDetail copyWith({
    String? id,
    String? fullName,
    String? roomLabel,
    int? floorNumber,
    String? unitLabel,
    String? recognitionImageKey,
    String? todaySummary,
    String? assignmentContext,
    String? contextLine,
    List<String>? alerts,
    String? aboutMe,
    ResidentPriorityLevel? baselinePriority,
    ResidentPriorityLevel? effectivePriority,
    ResidentPrioritySource? prioritySource,
    int? activeIncidentCount,
    MedicationTaskSummary? medicationSummary,
    List<ResidentIncident>? activeIncidents,
    List<ResidentTaskSummary>? currentTasks,
    List<ResidentTimelineEntry>? timeline,
  }) {
    return ResidentDetail(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      roomLabel: roomLabel ?? this.roomLabel,
      floorNumber: floorNumber ?? this.floorNumber,
      unitLabel: unitLabel ?? this.unitLabel,
      recognitionImageKey: recognitionImageKey ?? this.recognitionImageKey,
      todaySummary: todaySummary ?? this.todaySummary,
      assignmentContext: assignmentContext ?? this.assignmentContext,
      contextLine: contextLine ?? this.contextLine,
      alerts: alerts ?? this.alerts,
      aboutMe: aboutMe ?? this.aboutMe,
      baselinePriority: baselinePriority ?? this.baselinePriority,
      effectivePriority: effectivePriority ?? this.effectivePriority,
      prioritySource: prioritySource ?? this.prioritySource,
      activeIncidentCount: activeIncidentCount ?? this.activeIncidentCount,
      medicationSummary: medicationSummary ?? this.medicationSummary,
      activeIncidents: activeIncidents ?? this.activeIncidents,
      currentTasks: currentTasks ?? this.currentTasks,
      timeline: timeline ?? this.timeline,
    );
  }
}

class ResidentTimelineEntryDraft {
  const ResidentTimelineEntryDraft({
    required this.type,
    required this.details,
    this.personalCareSubtype,
    this.mealType,
    this.mealIntakeAmount,
    this.evidence,
  });

  factory ResidentTimelineEntryDraft.fromJson(Map<String, dynamic> json) {
    return ResidentTimelineEntryDraft(
      type: ResidentEntryTypeX.fromApiValue(json['type'] as String),
      details: (json['details'] as String?) ?? '',
      personalCareSubtype: json['personalCareSubtype'] == null
          ? null
          : PersonalCareSubtypeX.fromApiValue(
              json['personalCareSubtype'] as String,
            ),
      mealType: json['mealType'] == null
          ? null
          : MealTypeX.fromApiValue(json['mealType'] as String),
      mealIntakeAmount: json['mealIntakeAmount'] == null
          ? null
          : MealIntakeAmountX.fromApiValue(json['mealIntakeAmount'] as String),
    );
  }

  final ResidentEntryType type;
  final String details;
  final PersonalCareSubtype? personalCareSubtype;
  final MealType? mealType;
  final MealIntakeAmount? mealIntakeAmount;
  final TimelineEvidenceFile? evidence;

  Map<String, dynamic> toJson() {
    return {
      'type': type.apiValue,
      'details': details,
      if (personalCareSubtype != null)
        'personalCareSubtype': personalCareSubtype!.apiValue,
      if (mealType != null) 'mealType': mealType!.apiValue,
      if (mealIntakeAmount != null)
        'mealIntakeAmount': mealIntakeAmount!.apiValue,
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

  factory ResidentIncidentDraft.fromJson(Map<String, dynamic> json) {
    return ResidentIncidentDraft(
      severity: IncidentSeverityX.fromApiValue(json['severity'] as String),
      category: IncidentCategoryX.fromApiValue(json['category'] as String),
      title: json['title'] as String,
      details: json['details'] as String,
    );
  }

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
  const ShiftOverview({
    required this.currentShift,
    this.medicationSummary = const MedicationTaskSummary(),
    this.medicationOperationalSummary,
  });

  factory ShiftOverview.fromJson(Map<String, dynamic> json) {
    return ShiftOverview(
      currentShift: json['currentShift'] == null
          ? null
          : ShiftAssignment.fromJson(
              json['currentShift'] as Map<String, dynamic>,
            ),
      medicationSummary: json['medicationSummary'] == null
          ? const MedicationTaskSummary()
          : MedicationTaskSummary.fromJson(
              json['medicationSummary'] as Map<String, dynamic>,
            ),
      medicationOperationalSummary: json['medicationOperationalSummary'] == null
          ? null
          : MedicationShiftOperationalSummary.fromJson(
              json['medicationOperationalSummary'] as Map<String, dynamic>,
            ),
    );
  }

  final ShiftAssignment? currentShift;
  final MedicationTaskSummary medicationSummary;
  final MedicationShiftOperationalSummary? medicationOperationalSummary;
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
