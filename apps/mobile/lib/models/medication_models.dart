import 'shared_models.dart';

enum MedicationDoseStatus {
  due,
  administered,
  refused,
  omitted,
  delayed,
  notAvailable,
  held,
  cancelled,
  overdue,
}

MedicationDoseStatus _parseMedicationDoseStatus(String? value) {
  switch (value) {
    case 'ADMINISTERED':
      return MedicationDoseStatus.administered;
    case 'REFUSED':
      return MedicationDoseStatus.refused;
    case 'OMITTED':
      return MedicationDoseStatus.omitted;
    case 'DELAYED':
      return MedicationDoseStatus.delayed;
    case 'NOT_AVAILABLE':
      return MedicationDoseStatus.notAvailable;
    case 'HELD':
      return MedicationDoseStatus.held;
    case 'CANCELLED':
      return MedicationDoseStatus.cancelled;
    case 'OVERDUE':
      return MedicationDoseStatus.overdue;
    case 'DUE':
    default:
      return MedicationDoseStatus.due;
  }
}

extension MedicationDoseStatusX on MedicationDoseStatus {
  String get apiValue {
    switch (this) {
      case MedicationDoseStatus.due:
        return 'DUE';
      case MedicationDoseStatus.administered:
        return 'ADMINISTERED';
      case MedicationDoseStatus.refused:
        return 'REFUSED';
      case MedicationDoseStatus.omitted:
        return 'OMITTED';
      case MedicationDoseStatus.delayed:
        return 'DELAYED';
      case MedicationDoseStatus.notAvailable:
        return 'NOT_AVAILABLE';
      case MedicationDoseStatus.held:
        return 'HELD';
      case MedicationDoseStatus.cancelled:
        return 'CANCELLED';
      case MedicationDoseStatus.overdue:
        return 'OVERDUE';
    }
  }

  String get label {
    switch (this) {
      case MedicationDoseStatus.due:
        return 'Due';
      case MedicationDoseStatus.administered:
        return 'Administered';
      case MedicationDoseStatus.refused:
        return 'Refused';
      case MedicationDoseStatus.omitted:
        return 'Omitted';
      case MedicationDoseStatus.delayed:
        return 'Delayed';
      case MedicationDoseStatus.notAvailable:
        return 'Not available';
      case MedicationDoseStatus.held:
        return 'Held';
      case MedicationDoseStatus.cancelled:
        return 'Cancelled';
      case MedicationDoseStatus.overdue:
        return 'Overdue';
    }
  }
}

enum MedicationAdministrationEventType {
  administered,
  refused,
  omitted,
  delayed,
  notAvailable,
  held,
  prnOffered,
  prnAdministered,
  prnRefused,
  prnNotGiven,
}

MedicationAdministrationEventType _parseMedicationAdministrationEventType(
  String? value,
) {
  switch (value) {
    case 'REFUSED':
      return MedicationAdministrationEventType.refused;
    case 'OMITTED':
      return MedicationAdministrationEventType.omitted;
    case 'DELAYED':
      return MedicationAdministrationEventType.delayed;
    case 'NOT_AVAILABLE':
      return MedicationAdministrationEventType.notAvailable;
    case 'HELD':
      return MedicationAdministrationEventType.held;
    case 'PRN_OFFERED':
      return MedicationAdministrationEventType.prnOffered;
    case 'PRN_ADMINISTERED':
      return MedicationAdministrationEventType.prnAdministered;
    case 'PRN_REFUSED':
      return MedicationAdministrationEventType.prnRefused;
    case 'PRN_NOT_GIVEN':
      return MedicationAdministrationEventType.prnNotGiven;
    case 'ADMINISTERED':
    default:
      return MedicationAdministrationEventType.administered;
  }
}

