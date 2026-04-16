import type {
  IncidentSeverity,
  IncidentStatus,
  ResidentPriorityLevel,
} from '@prisma/client';
import { activeIncidentStatuses } from './residents.constants';

type ResidentPrioritySource = 'INCIDENT_OVERRIDE' | 'BASELINE';

type ResidentPriorityState = {
  baselinePriority: ResidentPriorityLevel;
  effectivePriority: ResidentPriorityLevel;
  prioritySource: ResidentPrioritySource;
  activeIncidentCount: number;
};

type ResidentPriorityIncident = {
  severity: IncidentSeverity;
  status: IncidentStatus;
};

function isActiveIncidentStatus(status: IncidentStatus) {
  return activeIncidentStatuses.includes(status);
}

export function buildResidentPriorityState({
  baselinePriority,
  incidents,
}: {
  baselinePriority: ResidentPriorityLevel;
  incidents: ResidentPriorityIncident[];
}): ResidentPriorityState {
  const activeIncidents = incidents.filter((incident) =>
    isActiveIncidentStatus(incident.status),
  );

  if (activeIncidents.some((incident) => incident.severity === 'RED')) {
    return {
      baselinePriority,
      effectivePriority: 'RED',
      prioritySource: 'INCIDENT_OVERRIDE',
      activeIncidentCount: activeIncidents.length,
    };
  }

  if (activeIncidents.length > 0) {
    return {
      baselinePriority,
      effectivePriority: 'AMBER',
      prioritySource: 'INCIDENT_OVERRIDE',
      activeIncidentCount: activeIncidents.length,
    };
  }

  return {
    baselinePriority,
    effectivePriority: baselinePriority,
    prioritySource: 'BASELINE',
    activeIncidentCount: 0,
  };
}
