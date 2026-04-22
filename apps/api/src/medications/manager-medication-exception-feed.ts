type MedicationExceptionFeedStatus =
  | 'OVERDUE'
  | 'REFUSED'
  | 'OMITTED'
  | 'DELAYED'
  | 'NOT_AVAILABLE'
  | 'HELD';

type ManagerMedicationExceptionFeedStatus =
  | 'OVERDUE'
  | 'ESCALATED'
  | 'DEFERRED';
type ManagerMedicationExceptionFeedTone = 'critical' | 'warning' | 'info';

type ManagerMedicationExceptionFeedInput = {
  id: string;
  shiftId: string;
  residentName: string;
  roomLabel: string;
  floorNumber: number | null;
  unitLabel: string | null;
  medicationName: string;
  dueWindowEnd: Date;
  status: MedicationExceptionFeedStatus;
  recordedByUserName: string | null;
  recordedAt: Date | null;
  reason: string | null;
  notes: string | null;
  roundLabel: string | null;
};

function resolveMedicationFeedStatus(
  status: MedicationExceptionFeedStatus,
): ManagerMedicationExceptionFeedStatus {
  switch (status) {
    case 'OVERDUE':
      return 'OVERDUE';
    case 'DELAYED':
      return 'DEFERRED';
    case 'REFUSED':
    case 'OMITTED':
    case 'NOT_AVAILABLE':
    case 'HELD':
    default:
      return 'ESCALATED';
  }
}

function resolveMedicationFeedTone(
  status: MedicationExceptionFeedStatus,
): ManagerMedicationExceptionFeedTone {
  switch (status) {
    case 'OVERDUE':
    case 'OMITTED':
    case 'NOT_AVAILABLE':
      return 'critical';
    case 'DELAYED':
      return 'info';
    case 'REFUSED':
    case 'HELD':
    default:
      return 'warning';
  }
}

function resolveMedicationFeedRank(status: MedicationExceptionFeedStatus) {
  switch (status) {
    case 'OVERDUE':
      return 3.1;
    case 'NOT_AVAILABLE':
      return 3.2;
    case 'OMITTED':
      return 3.25;
    case 'REFUSED':
      return 3.3;
    case 'HELD':
      return 3.35;
    case 'DELAYED':
    default:
      return 3.4;
  }
}

function buildMedicationExceptionTitle(
  medicationName: string,
  status: MedicationExceptionFeedStatus,
) {
  switch (status) {
    case 'OVERDUE':
      return `${medicationName} overdue`;
    case 'REFUSED':
      return `${medicationName} refused`;
    case 'OMITTED':
      return `${medicationName} omitted`;
    case 'DELAYED':
      return `${medicationName} delayed`;
    case 'NOT_AVAILABLE':
      return `${medicationName} unavailable`;
    case 'HELD':
    default:
      return `${medicationName} held`;
  }
}

function buildMedicationExceptionBadge(status: MedicationExceptionFeedStatus) {
  switch (status) {
    case 'OVERDUE':
      return 'MED OVERDUE';
    case 'REFUSED':
      return 'MED REFUSED';
    case 'OMITTED':
      return 'MED OMITTED';
    case 'DELAYED':
      return 'MED DELAYED';
    case 'NOT_AVAILABLE':
      return 'MED UNAVAILABLE';
    case 'HELD':
    default:
      return 'MED HELD';
  }
}

function buildMedicationExceptionDescription(
  exception: ManagerMedicationExceptionFeedInput,
) {
  const segments = [
    exception.roundLabel?.trim()
      ? `${exception.roundLabel.trim()} round needs follow-up.`
      : 'Medication exception needs manager visibility.',
    exception.reason?.trim() ? `Reason: ${exception.reason.trim()}.` : null,
    exception.notes?.trim() ? `Notes: ${exception.notes.trim()}.` : null,
    exception.recordedByUserName?.trim()
      ? `Recorded by ${exception.recordedByUserName.trim()}.`
      : null,
  ].filter((value): value is string => value != null && value.length > 0);

  return segments.join(' ');
}

export function mapMedicationExceptionFeedItem(
  exception: ManagerMedicationExceptionFeedInput,
) {
  return {
    kind: 'TASK' as const,
    id: `medication-${exception.id}`,
    shiftId: exception.shiftId,
    title: buildMedicationExceptionTitle(
      exception.medicationName,
      exception.status,
    ),
    residentName: exception.residentName,
    roomLabel: exception.roomLabel,
    floorNumber: exception.floorNumber ?? 0,
    unitLabel: exception.unitLabel ?? 'Unknown unit',
    description: buildMedicationExceptionDescription(exception),
    status: resolveMedicationFeedStatus(exception.status),
    severity: null,
    badge: buildMedicationExceptionBadge(exception.status),
    badgeTone: resolveMedicationFeedTone(exception.status),
    canAcknowledge: false,
    canResolve: false,
    occurredAt: exception.recordedAt,
    dueAt: exception.dueWindowEnd,
    rank: resolveMedicationFeedRank(exception.status),
  };
}
