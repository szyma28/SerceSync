part of '../../manager_app.dart';

enum ManagerResidentPriorityLevel { green, amber, red }

enum ManagerResidentPrioritySource { baseline, incidentOverride }

enum ManagerUserRole { carer, seniorCarer, manager }

enum ManagerShiftStatus { planned, active, completed, cancelled }

enum ManagerExceptionKind { incident, task }

enum ManagerActivityKind { note, task, incident }

enum ManagerIncidentSeverity { amber, red }

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
  switch (value) {
    case 'RED':
      return ManagerResidentPriorityLevel.red;
    case 'AMBER':
      return ManagerResidentPriorityLevel.amber;
    case 'GREEN':
    default:
      return ManagerResidentPriorityLevel.green;
  }
}

ManagerResidentPrioritySource _parseManagerResidentPrioritySource(
  String? value,
) {
  switch (value) {
    case 'INCIDENT_OVERRIDE':
      return ManagerResidentPrioritySource.incidentOverride;
    case 'BASELINE':
    default:
      return ManagerResidentPrioritySource.baseline;
  }
}

ManagerUserRole _parseManagerUserRole(String? value) {
  switch (value) {
    case 'SENIOR_CARER':
      return ManagerUserRole.seniorCarer;
    case 'MANAGER':
      return ManagerUserRole.manager;
    case 'CARER':
    default:
      return ManagerUserRole.carer;
  }
}

ManagerShiftStatus _parseManagerShiftStatus(String? value) {
  switch (value) {
    case 'ACTIVE':
      return ManagerShiftStatus.active;
    case 'COMPLETED':
      return ManagerShiftStatus.completed;
    case 'CANCELLED':
      return ManagerShiftStatus.cancelled;
    case 'PLANNED':
    default:
      return ManagerShiftStatus.planned;
  }
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
      return ManagerIncidentSeverity.red;
    case 'AMBER':
      return ManagerIncidentSeverity.amber;
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
    required this.residentName,
    required this.roomLabel,
    required this.description,
    required this.badge,
    required this.badgeTone,
  });

  final String id;
  final String title;
  final String residentName;
  final String roomLabel;
  final String description;
  final String badge;
  final String badgeTone;
}

extension ManagerResidentPriorityLevelPresentation
    on ManagerResidentPriorityLevel {
  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    ManagerResidentPriorityLevel.green => 'Green',
    ManagerResidentPriorityLevel.amber => 'Amber',
    ManagerResidentPriorityLevel.red => 'Red',
  };

  String get baselineLabel => '$label baseline';
}

extension ManagerResidentPrioritySourcePresentation
    on ManagerResidentPrioritySource {
  String get label => switch (this) {
    ManagerResidentPrioritySource.baseline => 'Baseline',
    ManagerResidentPrioritySource.incidentOverride => 'Incident override',
  };
}

extension ManagerUserRolePresentation on ManagerUserRole {
  String get apiValue => switch (this) {
    ManagerUserRole.carer => 'CARER',
    ManagerUserRole.seniorCarer => 'SENIOR_CARER',
    ManagerUserRole.manager => 'MANAGER',
  };

  String get label => switch (this) {
    ManagerUserRole.carer => 'Carer',
    ManagerUserRole.seniorCarer => 'Senior carer',
    ManagerUserRole.manager => 'Manager',
  };
}

extension ManagerShiftStatusPresentation on ManagerShiftStatus {
  String get apiValue => switch (this) {
    ManagerShiftStatus.planned => 'PLANNED',
    ManagerShiftStatus.active => 'ACTIVE',
    ManagerShiftStatus.completed => 'COMPLETED',
    ManagerShiftStatus.cancelled => 'CANCELLED',
  };

  String get label => switch (this) {
    ManagerShiftStatus.planned => 'Planned',
    ManagerShiftStatus.active => 'Active',
    ManagerShiftStatus.completed => 'Completed',
    ManagerShiftStatus.cancelled => 'Cancelled',
  };
}

extension ManagerIncidentSeverityPresentation on ManagerIncidentSeverity {
  String get label => switch (this) {
    ManagerIncidentSeverity.amber => 'Amber',
    ManagerIncidentSeverity.red => 'Red',
  };
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

class ManagerUser {
  const ManagerUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  factory ManagerUser.fromJson(Map<String, dynamic> json) {
    return ManagerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      role: _parseManagerUserRole(json['role'] as String?),
    );
  }

  final String id;
  final String email;
  final String displayName;
  final ManagerUserRole role;
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
  });

  factory ManagerDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardSnapshot(
      activeShift: ManagerShiftSummary.fromJson(
        json['activeShift'] as Map<String, dynamic>,
      ),
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
    );
  }

  final ManagerShiftSummary activeShift;
  final ManagerDashboardMetrics metrics;
  final List<ManagerActivityFeedItem> activityFeed;
  final List<ManagerExceptionFeedItem> exceptionFeed;
  final List<ManagerCompliancePoint> complianceSeries;
}

class ManagerShiftSummary {
  const ManagerShiftSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.unitLabel,
    required this.floorNumber,
    required this.startsAt,
    required this.endsAt,
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
    );
  }

  final String id;
  final String name;
  final ManagerShiftStatus status;
  final String unitLabel;
  final int floorNumber;
  final DateTime startsAt;
  final DateTime endsAt;
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
    required super.residentName,
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
      residentName: json['residentName'] as String,
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
    required super.residentName,
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
      residentName: json['residentName'] as String,
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

class ManagerResidentRecord {
  const ManagerResidentRecord({
    required this.id,
    required this.fullName,
    required this.roomNumber,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
    required this.baselinePriority,
    required this.effectivePriority,
    required this.prioritySource,
    required this.activeIncidentCount,
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
      careSummary: json['careSummary'] as String,
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

  final String id;
  final String fullName;
  final int roomNumber;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;
  final ManagerResidentPriorityLevel effectivePriority;
  final ManagerResidentPrioritySource prioritySource;
  final int activeIncidentCount;
}

class ManagerResidentDraft {
  const ManagerResidentDraft({
    required this.fullName,
    required this.roomNumber,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.careSummary,
    required this.isActive,
    required this.baselinePriority,
  });

  final String fullName;
  final int roomNumber;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String careSummary;
  final bool isActive;
  final ManagerResidentPriorityLevel baselinePriority;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'roomNumber': roomNumber,
      'floorNumber': floorNumber,
      'unitLabel': unitLabel,
      'recognitionImageKey': recognitionImageKey,
      'careSummary': careSummary,
      'isActive': isActive,
      'baselinePriority': baselinePriority.apiValue,
    };
  }
}
