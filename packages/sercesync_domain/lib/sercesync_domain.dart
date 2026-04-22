DateTime parseApiDateTime(String value) => DateTime.parse(value).toLocal();

String residentPhotoAssetPath(String recognitionImageKey) {
  final residentMatch = RegExp(
    r'^resident-(\d{2})$',
  ).firstMatch(recognitionImageKey);
  if (residentMatch != null) {
    return 'assets/images/resident_profile_${residentMatch.group(1)}.png';
  }

  switch (recognitionImageKey) {
    case 'resident-a':
    case 'resident-b':
    case 'resident-c':
    case 'resident-d':
    default:
      return 'assets/images/Resident.png';
  }
}

enum ResidentPriorityLevel { green, amber, red }

extension ResidentPriorityLevelX on ResidentPriorityLevel {
  String get apiValue {
    switch (this) {
      case ResidentPriorityLevel.green:
        return 'GREEN';
      case ResidentPriorityLevel.amber:
        return 'AMBER';
      case ResidentPriorityLevel.red:
        return 'RED';
    }
  }

  String get label {
    switch (this) {
      case ResidentPriorityLevel.green:
        return 'Green';
      case ResidentPriorityLevel.amber:
        return 'Amber';
      case ResidentPriorityLevel.red:
        return 'Red';
    }
  }

  String get baselineLabel => '$label baseline';

  static ResidentPriorityLevel fromApiValue(String value) {
    switch (value) {
      case 'AMBER':
        return ResidentPriorityLevel.amber;
      case 'RED':
        return ResidentPriorityLevel.red;
      case 'GREEN':
      default:
        return ResidentPriorityLevel.green;
    }
  }
}

enum ResidentPrioritySource { baseline, incidentOverride }

extension ResidentPrioritySourceX on ResidentPrioritySource {
  String get apiValue {
    switch (this) {
      case ResidentPrioritySource.baseline:
        return 'BASELINE';
      case ResidentPrioritySource.incidentOverride:
        return 'INCIDENT_OVERRIDE';
    }
  }

  String get label {
    switch (this) {
      case ResidentPrioritySource.baseline:
        return 'Baseline';
      case ResidentPrioritySource.incidentOverride:
        return 'Incident override';
    }
  }

  static ResidentPrioritySource fromApiValue(String value) {
    switch (value) {
      case 'INCIDENT_OVERRIDE':
        return ResidentPrioritySource.incidentOverride;
      case 'BASELINE':
      default:
        return ResidentPrioritySource.baseline;
    }
  }
}

enum AppUserRole { carer, nurse, manager }

extension AppUserRoleX on AppUserRole {
  String get apiValue {
    switch (this) {
      case AppUserRole.carer:
        return 'CARER';
      case AppUserRole.nurse:
        return 'NURSE';
      case AppUserRole.manager:
        return 'MANAGER';
    }
  }

  String get label {
    switch (this) {
      case AppUserRole.carer:
        return 'Carer';
      case AppUserRole.nurse:
        return 'Nurse';
      case AppUserRole.manager:
        return 'Manager';
    }
  }

  static AppUserRole fromApiValue(String value) {
    switch (value) {
      case 'CARER':
        return AppUserRole.carer;
      case 'NURSE':
        return AppUserRole.nurse;
      case 'MANAGER':
        return AppUserRole.manager;
    }

    throw ArgumentError.value(value, 'value', 'Unknown user role');
  }
}

enum ShiftStatus { planned, active, completed, cancelled }

extension ShiftStatusX on ShiftStatus {
  String get apiValue {
    switch (this) {
      case ShiftStatus.planned:
        return 'PLANNED';
      case ShiftStatus.active:
        return 'ACTIVE';
      case ShiftStatus.completed:
        return 'COMPLETED';
      case ShiftStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case ShiftStatus.planned:
        return 'Planned';
      case ShiftStatus.active:
        return 'Active';
      case ShiftStatus.completed:
        return 'Completed';
      case ShiftStatus.cancelled:
        return 'Cancelled';
    }
  }

  static ShiftStatus fromApiValue(String value) {
    switch (value) {
      case 'ACTIVE':
        return ShiftStatus.active;
      case 'COMPLETED':
        return ShiftStatus.completed;
      case 'CANCELLED':
        return ShiftStatus.cancelled;
      case 'PLANNED':
      default:
        return ShiftStatus.planned;
    }
  }
}

enum TaskStatus { pending, completed, deferred, escalated, overdue }

extension TaskStatusX on TaskStatus {
  String get apiValue {
    switch (this) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.deferred:
        return 'DEFERRED';
      case TaskStatus.escalated:
        return 'ESCALATED';
      case TaskStatus.overdue:
        return 'OVERDUE';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.deferred:
        return 'Deferred';
      case TaskStatus.escalated:
        return 'Escalated';
      case TaskStatus.overdue:
        return 'Overdue';
    }
  }

  static TaskStatus fromApiValue(String value) {
    switch (value) {
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'DEFERRED':
        return TaskStatus.deferred;
      case 'ESCALATED':
        return TaskStatus.escalated;
      case 'OVERDUE':
        return TaskStatus.overdue;
      case 'PENDING':
      default:
        return TaskStatus.pending;
    }
  }
}

