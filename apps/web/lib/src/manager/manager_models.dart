export 'package:sercesync_domain/sercesync_domain.dart'
    show
        AppUserRole,
        AppUserRoleX,
        IncidentSeverity,
        IncidentSeverityX,
        ResidentPriorityLevel,
        ResidentPriorityLevelX,
        ResidentPrioritySource,
        ResidentPrioritySourceX,
        ShiftPeriod,
        ShiftStatus,
        ShiftStatusX,
        UserProfile,
        residentPhotoAssetPath;

import 'package:sercesync_domain/sercesync_domain.dart';

typedef ManagerResidentPriorityLevel = ResidentPriorityLevel;
typedef ManagerResidentPrioritySource = ResidentPrioritySource;
typedef ManagerUserRole = AppUserRole;
typedef ManagerShiftStatus = ShiftStatus;
typedef ManagerIncidentSeverity = IncidentSeverity;

enum ManagerExceptionKind { incident, task }

enum ManagerActivityKind { note, task, incident }

enum ManagerExceptionStatus {
  open,
  acknowledged,
  resolved,
  pending,
  completed,
  deferred,
  escalated,
  overdue,
}

DateTime _parseManagerDateTime(String value) => DateTime.parse(value).toLocal();

ManagerResidentPriorityLevel _parseManagerResidentPriorityLevel(String? value) {
  return ResidentPriorityLevelX.fromApiValue(value ?? 'GREEN');
}

ManagerResidentPrioritySource _parseManagerResidentPrioritySource(
  String? value,
) {
  return ResidentPrioritySourceX.fromApiValue(value ?? 'BASELINE');
}

ManagerUserRole _parseManagerUserRole(String? value) {
  switch (value) {
    case 'CARER':
      return ManagerUserRole.carer;
    case 'NURSE':
      return ManagerUserRole.nurse;
    case 'MANAGER':
      return ManagerUserRole.manager;
  }

  throw ArgumentError.value(value, 'value', 'Unknown user role');
}

ManagerShiftStatus _parseManagerShiftStatus(String? value) {
  return ShiftStatusX.fromApiValue(value ?? 'PLANNED');
}

ManagerExceptionKind _parseManagerExceptionKind(String? value) {
  switch (value) {
    case 'INCIDENT':
      return ManagerExceptionKind.incident;
    case 'TASK':
    default:
      return ManagerExceptionKind.task;
  }
}

ManagerActivityKind _parseManagerActivityKind(String? value) {
  switch (value) {
    case 'NOTE':
      return ManagerActivityKind.note;
    case 'INCIDENT':
      return ManagerActivityKind.incident;
    case 'TASK':
    default:
      return ManagerActivityKind.task;
  }
}

ManagerIncidentSeverity? _parseManagerIncidentSeverity(String? value) {
  switch (value) {
    case 'RED':
      return IncidentSeverity.red;
    case 'AMBER':
      return IncidentSeverity.amber;
    default:
      return null;
  }
}

ManagerExceptionStatus _parseManagerExceptionStatus(String? value) {
  switch (value) {
    case 'OPEN':
      return ManagerExceptionStatus.open;
    case 'ACKNOWLEDGED':
      return ManagerExceptionStatus.acknowledged;
    case 'RESOLVED':
      return ManagerExceptionStatus.resolved;
    case 'COMPLETED':
      return ManagerExceptionStatus.completed;
    case 'DEFERRED':
      return ManagerExceptionStatus.deferred;
    case 'ESCALATED':
      return ManagerExceptionStatus.escalated;
    case 'OVERDUE':
      return ManagerExceptionStatus.overdue;
    case 'PENDING':
    default:
      return ManagerExceptionStatus.pending;
  }
}

abstract class _ManagerFeedItem {
  const _ManagerFeedItem({
    required this.id,
    required this.title,
    required this.shiftId,
    required this.residentName,
    required this.floorNumber,
    required this.unitLabel,
    required this.roomLabel,
    required this.description,
    required this.badge,
    required this.badgeTone,
  });

  final String id;
  final String title;
  final String shiftId;
  final String residentName;
  final int? floorNumber;
  final String unitLabel;
  final String roomLabel;
  final String description;
  final String badge;
  final String badgeTone;

  String get locationLabel {
    final segments = <String>[];
    if (unitLabel.trim().isNotEmpty) {
      segments.add(unitLabel.trim());
    }
    if (floorNumber != null) {
      segments.add('Floor $floorNumber');
    }
    if (roomLabel.trim().isNotEmpty) {
      segments.add(roomLabel.trim());
    }
    return segments.join(' • ');
  }
}

