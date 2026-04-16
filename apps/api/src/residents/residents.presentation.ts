import type {
  IncidentMedia,
  IncidentSeverity,
  IncidentStatus,
  PersonalCareSubtype,
  ResidentPriorityLevel,
  ResidentTimelineEntryType,
  ResidentTimelineMedia,
  TaskStatus,
} from '@prisma/client';
import { buildResidentPriorityState } from './resident-priority';
import { incidentCategoryLabels } from './residents.constants';

type ResidentTaskSummaryInput = {
  id: string;
  title: string;
  description: string | null;
  status: TaskStatus;
  dueAt: Date | null;
};

type ResidentTaskAlertInput = Pick<
  ResidentTaskSummaryInput,
  'title' | 'status' | 'dueAt'
>;

type ResidentPriorityIncidentInput = {
  severity: IncidentSeverity;
  status: IncidentStatus;
};

type ResidentListItemInput = {
  id: string;
  fullName: string;
  roomLabel: string;
  floorNumber: number;
  unitLabel: string;
  recognitionImageKey: string;
  careSummary: string;
  baselinePriority: ResidentPriorityLevel;
  tasks: ResidentTaskAlertInput[];
  incidents: ResidentPriorityIncidentInput[];
};

type ManagerResidentInput = {
  id: string;
  fullName: string;
  roomNumber: number;
  roomLabel: string;
  floorNumber: number;
  unitLabel: string;
  recognitionImageKey: string;
  careSummary: string;
  isActive: boolean;
  baselinePriority: ResidentPriorityLevel;
  incidents: ResidentPriorityIncidentInput[];
  createdAt: Date;
  updatedAt: Date;
};

type TimelineEntryInput = {
  id: string;
  type: ResidentTimelineEntryType;
  personalCareSubtype: PersonalCareSubtype | null;
  title: string;
  details: string;
  createdAt: Date;
  createdBy: {
    displayName: string;
  } | null;
  media: ResidentTimelineMedia[];
};

type IncidentInput = {
  id: string;
  severity: IncidentSeverity;
  status: IncidentStatus;
  category: keyof typeof incidentCategoryLabels;
  title: string;
  details: string;
  occurredAt: Date;
  acknowledgedAt: Date | null;
  resolvedAt: Date | null;
  createdAt: Date;
  createdBy: {
    displayName: string;
  } | null;
  acknowledgedBy: {
    displayName: string;
  } | null;
  resolvedBy: {
    displayName: string;
  } | null;
  media: IncidentMedia[];
};

type IncidentExceptionFeedInput = {
  id: string;
  title: string;
  details: string;
  status: IncidentStatus;
  severity: IncidentSeverity;
  occurredAt: Date;
  resident: {
    fullName: string;
    roomLabel: string;
  };
};

type TaskExceptionFeedInput = {
  id: string;
  title: string;
  description: string | null;
  resident: {
    fullName: string;
    roomLabel: string;
  } | null;
  dashboardStatus: TaskStatus;
  dueAt: Date | null;
};

type TimelineActivityFeedInput = {
  id: string;
  type: ResidentTimelineEntryType;
  title: string;
  details: string;
  createdAt: Date;
  createdBy: {
    displayName: string;
  } | null;
  resident: {
    fullName: string;
    roomLabel: string;
  };
};

type TaskActivityFeedInput = {
  id: string;
  title: string;
  statusNote: string | null;
  resident: {
    fullName: string;
    roomLabel: string;
  } | null;
  updatedAt: Date;
  updatedBy: {
    displayName: string;
  } | null;
};

type IncidentActivityFeedInput = {
  id: string;
  title: string;
  details: string;
  severity: IncidentSeverity;
  occurredAt: Date;
  actorName: string | null;
  resident: {
    fullName: string;
    roomLabel: string;
  };
};

function clampNumber(value: number, minimum: number, maximum: number) {
  return Math.min(Math.max(value, minimum), maximum);
}

function mapTaskStatusToAlert(status: TaskStatus) {
  switch (status) {
    case 'OVERDUE':
      return 'Overdue follow-up';
    case 'ESCALATED':
      return 'Escalated item';
    case 'DEFERRED':
      return 'Deferred review';
    case 'COMPLETED':
      return 'Completed today';
    case 'PENDING':
    default:
      return 'Due this shift';
  }
}

