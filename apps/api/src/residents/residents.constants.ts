import { extname } from 'path';
import { Prisma } from '@prisma/client';
import type {
  IncidentStatus,
  MealIntakeAmount,
  MealType,
  PersonalCareSubtype,
  ResidentTimelineEntryType,
} from '@prisma/client';

export const activeIncidentStatuses: IncidentStatus[] = [
  'OPEN',
  'ACKNOWLEDGED',
];

export const residentEvidenceMaxUploadBytes = 4 * 1024 * 1024;

const allowedResidentEvidenceMimeTypes = new Set([
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const allowedResidentEvidenceExtensions = new Set([
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
]);

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

const mealTypeLabels: Record<MealType, string> = {
  BREAKFAST: 'Breakfast',
  LUNCH: 'Lunch',
  DINNER: 'Dinner',
  SNACK: 'Snack',
};

const mealIntakeAmountLabels: Record<MealIntakeAmount, string> = {
  NONE: 'None eaten',
  QUARTER: 'Quarter eaten',
  HALF: 'Half eaten',
  MOST: 'Most eaten',
  ALL: 'All eaten',
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

export function isSafeResidentEvidenceUpload(file: {
  mimetype: string;
  originalname: string;
}) {
  const normalizedMimeType = file.mimetype.trim().toLowerCase();
  const normalizedExtension = extname(file.originalname).trim().toLowerCase();

  return (
    allowedResidentEvidenceMimeTypes.has(normalizedMimeType) &&
    allowedResidentEvidenceExtensions.has(normalizedExtension)
  );
}

export function buildEntryTitle(
  type: ResidentTimelineEntryType,
  title: string | undefined,
  personalCareSubtype?: PersonalCareSubtype,
  mealType?: MealType,
  mealIntakeAmount?: MealIntakeAmount,
) {
  const trimmedTitle = title?.trim();
  if (trimmedTitle) {
    return trimmedTitle;
  }

  if (type === 'PERSONAL_CARE' && personalCareSubtype) {
    return `Personal Care · ${personalCareSubtypeLabels[personalCareSubtype]}`;
  }

  if (type === 'NUTRITION_HYDRATION' && mealType && mealIntakeAmount) {
    return `${mealTypeLabels[mealType]} intake · ${mealIntakeAmountLabels[mealIntakeAmount]}`;
  }

  return entryTypeLabels[type];
}
