DateTime parseApiDateTime(String value) => DateTime.parse(value).toLocal();

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

enum AppUserRole { carer, seniorCarer, manager }

extension AppUserRoleX on AppUserRole {
  String get apiValue {
    switch (this) {
      case AppUserRole.carer:
        return 'CARER';
      case AppUserRole.seniorCarer:
        return 'SENIOR_CARER';
      case AppUserRole.manager:
        return 'MANAGER';
    }
  }

  String get label {
    switch (this) {
      case AppUserRole.carer:
        return 'Carer';
      case AppUserRole.seniorCarer:
        return 'Senior carer';
      case AppUserRole.manager:
        return 'Manager';
    }
  }

  static AppUserRole fromApiValue(String value) {
    switch (value) {
      case 'SENIOR_CARER':
        return AppUserRole.seniorCarer;
      case 'MANAGER':
        return AppUserRole.manager;
      case 'CARER':
      default:
        return AppUserRole.carer;
    }
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

abstract class ResidentProfile {
  const ResidentProfile({
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
    required this.baselinePriority,
    required this.effectivePriority,
    required this.prioritySource,
    required this.activeIncidentCount,
  });

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
  final ResidentPriorityLevel baselinePriority;
  final ResidentPriorityLevel effectivePriority;
  final ResidentPrioritySource prioritySource;
  final int activeIncidentCount;

  String get photoAssetPath => residentPhotoAssetPath(recognitionImageKey);
}

abstract class TaskRecord {
  const TaskRecord({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.dueAt,
    this.residentId,
    this.residentName,
    this.room,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueAt;
  final TaskStatus status;
  final String? residentId;
  final String? residentName;
  final String? room;
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