function formatDueState(dueAt: Date | null, referenceTime = Date.now()) {
  if (!dueAt) {
    return 'No timed action due right now';
  }

  const diffMinutes = Math.round((dueAt.getTime() - referenceTime) / 60000);
  if (diffMinutes < 0) {
    return `Overdue by ${Math.abs(diffMinutes)} min`;
  }
  if (diffMinutes === 0) {
    return 'Due now';
  }
  if (diffMinutes < 60) {
    return `Due in ${diffMinutes} min`;
  }

  return `Due in ${Math.floor(diffMinutes / 60)} hr`;
}

function getIncidentFeedRank(incident: {
  status: IncidentStatus;
  severity: IncidentSeverity;
}) {
  if (incident.status === 'OPEN' && incident.severity === 'RED') {
    return 0;
  }
  if (incident.status === 'OPEN' && incident.severity === 'AMBER') {
    return 1;
  }
  if (incident.status === 'ACKNOWLEDGED' && incident.severity === 'RED') {
    return 2;
  }

  return 3;
}

export function buildContextLine(
  tasks: ResidentTaskAlertInput[],
  careSummary: string,
  referenceTime = Date.now(),
) {
  const openTask = tasks.find(
    (task) => task.status !== 'COMPLETED' && task.status !== 'DEFERRED',
  );

  if (!openTask) {
    return careSummary;
  }

  return `${openTask.title} · ${formatDueState(openTask.dueAt, referenceTime)}`;
}

export function buildAlerts(tasks: ResidentTaskAlertInput[]) {
  const alerts = tasks
    .slice(0, 2)
    .map((task) => mapTaskStatusToAlert(task.status));
  return [...new Set(alerts)];
}

function mapTimelineMedia(media: ResidentTimelineMedia) {
  return {
    id: media.id,
    originalFileName: media.originalFileName,
    mediaType: media.mediaType,
    byteSize: media.byteSize,
    downloadPath: `/resident-media/${media.id}`,
    createdAt: media.createdAt,
  };
}

function mapIncidentMedia(media: IncidentMedia) {
  return {
    id: media.id,
    originalFileName: media.originalFileName,
    mediaType: media.mediaType,
    byteSize: media.byteSize,
    createdAt: media.createdAt,
  };
}

export function mapTimelineEntry(entry: TimelineEntryInput) {
  return {
    id: entry.id,
    type: entry.type,
    personalCareSubtype: entry.personalCareSubtype,
    title: entry.title,
    details: entry.details,
    authorName: entry.createdBy?.displayName ?? 'System note',
    timestamp: entry.createdAt,
    media: entry.media.map(mapTimelineMedia),
  };
}

export function mapIncident(incident: IncidentInput) {
  return {
    id: incident.id,
    severity: incident.severity,
    status: incident.status,
    category: incident.category,
    categoryLabel: incidentCategoryLabels[incident.category],
    title: incident.title,
    details: incident.details,
    occurredAt: incident.occurredAt,
    acknowledgedAt: incident.acknowledgedAt,
    acknowledgedByName: incident.acknowledgedBy?.displayName ?? null,
    resolvedAt: incident.resolvedAt,
    resolvedByName: incident.resolvedBy?.displayName ?? null,
    createdAt: incident.createdAt,
    createdByName: incident.createdBy?.displayName ?? 'Unknown user',
    evidence: incident.media.map(mapIncidentMedia),
  };
}

export function mapResidentTask(
  task: ResidentTaskSummaryInput,
  roomLabel: string,
  residentId: string,
  residentName: string,
) {
  return {
    id: task.id,
    title: task.title,
    description: task.description,
    status: task.status,
    dueAt: task.dueAt,
    residentId,
    residentName,
    room: roomLabel,
  };
}

export function mapResidentListItem(
  resident: ResidentListItemInput,
  shift: { unitLabel: string },
  referenceTime = Date.now(),
) {
  const priorityState = buildResidentPriorityState({
    baselinePriority: resident.baselinePriority,
    incidents: resident.incidents,
  });

  return {
    id: resident.id,
    fullName: resident.fullName,
    roomLabel: resident.roomLabel,
    floorNumber: resident.floorNumber,
    unitLabel: resident.unitLabel,
    recognitionImageKey: resident.recognitionImageKey,
    todaySummary: resident.careSummary,
    assignmentContext: `Assigned to ${shift.unitLabel} for this shift`,
    contextLine: buildContextLine(
      resident.tasks,
      resident.careSummary,
      referenceTime,
    ),
    alerts: buildAlerts(resident.tasks),
    ...priorityState,
  };
}

