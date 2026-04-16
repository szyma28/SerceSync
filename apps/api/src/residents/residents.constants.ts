import { Prisma } from '@prisma/client';
import type {
  IncidentStatus,
  PersonalCareSubtype,
  ResidentTimelineEntryType,
} from '@prisma/client';

export const activeIncidentStatuses: IncidentStatus[] = [
  'OPEN',
  'ACKNOWLEDGED',
];

const entryTypeLabels: Record<ResidentTimelineEntryType, string> = {
  CARE_GIVEN: 'Care Given',
  OBSERVATION: 'Observation',
  PERSONAL_CARE: 'Personal Care',
  NUTRITION_HYDRATION: 'Nutrition / Hydration',
  MOBILITY_REPOSITIONING: 'Mobility / Repositioning',
  MEDICATION_NOTE: 'Medication Note',
  ESCALATION: 'Escalation',
};

const personalCareSubtypeLabels: Record<PersonalCareSubtype, string> = {
  SHOWER: 'Shower',
  CONTINENCE: 'Continence',
  FOOT_CARE: 'Foot care',
  SKIN_CARE: 'Skin care',
};

export const incidentCategoryLabels = {
  FALL: 'Fall',
  MEDICATION: 'Medication',
  BEHAVIOUR: 'Behaviour',
  INJURY: 'Injury',
  OTHER: 'Other',
} as const;

export const incidentInclude = {
  resident: {
    select: {
      id: true,
      fullName: true,
      roomLabel: true,
      baselinePriority: true,
      floorNumber: true,
      unitLabel: true,
      isActive: true,
    },
  },
  createdBy: {
    select: {
      displayName: true,
    },
  },
  acknowledgedBy: {
    select: {
      displayName: true,
    },
  },
  resolvedBy: {
    select: {
      displayName: true,
    },
  },
  media: {
    orderBy: {
      createdAt: 'asc',
    },
  },
} satisfies Prisma.IncidentInclude;

export function buildEntryTitle(
  type: ResidentTimelineEntryType,
  title: string | undefined,
  personalCareSubtype?: PersonalCareSubtype,
) {
  const trimmedTitle = title?.trim();
  if (trimmedTitle) {
    return trimmedTitle;
  }

  if (type === 'PERSONAL_CARE' && personalCareSubtype) {
    return `Personal Care · ${personalCareSubtypeLabels[personalCareSubtype]}`;
  }

  return entryTypeLabels[type];
}