extension ManagerExceptionStatusPresentation on ManagerExceptionStatus {
  String get label => switch (this) {
    ManagerExceptionStatus.open => 'Open',
    ManagerExceptionStatus.acknowledged => 'Acknowledged',
    ManagerExceptionStatus.resolved => 'Resolved',
    ManagerExceptionStatus.pending => 'Pending',
    ManagerExceptionStatus.completed => 'Completed',
    ManagerExceptionStatus.deferred => 'Deferred',
    ManagerExceptionStatus.escalated => 'Escalated',
    ManagerExceptionStatus.overdue => 'Overdue',
  };
}

class ManagerUser extends UserProfile<ManagerUserRole> {
  const ManagerUser({
    required super.id,
    required super.email,
    required super.displayName,
    required super.role,
  });

  factory ManagerUser.fromJson(Map<String, dynamic> json) {
    return ManagerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: _parseManagerUserRole(json['role'] as String?),
    );
  }
}

class ManagerSession {
  const ManagerSession({required this.accessToken, required this.user});

  factory ManagerSession.fromJson(Map<String, dynamic> json) {
    return ManagerSession(
      accessToken: json['accessToken'] as String? ?? '',
      user: ManagerUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final ManagerUser user;
}

class ManagerDashboardSnapshot {
  const ManagerDashboardSnapshot({
    required this.activeShift,
    required this.metrics,
    required this.activityFeed,
    required this.exceptionFeed,
    required this.complianceSeries,
    this.medicationOverview,
  });

  factory ManagerDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final parsedActiveShifts =
        (json['activeShifts'] as List<dynamic>? ?? const [])
            .map(
              (entry) =>
                  ManagerShiftSummary.fromJson(entry as Map<String, dynamic>),
            )
            .toList(growable: false);
    final parsedActiveShift = json['activeShift'] != null
        ? ManagerShiftSummary.fromJson(
            json['activeShift'] as Map<String, dynamic>,
          )
        : parsedActiveShifts.first;

    return ManagerDashboardSnapshot(
      activeShift: parsedActiveShift,
      metrics: ManagerDashboardMetrics.fromJson(
        json['metrics'] as Map<String, dynamic>,
      ),
      activityFeed: (json['activityFeed'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ManagerActivityFeedItem.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      exceptionFeed: (json['exceptionFeed'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerExceptionFeedItem.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(),
      complianceSeries: (json['complianceSeries'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                ManagerCompliancePoint.fromJson(entry as Map<String, dynamic>),
          )
          .toList(),
      medicationOverview: json['medicationOverview'] == null
          ? null
          : ManagerMedicationOverview.fromJson(
              json['medicationOverview'] as Map<String, dynamic>,
            ),
    );
  }

  final ManagerShiftSummary activeShift;
  final ManagerDashboardMetrics metrics;
  final List<ManagerActivityFeedItem> activityFeed;
  final List<ManagerExceptionFeedItem> exceptionFeed;
  final List<ManagerCompliancePoint> complianceSeries;
  final ManagerMedicationOverview? medicationOverview;
}

class ManagerShiftSummary extends ShiftPeriod {
  const ManagerShiftSummary({
    required super.id,
    required super.name,
    required super.status,
    required super.unitLabel,
    required super.floorNumber,
    required super.startsAt,
    required super.endsAt,
    required this.assignedUsers,
  });

  factory ManagerShiftSummary.fromJson(Map<String, dynamic> json) {
    return ManagerShiftSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      status: _parseManagerShiftStatus(json['status'] as String?),
      unitLabel: json['unitLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      startsAt: _parseManagerDateTime(json['startsAt'] as String),
      endsAt: _parseManagerDateTime(json['endsAt'] as String),
      assignedUsers: (json['assignedUsers'] as List<dynamic>? ?? const [])
          .map((entry) => ManagerUser.fromJson(entry as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  final List<ManagerUser> assignedUsers;
}

class ManagerDashboardMetrics {
  const ManagerDashboardMetrics({
    required this.overdueTasks,
    required this.escalatedItems,
    required this.unreadHandovers,
    required this.shiftCompletionPercent,
    required this.activeIncidents,
  });

  factory ManagerDashboardMetrics.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardMetrics(
      overdueTasks: json['overdueTasks'] as int? ?? 0,
      escalatedItems: json['escalatedItems'] as int? ?? 0,
      unreadHandovers: json['unreadHandovers'] as int? ?? 0,
      shiftCompletionPercent: json['shiftCompletionPercent'] as int? ?? 0,
      activeIncidents: json['activeIncidents'] as int? ?? 0,
    );
  }

  final int overdueTasks;
  final int escalatedItems;
  final int unreadHandovers;
  final int shiftCompletionPercent;
  final int activeIncidents;
}

class ManagerExceptionFeedItem extends _ManagerFeedItem {
  const ManagerExceptionFeedItem({
    required super.id,
    required this.kind,
    required super.title,
    required super.shiftId,
    required super.residentName,
    required super.floorNumber,
    required super.unitLabel,
    required super.roomLabel,
    required super.description,
    required this.status,
    required this.severity,
    required super.badge,
    required super.badgeTone,
    required this.canAcknowledge,
    required this.canResolve,
    required this.occurredAt,
    required this.dueAt,
  });

  factory ManagerExceptionFeedItem.fromJson(Map<String, dynamic> json) {
    return ManagerExceptionFeedItem(
      id: json['id'] as String,
      kind: _parseManagerExceptionKind(json['kind'] as String?),
      title: json['title'] as String,
      shiftId: json['shiftId'] as String? ?? '',
      residentName: json['residentName'] as String,
      floorNumber: json['floorNumber'] as int?,
      unitLabel: json['unitLabel'] as String? ?? '',
      roomLabel: json['roomLabel'] as String,
      description: json['description'] as String,
      status: _parseManagerExceptionStatus(json['status'] as String?),
      severity: _parseManagerIncidentSeverity(json['severity'] as String?),
      badge: json['badge'] as String,
      badgeTone: json['badgeTone'] as String,
      canAcknowledge: json['canAcknowledge'] as bool? ?? false,
      canResolve: json['canResolve'] as bool? ?? false,
      occurredAt: json['occurredAt'] == null
          ? null
          : _parseManagerDateTime(json['occurredAt'] as String),
      dueAt: json['dueAt'] == null
          ? null
          : _parseManagerDateTime(json['dueAt'] as String),
    );
  }
  final ManagerExceptionKind kind;
  final ManagerExceptionStatus status;
  final ManagerIncidentSeverity? severity;
  final bool canAcknowledge;
  final bool canResolve;
  final DateTime? occurredAt;
  final DateTime? dueAt;

  bool get isIncident => kind == ManagerExceptionKind.incident;
}

class ManagerActivityFeedItem extends _ManagerFeedItem {
  const ManagerActivityFeedItem({
    required super.id,
    required this.kind,
    required super.title,
    required super.shiftId,
    required super.residentName,
    required super.floorNumber,
    required super.unitLabel,
    required super.roomLabel,
    required super.description,
    required this.actorName,
    required this.occurredAt,
    required super.badge,
    required super.badgeTone,
  });

  factory ManagerActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ManagerActivityFeedItem(
      id: json['id'] as String,
      kind: _parseManagerActivityKind(json['kind'] as String?),
      title: json['title'] as String,
      shiftId: json['shiftId'] as String? ?? '',
      residentName: json['residentName'] as String,
      floorNumber: json['floorNumber'] as int?,
      unitLabel: json['unitLabel'] as String? ?? '',
      roomLabel: json['roomLabel'] as String,
      description: json['description'] as String,
      actorName: json['actorName'] as String? ?? 'Unknown user',
      occurredAt: _parseManagerDateTime(json['occurredAt'] as String),
      badge: json['badge'] as String,
      badgeTone: json['badgeTone'] as String,
    );
  }
  final ManagerActivityKind kind;
  final String actorName;
  final DateTime occurredAt;
}

class ManagerCompliancePoint {
  const ManagerCompliancePoint({required this.timestamp, required this.value});

  factory ManagerCompliancePoint.fromJson(Map<String, dynamic> json) {
    return ManagerCompliancePoint(
      timestamp: _parseManagerDateTime(json['timestamp'] as String),
      value: json['value'] as int? ?? 0,
    );
  }

  final DateTime timestamp;
  final int value;
}

class ManagerResidentRecord extends ResidentIdentity {
  const ManagerResidentRecord({
    required super.id,
    required super.fullName,
    required this.roomNumber,
    required super.roomLabel,
    required super.floorNumber,
    required super.unitLabel,
    required super.recognitionImageKey,
    required super.aboutMe,
    required this.isActive,
    required super.baselinePriority,
    required super.effectivePriority,
    required super.prioritySource,
    required super.activeIncidentCount,
  });

  factory ManagerResidentRecord.fromJson(Map<String, dynamic> json) {
    return ManagerResidentRecord(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      roomNumber: json['roomNumber'] as int,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      recognitionImageKey: json['recognitionImageKey'] as String,
      aboutMe: (json['aboutMe'] as String?) ?? '',
      isActive: json['isActive'] as bool,
      baselinePriority: _parseManagerResidentPriorityLevel(
        json['baselinePriority'] as String?,
      ),
      effectivePriority: _parseManagerResidentPriorityLevel(
        json['effectivePriority'] as String?,
      ),
      prioritySource: _parseManagerResidentPrioritySource(
        json['prioritySource'] as String?,
      ),
      activeIncidentCount: json['activeIncidentCount'] as int? ?? 0,
    );
  }

  final int roomNumber;
  final bool isActive;
}

class ManagerMedicationOverview {
  const ManagerMedicationOverview({
    required this.workflowNote,
    required this.totals,
    required this.exceptions,
    required this.recentPrnEvents,
    required this.recentChanges,
  });

  factory ManagerMedicationOverview.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationOverview(
      workflowNote: json['workflowNote'] as String? ?? '',
      totals: ManagerMedicationOverviewTotals.fromJson(
        json['totals'] as Map<String, dynamic>? ?? const {},
      ),
      exceptions: (json['exceptions'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationException.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      recentPrnEvents: (json['recentPrnEvents'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationAdministrationRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      recentChanges: (json['recentChanges'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationChangeLogRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String workflowNote;
  final ManagerMedicationOverviewTotals totals;
  final List<ManagerMedicationException> exceptions;
  final List<ManagerMedicationAdministrationRecord> recentPrnEvents;
  final List<ManagerMedicationChangeLogRecord> recentChanges;
}

class ManagerMedicationOverviewTotals {
  const ManagerMedicationOverviewTotals({
    required this.overdue,
    required this.refused,
    required this.omitted,
    required this.delayed,
    required this.notAvailable,
    required this.held,
    required this.recentPrnAdministrations,
  });

  factory ManagerMedicationOverviewTotals.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationOverviewTotals(
      overdue: json['overdue'] as int? ?? 0,
      refused: json['refused'] as int? ?? 0,
      omitted: json['omitted'] as int? ?? 0,
      delayed: json['delayed'] as int? ?? 0,
      notAvailable: json['notAvailable'] as int? ?? 0,
      held: json['held'] as int? ?? 0,
      recentPrnAdministrations: json['recentPrnAdministrations'] as int? ?? 0,
    );
  }

  final int overdue;
  final int refused;
  final int omitted;
  final int delayed;
  final int notAvailable;
  final int held;
  final int recentPrnAdministrations;
}

class ManagerMedicationException {
  const ManagerMedicationException({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.roomLabel,
    required this.medicationOrderId,
    required this.medicationName,
    required this.strength,
    required this.roundLabel,
    required this.status,
    required this.dueWindowStart,
    required this.dueWindowEnd,
    required this.recordedByUserId,
    required this.recordedByUserName,
    required this.recordedAt,
    required this.reason,
    required this.notes,
    required this.residentEmarPath,
    required this.doseInstanceId,
  });

  factory ManagerMedicationException.fromJson(Map<String, dynamic> json) {
    final resolvedId =
        (json['id'] as String?) ??
        (json['doseInstanceId'] as String?) ??
        (json['medicationOrderId'] as String?) ??
        '';

    return ManagerMedicationException(
      id: resolvedId,
      residentId: json['residentId'] as String,
      residentName: json['residentName'] as String? ?? 'Resident',
      roomLabel: json['roomLabel'] as String? ?? '',
      medicationOrderId: json['medicationOrderId'] as String? ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      strength: json['strength'] as String?,
      roundLabel: json['roundLabel'] as String? ?? 'CUSTOM',
      status: json['status'] as String? ?? 'DUE',
      dueWindowStart: _parseManagerDateTime(json['dueWindowStart'] as String),
      dueWindowEnd: _parseManagerDateTime(json['dueWindowEnd'] as String),
      recordedByUserId: json['recordedByUserId'] as String?,
      recordedByUserName: json['recordedByUserName'] as String?,
      recordedAt: json['recordedAt'] == null
          ? null
          : _parseManagerDateTime(json['recordedAt'] as String),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      residentEmarPath: json['residentEmarPath'] as String? ?? '',
      doseInstanceId: json['doseInstanceId'] as String? ?? '',
    );
  }

  final String id;
  final String residentId;
  final String residentName;
  final String roomLabel;
  final String medicationOrderId;
  final String medicationName;
  final String? strength;
  final String roundLabel;
  final String status;
  final DateTime dueWindowStart;
  final DateTime dueWindowEnd;
  final String? recordedByUserId;
  final String? recordedByUserName;
  final DateTime? recordedAt;
  final String? reason;
  final String? notes;
  final String residentEmarPath;
  final String doseInstanceId;

  String get medicationLabel => [
    medicationName,
    strength,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
}

class ManagerResidentEmarProfile {
  const ManagerResidentEmarProfile({
    required this.workflowNote,
    required this.downtimeNotice,
    required this.safetyBanner,
    required this.chart,
    required this.allergies,
    required this.scheduledMedications,
    required this.prnMedications,
    required this.recentEvents,
    required this.stockOverview,
    required this.changeHistory,
  });

  factory ManagerResidentEmarProfile.fromJson(Map<String, dynamic> json) {
    return ManagerResidentEmarProfile(
      workflowNote: json['workflowNote'] as String? ?? '',
      downtimeNotice: json['downtimeNotice'] as String? ?? '',
      safetyBanner: json['safetyBanner'] as String? ?? '',
      chart: json['chart'] == null
          ? null
          : ManagerMedicationChartSummary.fromJson(
              json['chart'] as Map<String, dynamic>,
            ),
      allergies: (json['allergies'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationAllergyRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      scheduledMedications:
          (json['scheduledMedications'] as List<dynamic>? ?? const [])
              .map(
                (entry) => ManagerMedicationOrderRecord.fromJson(
                  entry as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
      prnMedications: (json['prnMedications'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationOrderRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      recentEvents: (json['recentEvents'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationAdministrationRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      stockOverview: (json['stockOverview'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationStockSummary.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      changeHistory: (json['changeHistory'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationChangeLogRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String workflowNote;
  final String downtimeNotice;
  final String safetyBanner;
  final ManagerMedicationChartSummary? chart;
  final List<ManagerMedicationAllergyRecord> allergies;
  final List<ManagerMedicationOrderRecord> scheduledMedications;
  final List<ManagerMedicationOrderRecord> prnMedications;
  final List<ManagerMedicationAdministrationRecord> recentEvents;
  final List<ManagerMedicationStockSummary> stockOverview;
  final List<ManagerMedicationChangeLogRecord> changeHistory;
}

class ManagerMedicationChartSummary {
  const ManagerMedicationChartSummary({
    required this.id,
    required this.status,
    required this.createdByUserId,
    required this.createdByUserName,
    required this.reviewedByUserId,
    required this.reviewedByUserName,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagerMedicationChartSummary.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationChartSummary(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'ACTIVE',
      createdByUserId: json['createdByUserId'] as String?,
      createdByUserName: json['createdByUserName'] as String?,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedByUserName: json['reviewedByUserName'] as String?,
      archivedAt: json['archivedAt'] == null
          ? null
          : _parseManagerDateTime(json['archivedAt'] as String),
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String status;
  final String? createdByUserId;
  final String? createdByUserName;
  final String? reviewedByUserId;
  final String? reviewedByUserName;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ManagerMedicationAllergyRecord {
  const ManagerMedicationAllergyRecord({
    required this.id,
    required this.substance,
    required this.reaction,
    required this.severity,
    required this.recordedByUserId,
    required this.recordedByUserName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagerMedicationAllergyRecord.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationAllergyRecord(
      id: json['id'] as String,
      substance: json['substance'] as String? ?? '',
      reaction: json['reaction'] as String?,
      severity: json['severity'] as String?,
      recordedByUserId: json['recordedByUserId'] as String?,
      recordedByUserName: json['recordedByUserName'] as String?,
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String substance;
  final String? reaction;
  final String? severity;
  final String? recordedByUserId;
  final String? recordedByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ManagerMedicationScheduleRecord {
  const ManagerMedicationScheduleRecord({
    required this.id,
    required this.roundLabel,
    required this.anchorType,
    required this.windowStartOffsetMinutes,
    required this.windowEndOffsetMinutes,
    required this.fixedTimeLocal,
    required this.daysOfWeek,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagerMedicationScheduleRecord.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationScheduleRecord(
      id: json['id'] as String,
      roundLabel: json['roundLabel'] as String? ?? 'CUSTOM',
      anchorType: json['anchorType'] as String? ?? 'SHIFT_START',
      windowStartOffsetMinutes: json['windowStartOffsetMinutes'] as int?,
      windowEndOffsetMinutes: json['windowEndOffsetMinutes'] as int?,
      fixedTimeLocal: json['fixedTimeLocal'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
      active: json['active'] as bool? ?? true,
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String roundLabel;
  final String anchorType;
  final int? windowStartOffsetMinutes;
  final int? windowEndOffsetMinutes;
  final String? fixedTimeLocal;
  final List<String> daysOfWeek;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ManagerPrnProtocolRecord {
  const ManagerPrnProtocolRecord({
    required this.id,
    required this.indication,
    required this.whenToOffer,
    required this.doseInstructions,
    required this.minimumIntervalMinutes,
    required this.maxDosePer24Hours,
    required this.expectedEffect,
    required this.monitoringRequired,
    required this.whenToEscalate,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ManagerPrnProtocolRecord.fromJson(Map<String, dynamic> json) {
    return ManagerPrnProtocolRecord(
      id: json['id'] as String,
      indication: json['indication'] as String? ?? '',
      whenToOffer: json['whenToOffer'] as String? ?? '',
      doseInstructions: json['doseInstructions'] as String? ?? '',
      minimumIntervalMinutes: json['minimumIntervalMinutes'] as int?,
      maxDosePer24Hours: json['maxDosePer24Hours'] as int?,
      expectedEffect: json['expectedEffect'] as String?,
      monitoringRequired: json['monitoringRequired'] as String?,
      whenToEscalate: json['whenToEscalate'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String indication;
  final String whenToOffer;
  final String doseInstructions;
  final int? minimumIntervalMinutes;
  final int? maxDosePer24Hours;
  final String? expectedEffect;
  final String? monitoringRequired;
  final String? whenToEscalate;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ManagerMedicationStockSummary {
  const ManagerMedicationStockSummary({
    required this.id,
    required this.currentQuantity,
    required this.quantityUnit,
    required this.lastCheckedByUserId,
    required this.lastCheckedByUserName,
    required this.lastCheckedAt,
    required this.notes,
    required this.updatedAt,
  });

  factory ManagerMedicationStockSummary.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationStockSummary(
      id: json['id'] as String,
      currentQuantity: json['currentQuantity'] as String? ?? '',
      quantityUnit: json['quantityUnit'] as String? ?? '',
      lastCheckedByUserId: json['lastCheckedByUserId'] as String?,
      lastCheckedByUserName: json['lastCheckedByUserName'] as String?,
      lastCheckedAt: json['lastCheckedAt'] == null
          ? null
          : _parseManagerDateTime(json['lastCheckedAt'] as String),
      notes: json['notes'] as String?,
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String currentQuantity;
  final String quantityUnit;
  final String? lastCheckedByUserId;
  final String? lastCheckedByUserName;
  final DateTime? lastCheckedAt;
  final String? notes;
  final DateTime updatedAt;
}

class ManagerMedicationOrderRecord {
  const ManagerMedicationOrderRecord({
    required this.id,
    required this.medicationName,
    required this.formulation,
    required this.strength,
    required this.doseAmount,
    required this.doseUnit,
    required this.route,
    required this.instructions,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.isControlledDrug,
    required this.requiresWitness,
    required this.isPrn,
    required this.sourceType,
    required this.createdByUserId,
    required this.createdByUserName,
    required this.updatedByUserId,
    required this.updatedByUserName,
    required this.createdAt,
    required this.updatedAt,
    required this.deactivatedAt,
    required this.deactivationReason,
    required this.schedules,
    required this.prnProtocol,
    required this.stock,
  });

  factory ManagerMedicationOrderRecord.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationOrderRecord(
      id: json['id'] as String,
      medicationName: json['medicationName'] as String? ?? '',
      formulation: json['formulation'] as String?,
      strength: json['strength'] as String?,
      doseAmount: json['doseAmount'] as String? ?? '',
      doseUnit: json['doseUnit'] as String? ?? '',
      route: json['route'] as String? ?? '',
      instructions: json['instructions'] as String? ?? '',
      startDate: _parseManagerDateTime(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : _parseManagerDateTime(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isControlledDrug: json['isControlledDrug'] as bool? ?? false,
      requiresWitness: json['requiresWitness'] as bool? ?? false,
      isPrn: json['isPRN'] as bool? ?? false,
      sourceType: json['sourceType'] as String? ?? 'MANUAL_ENTRY',
      createdByUserId: json['createdByUserId'] as String?,
      createdByUserName: json['createdByUserName'] as String?,
      updatedByUserId: json['updatedByUserId'] as String?,
      updatedByUserName: json['updatedByUserName'] as String?,
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
      updatedAt: _parseManagerDateTime(json['updatedAt'] as String),
      deactivatedAt: json['deactivatedAt'] == null
          ? null
          : _parseManagerDateTime(json['deactivatedAt'] as String),
      deactivationReason: json['deactivationReason'] as String?,
      schedules: (json['schedules'] as List<dynamic>? ?? const [])
          .map(
            (entry) => ManagerMedicationScheduleRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      prnProtocol: json['prnProtocol'] == null
          ? null
          : ManagerPrnProtocolRecord.fromJson(
              json['prnProtocol'] as Map<String, dynamic>,
            ),
      stock: json['stock'] == null
          ? null
          : ManagerMedicationStockSummary.fromJson(
              json['stock'] as Map<String, dynamic>,
            ),
    );
  }

  final String id;
  final String medicationName;
  final String? formulation;
  final String? strength;
  final String doseAmount;
  final String doseUnit;
  final String route;
  final String instructions;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final bool isControlledDrug;
  final bool requiresWitness;
  final bool isPrn;
  final String sourceType;
  final String? createdByUserId;
  final String? createdByUserName;
  final String? updatedByUserId;
  final String? updatedByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deactivatedAt;
  final String? deactivationReason;
  final List<ManagerMedicationScheduleRecord> schedules;
  final ManagerPrnProtocolRecord? prnProtocol;
  final ManagerMedicationStockSummary? stock;

  String get titleLine => [
    medicationName,
    strength,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

  String get doseLine => '$doseAmount $doseUnit via $route';
}

class ManagerMedicationAdministrationRecord {
  const ManagerMedicationAdministrationRecord({
    required this.id,
    required this.doseInstanceId,
    required this.residentId,
    required this.residentName,
    required this.roomLabel,
    required this.shiftId,
    required this.medicationOrderId,
    required this.medicationName,
    required this.strength,
    required this.formulation,
    required this.eventType,
    required this.doseGiven,
    required this.doseUnit,
    required this.reason,
    required this.notes,
    required this.recordedByUserId,
    required this.recordedByUserName,
    required this.recordedAt,
    required this.witnessUserId,
    required this.witnessUserName,
    required this.createdAt,
  });

  factory ManagerMedicationAdministrationRecord.fromJson(
    Map<String, dynamic> json,
  ) {
    return ManagerMedicationAdministrationRecord(
      id: json['id'] as String,
      doseInstanceId: json['doseInstanceId'] as String?,
      residentId: json['residentId'] as String,
      residentName: json['residentName'] as String? ?? 'Resident',
      roomLabel: json['roomLabel'] as String? ?? '',
      shiftId: json['shiftId'] as String? ?? '',
      medicationOrderId: json['medicationOrderId'] as String? ?? '',
      medicationName: json['medicationName'] as String? ?? '',
      strength: json['strength'] as String?,
      formulation: json['formulation'] as String?,
      eventType: json['eventType'] as String? ?? '',
      doseGiven: json['doseGiven'] as String?,
      doseUnit: json['doseUnit'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      recordedByUserId: json['recordedByUserId'] as String?,
      recordedByUserName: json['recordedByUserName'] as String?,
      recordedAt: _parseManagerDateTime(json['recordedAt'] as String),
      witnessUserId: json['witnessUserId'] as String?,
      witnessUserName: json['witnessUserName'] as String?,
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
    );
  }

  final String id;
  final String? doseInstanceId;
  final String residentId;
  final String residentName;
  final String roomLabel;
  final String shiftId;
  final String medicationOrderId;
  final String medicationName;
  final String? strength;
  final String? formulation;
  final String eventType;
  final String? doseGiven;
  final String? doseUnit;
  final String? reason;
  final String? notes;
  final String? recordedByUserId;
  final String? recordedByUserName;
  final DateTime recordedAt;
  final String? witnessUserId;
  final String? witnessUserName;
  final DateTime createdAt;

  String get medicationLabel => [
    medicationName,
    strength,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
}

class ManagerMedicationChangeLogRecord {
  const ManagerMedicationChangeLogRecord({
    required this.id,
    required this.medicationOrderId,
    required this.residentId,
    required this.medicationName,
    required this.changedByUserId,
    required this.changedByUserName,
    required this.changeType,
    required this.previousValueJson,
    required this.newValueJson,
    required this.reason,
    required this.createdAt,
  });

  factory ManagerMedicationChangeLogRecord.fromJson(Map<String, dynamic> json) {
    return ManagerMedicationChangeLogRecord(
      id: json['id'] as String,
      medicationOrderId: json['medicationOrderId'] as String,
      residentId: json['residentId'] as String,
      medicationName: json['medicationName'] as String? ?? '',
      changedByUserId: json['changedByUserId'] as String?,
      changedByUserName: json['changedByUserName'] as String?,
      changeType: json['changeType'] as String? ?? '',
      previousValueJson: json['previousValueJson'],
      newValueJson: json['newValueJson'],
      reason: json['reason'] as String? ?? '',
      createdAt: _parseManagerDateTime(json['createdAt'] as String),
    );
  }

  final String id;
  final String medicationOrderId;
  final String residentId;
  final String medicationName;
  final String? changedByUserId;
  final String? changedByUserName;
  final String changeType;
  final Object? previousValueJson;
  final Object? newValueJson;
  final String reason;
  final DateTime createdAt;
}

class ManagerMedicationOrderDraft {
  const ManagerMedicationOrderDraft({
    required this.medicationName,
    required this.formulation,
    required this.strength,
    required this.doseAmount,
    required this.doseUnit,
    required this.route,
    required this.instructions,
    required this.startDateIso,
    required this.endDateIso,
    required this.isControlledDrug,
    required this.requiresWitness,
    required this.isPrn,
    required this.sourceType,
    this.changeReason,
    this.reason,
  });

  final String medicationName;
  final String formulation;
  final String strength;
  final String doseAmount;
  final String doseUnit;
  final String route;
  final String instructions;
  final String startDateIso;
  final String? endDateIso;
  final bool isControlledDrug;
  final bool requiresWitness;
  final bool isPrn;
  final String sourceType;
  final String? changeReason;
  final String? reason;

  Map<String, dynamic> toCreateJson() {
    return {
      'medicationName': medicationName,
      'formulation': formulation.isEmpty ? null : formulation,
      'strength': strength.isEmpty ? null : strength,
      'doseAmount': doseAmount,
      'doseUnit': doseUnit,
      'route': route,
      'instructions': instructions,
      'startDate': startDateIso,
      'endDate': endDateIso,
      'isControlledDrug': isControlledDrug,
      'requiresWitness': requiresWitness,
      'isPRN': isPrn,
      'sourceType': sourceType,
      'changeReason': changeReason,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'medicationName': medicationName,
      'formulation': formulation.isEmpty ? null : formulation,
      'strength': strength.isEmpty ? null : strength,
      'doseAmount': doseAmount,
      'doseUnit': doseUnit,
      'route': route,
      'instructions': instructions,
      'startDate': startDateIso,
      'endDate': endDateIso,
      'isControlledDrug': isControlledDrug,
      'requiresWitness': requiresWitness,
      'isPRN': isPrn,
      'sourceType': sourceType,
      'reason': reason,
    };
  }
}

class ManagerMedicationScheduleDraft {
  const ManagerMedicationScheduleDraft({
    required this.roundLabel,
    required this.anchorType,
    required this.windowStartOffsetMinutes,
    required this.windowEndOffsetMinutes,
    required this.fixedTimeLocal,
    required this.daysOfWeek,
  });

  final String roundLabel;
  final String anchorType;
  final int? windowStartOffsetMinutes;
  final int? windowEndOffsetMinutes;
  final String? fixedTimeLocal;
  final List<String> daysOfWeek;

  Map<String, dynamic> toJson() {
    return {
      'roundLabel': roundLabel,
      'anchorType': anchorType,
      'windowStartOffsetMinutes': windowStartOffsetMinutes,
      'windowEndOffsetMinutes': windowEndOffsetMinutes,
      'fixedTimeLocal': fixedTimeLocal,
      'daysOfWeek': daysOfWeek,
    };
  }
}

class ManagerPrnProtocolDraft {
  const ManagerPrnProtocolDraft({
    required this.indication,
    required this.whenToOffer,
    required this.doseInstructions,
    required this.minimumIntervalMinutes,
    required this.maxDosePer24Hours,
    required this.expectedEffect,
    required this.monitoringRequired,
    required this.whenToEscalate,
  });

  final String indication;
  final String whenToOffer;
  final String doseInstructions;
  final int? minimumIntervalMinutes;
  final int? maxDosePer24Hours;
  final String expectedEffect;
  final String monitoringRequired;
  final String whenToEscalate;

  Map<String, dynamic> toJson() {
    return {
      'indication': indication,
      'whenToOffer': whenToOffer,
      'doseInstructions': doseInstructions,
      'minimumIntervalMinutes': minimumIntervalMinutes,
      'maxDosePer24Hours': maxDosePer24Hours,
      'expectedEffect': expectedEffect.isEmpty ? null : expectedEffect,
      'monitoringRequired': monitoringRequired.isEmpty
          ? null
          : monitoringRequired,
      'whenToEscalate': whenToEscalate.isEmpty ? null : whenToEscalate,
    };
  }
}

class ManagerMedicationAllergyDraft {
  const ManagerMedicationAllergyDraft({
    required this.substance,
    required this.reaction,
    required this.severity,
  });

  final String substance;
  final String reaction;
  final String severity;

  Map<String, dynamic> toJson() {
    return {
      'substance': substance,
      'reaction': reaction.isEmpty ? null : reaction,
      'severity': severity.isEmpty ? null : severity,
    };
  }
}

class ManagerResidentDraft {
  const ManagerResidentDraft({
    required this.fullName,
    required this.roomNumber,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.aboutMe,
    required this.isActive,
    required this.baselinePriority,
  });

  final String fullName;
  final int roomNumber;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String aboutMe;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'roomNumber': roomNumber,
      'floorNumber': floorNumber,
      'unitLabel': unitLabel,
      'recognitionImageKey': recognitionImageKey,
      'aboutMe': aboutMe,
      'isActive': isActive,
      'baselinePriority': baselinePriority.apiValue,
    };
  }
}