extension MedicationAdministrationEventTypeX
    on MedicationAdministrationEventType {
  String get apiValue {
    switch (this) {
      case MedicationAdministrationEventType.administered:
        return 'ADMINISTERED';
      case MedicationAdministrationEventType.refused:
        return 'REFUSED';
      case MedicationAdministrationEventType.omitted:
        return 'OMITTED';
      case MedicationAdministrationEventType.delayed:
        return 'DELAYED';
      case MedicationAdministrationEventType.notAvailable:
        return 'NOT_AVAILABLE';
      case MedicationAdministrationEventType.held:
        return 'HELD';
      case MedicationAdministrationEventType.prnOffered:
        return 'PRN_OFFERED';
      case MedicationAdministrationEventType.prnAdministered:
        return 'PRN_ADMINISTERED';
      case MedicationAdministrationEventType.prnRefused:
        return 'PRN_REFUSED';
      case MedicationAdministrationEventType.prnNotGiven:
        return 'PRN_NOT_GIVEN';
    }
  }

  String get label {
    switch (this) {
      case MedicationAdministrationEventType.administered:
        return 'Administered';
      case MedicationAdministrationEventType.refused:
        return 'Refused';
      case MedicationAdministrationEventType.omitted:
        return 'Omitted';
      case MedicationAdministrationEventType.delayed:
        return 'Delayed';
      case MedicationAdministrationEventType.notAvailable:
        return 'Not available';
      case MedicationAdministrationEventType.held:
        return 'Held';
      case MedicationAdministrationEventType.prnOffered:
        return 'PRN offered';
      case MedicationAdministrationEventType.prnAdministered:
        return 'PRN administered';
      case MedicationAdministrationEventType.prnRefused:
        return 'PRN refused';
      case MedicationAdministrationEventType.prnNotGiven:
        return 'PRN not given';
    }
  }
}

class MedicationResidentSummary {
  const MedicationResidentSummary({
    required this.id,
    required this.fullName,
    required this.roomLabel,
    this.floorNumber,
    this.unitLabel,
  });