enum TaskFocus {
  general,
  hydration,
  observation,
  personalCare,
  mobility,
  medication,
}

extension TaskFocusX on TaskFocus {
  String get apiValue {
    switch (this) {
      case TaskFocus.general:
        return 'GENERAL';
      case TaskFocus.hydration:
        return 'HYDRATION';
      case TaskFocus.observation:
        return 'OBSERVATION';
      case TaskFocus.personalCare:
        return 'PERSONAL_CARE';
      case TaskFocus.mobility:
        return 'MOBILITY';
      case TaskFocus.medication:
        return 'MEDICATION';
    }
  }

  String get label {
    switch (this) {
      case TaskFocus.general:
        return 'General';
      case TaskFocus.hydration:
        return 'Hydration';
      case TaskFocus.observation:
        return 'Observation';
      case TaskFocus.personalCare:
        return 'Personal care';
      case TaskFocus.mobility:
        return 'Mobility';
      case TaskFocus.medication:
        return 'Medication';
    }
  }

  static TaskFocus fromApiValue(String value) {
    switch (value) {
      case 'HYDRATION':
        return TaskFocus.hydration;
      case 'OBSERVATION':
        return TaskFocus.observation;
      case 'PERSONAL_CARE':
        return TaskFocus.personalCare;
      case 'MOBILITY':
        return TaskFocus.mobility;
      case 'MEDICATION':
        return TaskFocus.medication;
      case 'GENERAL':
      default:
        return TaskFocus.general;
    }
  }
}

enum TaskClinicalPriority { routine, priority, timeCritical }

extension TaskClinicalPriorityX on TaskClinicalPriority {
  String get apiValue {
    switch (this) {
      case TaskClinicalPriority.routine:
        return 'ROUTINE';
      case TaskClinicalPriority.priority:
        return 'PRIORITY';
      case TaskClinicalPriority.timeCritical:
        return 'TIME_CRITICAL';
    }
  }

  String get label {
    switch (this) {
      case TaskClinicalPriority.routine:
        return 'Routine';
      case TaskClinicalPriority.priority:
        return 'Priority';
      case TaskClinicalPriority.timeCritical:
        return 'Time-critical';
    }
  }

  static TaskClinicalPriority fromApiValue(String value) {
    switch (value) {
      case 'PRIORITY':
        return TaskClinicalPriority.priority;
      case 'TIME_CRITICAL':
        return TaskClinicalPriority.timeCritical;
      case 'ROUTINE':
      default:
        return TaskClinicalPriority.routine;
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

abstract class UserProfile<RoleT> {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final String id;
  final String email;
  final String displayName;
  final RoleT role;
}

abstract class ResidentIdentity {
  const ResidentIdentity({
    required this.id,
    required this.fullName,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.recognitionImageKey,
    required this.baselinePriority,
    required this.effectivePriority,
    required this.prioritySource,
    required this.activeIncidentCount,
    this.aboutMe = '',
  });

  final String id;
  final String fullName;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String recognitionImageKey;
  final String aboutMe;
  final ResidentPriorityLevel baselinePriority;
  final ResidentPriorityLevel effectivePriority;
  final ResidentPrioritySource prioritySource;
  final int activeIncidentCount;

  String get photoAssetPath => residentPhotoAssetPath(recognitionImageKey);
}

abstract class ResidentProfile extends ResidentIdentity {
  const ResidentProfile({
    required super.id,
    required super.fullName,
    required super.roomLabel,
    required super.floorNumber,
    required super.unitLabel,
    required super.recognitionImageKey,
    required super.aboutMe,
    required super.baselinePriority,
    required super.effectivePriority,
    required super.prioritySource,
    required super.activeIncidentCount,
    required this.todaySummary,
    required this.assignmentContext,
    required this.contextLine,
    required this.alerts,
  });

  final String todaySummary;
  final String assignmentContext;
  final String contextLine;
  final List<String> alerts;
}

abstract class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.title,
    required this.status,
    this.focus = TaskFocus.general,
    this.clinicalPriority = TaskClinicalPriority.routine,
    this.description,
    this.dueAt,
    this.residentId,
    this.residentName,
    this.room,
    bool? canComplete,
    bool? canDefer,
    bool? canEscalate,
    this.actionRestrictionReason,
  }) : canComplete =
           canComplete ??
           (status == TaskStatus.pending || status == TaskStatus.overdue),
       canDefer =
           canDefer ??
           (status == TaskStatus.pending || status == TaskStatus.overdue),
       canEscalate =
           canEscalate ??
           (status == TaskStatus.pending || status == TaskStatus.overdue);

  final String id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final TaskStatus status;
  final TaskFocus focus;
  final TaskClinicalPriority clinicalPriority;
  final String? residentId;
  final String? residentName;
  final String? room;
  final bool canComplete;
  final bool canDefer;
  final bool canEscalate;
  final String? actionRestrictionReason;
}

abstract class ShiftPeriod {
  const ShiftPeriod({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.floorNumber,
    required this.unitLabel,
  });

  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final ShiftStatus status;
  final int floorNumber;
  final String unitLabel;
}