export function mapManagerResident(resident: ManagerResidentInput) {
  const priorityState = buildResidentPriorityState({
    baselinePriority: resident.baselinePriority,
    incidents: resident.incidents,
  });

  return {
    id: resident.id,
    fullName: resident.fullName,
    roomNumber: resident.roomNumber,
    roomLabel: resident.roomLabel,
    floorNumber: resident.floorNumber,
    unitLabel: resident.unitLabel,
    recognitionImageKey: resident.recognitionImageKey,
    careSummary: resident.careSummary,
    isActive: resident.isActive,
    ...priorityState,
    createdAt: resident.createdAt,
    updatedAt: resident.updatedAt,
  };
}

export function getDashboardTaskStatus(
  task: Pick<ResidentTaskSummaryInput, 'status' | 'dueAt'>,
  referenceTime = Date.now(),
) {
  if (
    task.status === 'PENDING' &&
    task.dueAt &&
    task.dueAt.getTime() < referenceTime
  ) {
    return 'OVERDUE' satisfies TaskStatus;
  }

  return task.status;
}

export function buildManagerComplianceSeries({
  shiftStartsAt,
  shiftEndsAt,
  overdueTasks,
  escalatedItems,
  unreadHandovers,
}: {
  shiftStartsAt: Date;
  shiftEndsAt: Date;
  overdueTasks: number;
  escalatedItems: number;
  unreadHandovers: number;
}) {
  const shiftDurationMs = Math.max(
    shiftEndsAt.getTime() - shiftStartsAt.getTime(),
    60 * 60 * 1000,
  );

  const pointOffsets = [0.05, 0.3, 0.55, 0.82];
  const values = [
    clampNumber(97 - unreadHandovers * 2, 78, 99),
    clampNumber(94 - escalatedItems * 3, 76, 98),
    clampNumber(88 - overdueTasks * 4 - escalatedItems * 2, 70, 96),
    clampNumber(
      95 - overdueTasks * 2 - escalatedItems * 3 - unreadHandovers * 2,
      72,
      98,
    ),
  ];

  return pointOffsets.map((offset, index) => ({
    timestamp: new Date(shiftStartsAt.getTime() + shiftDurationMs * offset),
    value: values[index],
  }));
}

export function mapIncidentExceptionFeedItem(
  incident: IncidentExceptionFeedInput,
) {
  return {
    kind: 'INCIDENT' as const,
    id: incident.id,
    title: incident.title,
    residentName: incident.resident.fullName,
    roomLabel: incident.resident.roomLabel,
    description: incident.details,
    status: incident.status,
    severity: incident.severity,
    badge: incident.severity === 'RED' ? 'RED INCIDENT' : 'AMBER INCIDENT',
    badgeTone: incident.severity === 'RED' ? 'critical' : 'warning',
    canAcknowledge: incident.status === 'OPEN',
    canResolve: incident.status === 'ACKNOWLEDGED',
    occurredAt: incident.occurredAt,
    dueAt: null,
    rank: getIncidentFeedRank(incident),
  };
}

export function mapTaskExceptionFeedItem(
  task: TaskExceptionFeedInput,
  activeShift: { unitLabel: string },
  referenceTime = Date.now(),
) {
  if (task.dashboardStatus === 'ESCALATED') {
    return {
      kind: 'TASK' as const,
      id: task.id,
      title: task.title,
      residentName: task.resident?.fullName ?? 'Unit task',
      roomLabel: task.resident?.roomLabel ?? activeShift.unitLabel,
      description:
        task.description ??
        'This item has been escalated for manager attention.',
      status: task.dashboardStatus,
      severity: null,
      badge: 'ESCALATED',
      badgeTone: 'warning',
      canAcknowledge: false,
      canResolve: false,
      occurredAt: null,
      dueAt: task.dueAt,
      rank: 4,
    };
  }

  if (task.dashboardStatus === 'OVERDUE') {
    return {
      kind: 'TASK' as const,
      id: task.id,
      title: task.title,
      residentName: task.resident?.fullName ?? 'Unit task',
      roomLabel: task.resident?.roomLabel ?? activeShift.unitLabel,
      description:
        task.description ?? 'This task missed its expected care window.',
      status: task.dashboardStatus,
      severity: null,
      badge: 'MISSED',
      badgeTone: 'critical',
      canAcknowledge: false,
      canResolve: false,
      occurredAt: null,
      dueAt: task.dueAt,
      rank: 5,
    };
  }

  if (
    task.dashboardStatus === 'PENDING' &&
    task.dueAt &&
    task.dueAt.getTime() - referenceTime <= 90 * 60 * 1000
  ) {
    return {
      kind: 'TASK' as const,
      id: task.id,
      title: task.title,
      residentName: task.resident?.fullName ?? 'Unit task',
      roomLabel: task.resident?.roomLabel ?? activeShift.unitLabel,
      description:
        task.description ?? 'This task is due soon within the active shift.',
      status: task.dashboardStatus,
      severity: null,
      badge: 'DUE SOON',
      badgeTone: 'info',
      canAcknowledge: false,
      canResolve: false,
      occurredAt: null,
      dueAt: task.dueAt,
      rank: 6,
    };
  }

  return null;
}