  factory MedicationResidentSummary.fromJson(Map<String, dynamic> json) {
    return MedicationResidentSummary(
      id: json['id'] as String,
      fullName: (json['fullName'] ?? json['residentName']) as String,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int?,
      unitLabel: json['unitLabel'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String roomLabel;
  final int? floorNumber;
  final String? unitLabel;
}

class MedicationChartSummary {
  const MedicationChartSummary({
    required this.id,
    required this.status,
    required this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserName,
    this.reviewedByUserId,
    this.reviewedByUserName,
    this.archivedAt,
  });

  factory MedicationChartSummary.fromJson(Map<String, dynamic> json) {
    return MedicationChartSummary(
      id: json['id'] as String,
      status: json['status'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByUserName: json['createdByUserName'] as String?,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedByUserName: json['reviewedByUserName'] as String?,
      archivedAt: json['archivedAt'] == null
          ? null
          : parseApiDateTime(json['archivedAt'] as String),
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String status;
  final String createdByUserId;
  final String? createdByUserName;
  final String? reviewedByUserId;
  final String? reviewedByUserName;
  final DateTime? archivedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MedicationAllergyRecord {
  const MedicationAllergyRecord({
    required this.id,
    required this.substance,
    required this.recordedByUserId,
    required this.createdAt,
    required this.updatedAt,
    this.reaction,
    this.severity,
    this.recordedByUserName,
  });

  factory MedicationAllergyRecord.fromJson(Map<String, dynamic> json) {
    return MedicationAllergyRecord(
      id: json['id'] as String,
      substance: json['substance'] as String,
      reaction: json['reaction'] as String?,
      severity: json['severity'] as String?,
      recordedByUserId: json['recordedByUserId'] as String,
      recordedByUserName: json['recordedByUserName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
    );
  }

  final String id;
  final String substance;
  final String? reaction;
  final String? severity;
  final String recordedByUserId;
  final String? recordedByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class MedicationScheduleRecord {
  const MedicationScheduleRecord({
    required this.id,
    required this.roundLabel,
    required this.anchorType,
    required this.daysOfWeek,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.windowStartOffsetMinutes,
    this.windowEndOffsetMinutes,
    this.fixedTimeLocal,
  });

  factory MedicationScheduleRecord.fromJson(Map<String, dynamic> json) {
    return MedicationScheduleRecord(
      id: json['id'] as String,
      roundLabel: json['roundLabel'] as String,
      anchorType: json['anchorType'] as String,
      windowStartOffsetMinutes: json['windowStartOffsetMinutes'] as int?,
      windowEndOffsetMinutes: json['windowEndOffsetMinutes'] as int?,
      fixedTimeLocal: json['fixedTimeLocal'] as String?,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? const [])
          .map((entry) => entry as String)
          .toList(growable: false),
      active: json['active'] as bool? ?? false,
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
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

class PrnProtocolRecord {
  const PrnProtocolRecord({
    required this.id,
    required this.indication,
    required this.whenToOffer,
    required this.doseInstructions,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    this.minimumIntervalMinutes,
    this.maxDosePer24Hours,
    this.expectedEffect,
    this.monitoringRequired,
    this.whenToEscalate,
  });

  factory PrnProtocolRecord.fromJson(Map<String, dynamic> json) {
    return PrnProtocolRecord(
      id: json['id'] as String,
      indication: json['indication'] as String,
      whenToOffer: json['whenToOffer'] as String,
      doseInstructions: json['doseInstructions'] as String,
      minimumIntervalMinutes: json['minimumIntervalMinutes'] as int?,
      maxDosePer24Hours: json['maxDosePer24Hours'] as int?,
      expectedEffect: json['expectedEffect'] as String?,
      monitoringRequired: json['monitoringRequired'] as String?,
      whenToEscalate: json['whenToEscalate'] as String?,
      active: json['active'] as bool? ?? false,
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
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

class MedicationStockSummary {
  const MedicationStockSummary({
    required this.id,
    required this.currentQuantity,
    required this.quantityUnit,
    required this.updatedAt,
    this.lastCheckedByUserId,
    this.lastCheckedByUserName,
    this.lastCheckedAt,
    this.notes,
  });

  factory MedicationStockSummary.fromJson(Map<String, dynamic> json) {
    return MedicationStockSummary(
      id: json['id'] as String,
      currentQuantity: json['currentQuantity'] as String,
      quantityUnit: json['quantityUnit'] as String,
      lastCheckedByUserId: json['lastCheckedByUserId'] as String?,
      lastCheckedByUserName: json['lastCheckedByUserName'] as String?,
      lastCheckedAt: json['lastCheckedAt'] == null
          ? null
          : parseApiDateTime(json['lastCheckedAt'] as String),
      notes: json['notes'] as String?,
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
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

class MedicationOrderRecord {
  const MedicationOrderRecord({
    required this.id,
    required this.medicationName,
    required this.doseAmount,
    required this.doseUnit,
    required this.route,
    required this.instructions,
    required this.startDate,
    required this.isActive,
    required this.isControlledDrug,
    required this.requiresWitness,
    required this.isPRN,
    required this.sourceType,
    required this.createdByUserId,
    required this.updatedByUserId,
    required this.createdAt,
    required this.updatedAt,
    required this.schedules,
    this.formulation,
    this.strength,
    this.endDate,
    this.createdByUserName,
    this.updatedByUserName,
    this.deactivatedAt,
    this.deactivationReason,
    this.prnProtocol,
    this.stock,
  });

  factory MedicationOrderRecord.fromJson(Map<String, dynamic> json) {
    return MedicationOrderRecord(
      id: json['id'] as String,
      medicationName: json['medicationName'] as String,
      formulation: json['formulation'] as String?,
      strength: json['strength'] as String?,
      doseAmount: json['doseAmount'] as String,
      doseUnit: json['doseUnit'] as String,
      route: json['route'] as String,
      instructions: json['instructions'] as String,
      startDate: parseApiDateTime(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : parseApiDateTime(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? false,
      isControlledDrug: json['isControlledDrug'] as bool? ?? false,
      requiresWitness: json['requiresWitness'] as bool? ?? false,
      isPRN: json['isPRN'] as bool? ?? false,
      sourceType: json['sourceType'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByUserName: json['createdByUserName'] as String?,
      updatedByUserId: json['updatedByUserId'] as String,
      updatedByUserName: json['updatedByUserName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String),
      updatedAt: parseApiDateTime(json['updatedAt'] as String),
      deactivatedAt: json['deactivatedAt'] == null
          ? null
          : parseApiDateTime(json['deactivatedAt'] as String),
      deactivationReason: json['deactivationReason'] as String?,
      schedules: (json['schedules'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MedicationScheduleRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      prnProtocol: json['prnProtocol'] == null
          ? null
          : PrnProtocolRecord.fromJson(
              json['prnProtocol'] as Map<String, dynamic>,
            ),
      stock: json['stock'] == null
          ? null
          : MedicationStockSummary.fromJson(
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
  final bool isPRN;
  final String sourceType;
  final String createdByUserId;
  final String? createdByUserName;
  final String updatedByUserId;
  final String? updatedByUserName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deactivatedAt;
  final String? deactivationReason;
  final List<MedicationScheduleRecord> schedules;
  final PrnProtocolRecord? prnProtocol;
  final MedicationStockSummary? stock;

  String get titleLine => [
    medicationName,
    if (strength != null && strength!.trim().isNotEmpty) strength,
  ].join(' ').trim();
}

class MedicationAdministrationRecord {
  const MedicationAdministrationRecord({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.roomLabel,
    required this.shiftId,
    required this.medicationOrderId,
    required this.medicationName,
    required this.eventType,
    required this.recordedByUserId,
    required this.recordedAt,
    required this.createdAt,
    this.doseInstanceId,
    this.strength,
    this.formulation,
    this.doseGiven,
    this.doseUnit,
    this.reason,
    this.notes,
    this.recordedByUserName,
    this.witnessUserId,
    this.witnessUserName,
  });

  factory MedicationAdministrationRecord.fromJson(Map<String, dynamic> json) {
    return MedicationAdministrationRecord(
      id: json['id'] as String,
      doseInstanceId: json['doseInstanceId'] as String?,
      residentId: json['residentId'] as String,
      residentName: json['residentName'] as String,
      roomLabel: json['roomLabel'] as String,
      shiftId: json['shiftId'] as String,
      medicationOrderId: json['medicationOrderId'] as String,
      medicationName: json['medicationName'] as String,
      strength: json['strength'] as String?,
      formulation: json['formulation'] as String?,
      eventType: _parseMedicationAdministrationEventType(
        json['eventType'] as String?,
      ),
      doseGiven: json['doseGiven'] as String?,
      doseUnit: json['doseUnit'] as String?,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      recordedByUserId: json['recordedByUserId'] as String,
      recordedByUserName: json['recordedByUserName'] as String?,
      recordedAt: parseApiDateTime(json['recordedAt'] as String),
      witnessUserId: json['witnessUserId'] as String?,
      witnessUserName: json['witnessUserName'] as String?,
      createdAt: parseApiDateTime(json['createdAt'] as String),
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
  final MedicationAdministrationEventType eventType;
  final String? doseGiven;
  final String? doseUnit;
  final String? reason;
  final String? notes;
  final String recordedByUserId;
  final String? recordedByUserName;
  final DateTime recordedAt;
  final String? witnessUserId;
  final String? witnessUserName;
  final DateTime createdAt;
}

class MedicationChangeLogRecord {
  const MedicationChangeLogRecord({
    required this.id,
    required this.medicationOrderId,
    required this.residentId,
    required this.medicationName,
    required this.changedByUserId,
    required this.changeType,
    required this.reason,
    required this.createdAt,
    this.changedByUserName,
    this.previousValueJson,
    this.newValueJson,
  });

  factory MedicationChangeLogRecord.fromJson(Map<String, dynamic> json) {
    return MedicationChangeLogRecord(
      id: json['id'] as String,
      medicationOrderId: json['medicationOrderId'] as String,
      residentId: json['residentId'] as String,
      medicationName: json['medicationName'] as String,
      changedByUserId: json['changedByUserId'] as String,
      changedByUserName: json['changedByUserName'] as String?,
      changeType: json['changeType'] as String,
      previousValueJson: json['previousValueJson'],
      newValueJson: json['newValueJson'],
      reason: json['reason'] as String,
      createdAt: parseApiDateTime(json['createdAt'] as String),
    );
  }

  final String id;
  final String medicationOrderId;
  final String residentId;
  final String medicationName;
  final String changedByUserId;
  final String? changedByUserName;
  final String changeType;
  final Object? previousValueJson;
  final Object? newValueJson;
  final String reason;
  final DateTime createdAt;
}

class ResidentEmarProfile {
  const ResidentEmarProfile({
    required this.workflowNote,
    required this.downtimeNotice,
    required this.safetyBanner,
    required this.resident,
    required this.allergies,
    required this.scheduledMedications,
    required this.prnMedications,
    required this.recentEvents,
    required this.stockOverview,
    required this.changeHistory,
    this.chart,
  });

  factory ResidentEmarProfile.fromJson(Map<String, dynamic> json) {
    return ResidentEmarProfile(
      workflowNote: json['workflowNote'] as String? ?? '',
      downtimeNotice: json['downtimeNotice'] as String? ?? '',
      safetyBanner: json['safetyBanner'] as String? ?? '',
      resident: MedicationResidentSummary.fromJson(
        json['resident'] as Map<String, dynamic>,
      ),
      chart: json['chart'] == null
          ? null
          : MedicationChartSummary.fromJson(
              json['chart'] as Map<String, dynamic>,
            ),
      allergies: (json['allergies'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                MedicationAllergyRecord.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
      scheduledMedications:
          (json['scheduledMedications'] as List<dynamic>? ?? const [])
              .map(
                (entry) => MedicationOrderRecord.fromJson(
                  entry as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
      prnMedications: (json['prnMedications'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                MedicationOrderRecord.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
      recentEvents: (json['recentEvents'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MedicationAdministrationRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
      stockOverview: (json['stockOverview'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                MedicationStockSummary.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
      changeHistory: (json['changeHistory'] as List<dynamic>? ?? const [])
          .map(
            (entry) => MedicationChangeLogRecord.fromJson(
              entry as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }

  final String workflowNote;
  final String downtimeNotice;
  final String safetyBanner;
  final MedicationResidentSummary resident;
  final MedicationChartSummary? chart;
  final List<MedicationAllergyRecord> allergies;
  final List<MedicationOrderRecord> scheduledMedications;
  final List<MedicationOrderRecord> prnMedications;
  final List<MedicationAdministrationRecord> recentEvents;
  final List<MedicationStockSummary> stockOverview;
  final List<MedicationChangeLogRecord> changeHistory;
}

class MedicationRoundShift {
  const MedicationRoundShift({
    required this.id,
    required this.name,
    required this.floorNumber,
    required this.unitLabel,
    required this.startsAt,
    required this.endsAt,
    required this.handoverAcknowledged,
    this.handoverAcknowledgedAt,
  });

  factory MedicationRoundShift.fromJson(Map<String, dynamic> json) {
    return MedicationRoundShift(
      id: json['id'] as String,
      name: json['name'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      startsAt: parseApiDateTime(json['startsAt'] as String),
      endsAt: parseApiDateTime(json['endsAt'] as String),
      handoverAcknowledged: json['handoverAcknowledged'] as bool? ?? false,
      handoverAcknowledgedAt: json['handoverAcknowledgedAt'] == null
          ? null
          : parseApiDateTime(json['handoverAcknowledgedAt'] as String),
    );
  }

  final String id;
  final String name;
  final int floorNumber;
  final String unitLabel;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool handoverAcknowledged;
  final DateTime? handoverAcknowledgedAt;
}

class MedicationRoundWitnessCandidate {
  const MedicationRoundWitnessCandidate({
    required this.id,
    required this.displayName,
    required this.role,
  });

  factory MedicationRoundWitnessCandidate.fromJson(Map<String, dynamic> json) {
    return MedicationRoundWitnessCandidate(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String displayName;
  final String role;
}

class MedicationRoundItem {
  const MedicationRoundItem({
    required this.id,
    required this.residentId,
    required this.residentName,
    required this.roomLabel,
    required this.floorNumber,
    required this.unitLabel,
    required this.medicationOrderId,
    required this.medicationName,
    required this.doseAmount,
    required this.doseUnit,
    required this.route,
    required this.instructions,
    required this.roundLabel,
    required this.anchorType,
    required this.dueWindowStart,
    required this.dueWindowEnd,
    required this.status,
    required this.generatedAt,
    required this.requiresWitness,
    required this.allergies,
    this.formulation,
    this.strength,
    this.recordedByUserId,
    this.recordedByUserName,
    this.recordedAt,
    this.reason,
    this.notes,
    this.witnessUserId,
    this.witnessUserName,
  });

  factory MedicationRoundItem.fromJson(Map<String, dynamic> json) {
    return MedicationRoundItem(
      id: json['id'] as String,
      residentId: json['residentId'] as String,
      residentName: json['residentName'] as String,
      roomLabel: json['roomLabel'] as String,
      floorNumber: json['floorNumber'] as int,
      unitLabel: json['unitLabel'] as String,
      medicationOrderId: json['medicationOrderId'] as String,
      medicationName: json['medicationName'] as String,
      formulation: json['formulation'] as String?,
      strength: json['strength'] as String?,
      doseAmount: json['doseAmount'] as String,
      doseUnit: json['doseUnit'] as String,
      route: json['route'] as String,
      instructions: json['instructions'] as String,
      roundLabel: json['roundLabel'] as String,
      anchorType: json['anchorType'] as String,
      dueWindowStart: parseApiDateTime(json['dueWindowStart'] as String),
      dueWindowEnd: parseApiDateTime(json['dueWindowEnd'] as String),
      status: _parseMedicationDoseStatus(json['status'] as String?),
      generatedAt: parseApiDateTime(json['generatedAt'] as String),
      recordedByUserId: json['recordedByUserId'] as String?,
      recordedByUserName: json['recordedByUserName'] as String?,
      recordedAt: json['recordedAt'] == null
          ? null
          : parseApiDateTime(json['recordedAt'] as String),
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      requiresWitness: json['requiresWitness'] as bool? ?? false,
      witnessUserId: json['witnessUserId'] as String?,
      witnessUserName: json['witnessUserName'] as String?,
      allergies: (json['allergies'] as List<dynamic>? ?? const [])
          .map((entry) => entry as Map<String, dynamic>)
          .toList(growable: false),
    );
  }

  final String id;
  final String residentId;
  final String residentName;
  final String roomLabel;
  final int floorNumber;
  final String unitLabel;
  final String medicationOrderId;
  final String medicationName;
  final String? formulation;
  final String? strength;
  final String doseAmount;
  final String doseUnit;
  final String route;
  final String instructions;
  final String roundLabel;
  final String anchorType;
  final DateTime dueWindowStart;
  final DateTime dueWindowEnd;
  final MedicationDoseStatus status;
  final DateTime generatedAt;
  final String? recordedByUserId;
  final String? recordedByUserName;
  final DateTime? recordedAt;
  final String? reason;
  final String? notes;
  final bool requiresWitness;
  final String? witnessUserId;
  final String? witnessUserName;
  final List<Map<String, dynamic>> allergies;

  String get titleLine => [
    medicationName,
    if (strength != null && strength!.trim().isNotEmpty) strength,
  ].join(' ').trim();
}

class MedicationRoundGroup {
  const MedicationRoundGroup({required this.roundLabel, required this.items});

  factory MedicationRoundGroup.fromJson(Map<String, dynamic> json) {
    return MedicationRoundGroup(
      roundLabel: json['roundLabel'] as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                MedicationRoundItem.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String roundLabel;
  final List<MedicationRoundItem> items;
}

class MedicationRoundSnapshot {
  const MedicationRoundSnapshot({
    required this.workflowNote,
    required this.safetyBanner,
    required this.shift,
    required this.witnessCandidates,
    required this.groupedRounds,
  });

  factory MedicationRoundSnapshot.fromJson(Map<String, dynamic> json) {
    return MedicationRoundSnapshot(
      workflowNote: json['workflowNote'] as String? ?? '',
      safetyBanner: json['safetyBanner'] as String? ?? '',
      shift: MedicationRoundShift.fromJson(
        json['shift'] as Map<String, dynamic>,
      ),
      witnessCandidates:
          (json['witnessCandidates'] as List<dynamic>? ?? const [])
              .map(
                (entry) => MedicationRoundWitnessCandidate.fromJson(
                  entry as Map<String, dynamic>,
                ),
              )
              .toList(growable: false),
      groupedRounds: (json['groupedRounds'] as List<dynamic>? ?? const [])
          .map(
            (entry) =>
                MedicationRoundGroup.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  final String workflowNote;
  final String safetyBanner;
  final MedicationRoundShift shift;
  final List<MedicationRoundWitnessCandidate> witnessCandidates;
  final List<MedicationRoundGroup> groupedRounds;
}

class MedicationDoseActionResult {
  const MedicationDoseActionResult({
    required this.workflowNote,
    required this.safetyBanner,
    required this.doseInstance,
    required this.administrationEvent,
  });

  factory MedicationDoseActionResult.fromJson(Map<String, dynamic> json) {
    return MedicationDoseActionResult(
      workflowNote: json['workflowNote'] as String? ?? '',
      safetyBanner: json['safetyBanner'] as String? ?? '',
      doseInstance: MedicationRoundItem.fromJson(
        json['doseInstance'] as Map<String, dynamic>,
      ),
      administrationEvent: MedicationAdministrationRecord.fromJson(
        json['administrationEvent'] as Map<String, dynamic>,
      ),
    );
  }

  final String workflowNote;
  final String safetyBanner;
  final MedicationRoundItem doseInstance;
  final MedicationAdministrationRecord administrationEvent;
}

class PrnEventResult {
  const PrnEventResult({
    required this.workflowNote,
    required this.administrationEvent,
    this.warning,
  });

  factory PrnEventResult.fromJson(Map<String, dynamic> json) {
    return PrnEventResult(
      workflowNote: json['workflowNote'] as String? ?? '',
      warning: json['warning'] as String?,
      administrationEvent: MedicationAdministrationRecord.fromJson(
        json['administrationEvent'] as Map<String, dynamic>,
      ),
    );
  }

  final String workflowNote;
  final String? warning;
  final MedicationAdministrationRecord administrationEvent;
}