function buildTimelineActivityBadge(type: ResidentTimelineEntryType) {
  switch (type) {
    case 'PERSONAL_CARE':
      return 'PERSONAL CARE';
    case 'NUTRITION_HYDRATION':
      return 'NUTRITION';
    case 'MOBILITY_REPOSITIONING':
      return 'MOBILITY';
    case 'MEDICATION_NOTE':
      return 'MEDICATION';
    case 'ESCALATION':
      return 'ESCALATION';
    case 'OBSERVATION':
      return 'OBSERVATION';
    case 'CARE_GIVEN':
    default:
      return 'NOTE';
  }
}

export function mapTimelineActivityFeedItem(entry: TimelineActivityFeedInput) {
  return {
    id: `note-${entry.id}`,
    kind: 'NOTE' as const,
    title: entry.title,
    residentName: entry.resident.fullName,
    roomLabel: entry.resident.roomLabel,
    description: entry.details,
    actorName: entry.createdBy?.displayName ?? 'System note',
    occurredAt: entry.createdAt,
    badge: buildTimelineActivityBadge(entry.type),
    badgeTone: 'info',
  };
}

function buildTaskActivityDescription(
  badge: 'COMPLETED' | 'DEFERRED' | 'ESCALATED',
  statusNote: string | null,
) {
  if (statusNote) {
    return statusNote;
  }

  switch (badge) {
    case 'COMPLETED':
      return 'Task marked complete for this shift.';
    case 'DEFERRED':
      return 'Task deferred for later follow-up.';
    case 'ESCALATED':
    default:
      return 'Task escalated for manager attention.';
  }
}

export function mapTaskActivityFeedItem(
  task: TaskActivityFeedInput,
  badge: 'COMPLETED' | 'DEFERRED' | 'ESCALATED',
  tone: 'success' | 'warning',
  unitLabel: string,
) {
  return {
    id: `task-${task.id}-${badge.toLowerCase()}`,
    kind: 'TASK' as const,
    title: task.title,
    residentName: task.resident?.fullName ?? 'Unit task',
    roomLabel: task.resident?.roomLabel ?? unitLabel,
    description: buildTaskActivityDescription(badge, task.statusNote),
    actorName: task.updatedBy?.displayName ?? 'Unknown user',
    occurredAt: task.updatedAt,
    badge,
    badgeTone: tone,
  };
}

export function mapIncidentCreatedActivityFeedItem(
  incident: IncidentActivityFeedInput,
) {
  return {
    id: `incident-created-${incident.id}`,
    kind: 'INCIDENT' as const,
    title: incident.title,
    residentName: incident.resident.fullName,
    roomLabel: incident.resident.roomLabel,
    description: incident.details,
    actorName: incident.actorName ?? 'Unknown user',
    occurredAt: incident.occurredAt,
    badge: incident.severity === 'RED' ? 'RED INCIDENT' : 'AMBER INCIDENT',
    badgeTone: incident.severity === 'RED' ? 'critical' : 'warning',
  };
}

export function mapIncidentTransitionActivityFeedItem({
  eventId,
  incident,
  actorName,
  occurredAt,
  action,
}: {
  eventId: string;
  incident: IncidentActivityFeedInput;
  actorName: string | null;
  occurredAt: Date;
  action: 'ACKNOWLEDGED' | 'RESOLVED';
}) {
  return {
    id: `incident-${action.toLowerCase()}-${eventId}`,
    kind: 'INCIDENT' as const,
    title: incident.title,
    residentName: incident.resident.fullName,
    roomLabel: incident.resident.roomLabel,
    description:
      action === 'ACKNOWLEDGED'
        ? 'Incident acknowledged and stays visible for follow-up.'
        : 'Incident resolved and closed out for the shift.',
    actorName: actorName ?? 'Unknown user',
    occurredAt,
    badge: action,
    badgeTone: action === 'RESOLVED' ? 'success' : 'warning',
  };
}
