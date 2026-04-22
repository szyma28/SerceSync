import { Prisma } from '@prisma/client';
import type {
  MealIntakeAmount,
  MealType,
  IncidentCategory,
  IncidentSeverity,
  IncidentStatus,
  PersonalCareSubtype,
  ResidentTimelineEntryType,
  TaskStatus,
} from '@prisma/client';

export interface AuditEventDetails {
  incidentId?: string;
  residentId?: string;
  residentName?: string;
  entryId?: string;
  entryType?: ResidentTimelineEntryType;
  entryTitle?: string;
  personalCareSubtype?: PersonalCareSubtype | null;
  mealType?: MealType | null;
  mealIntakeAmount?: MealIntakeAmount | null;
  mediaAttached?: boolean;
  mediaType?: string;
  originalFileName?: string;
  severity?: IncidentSeverity;
  status?: IncidentStatus | TaskStatus;
  category?: IncidentCategory;
  title?: string;
  occurredAt?: Date;
  handoverId?: string;
  fromStatus?: TaskStatus;
  toStatus?: TaskStatus;
  note?: string | null;
}

type AuditEventDetailStringKey = Exclude<
  keyof AuditEventDetails,
  'mediaAttached' | 'occurredAt'
>;

function isAuditEventDetailRecord(
  details: Prisma.JsonValue | null | undefined,
): details is Record<string, Prisma.JsonValue> {
  return (
    typeof details === 'object' && details !== null && !Array.isArray(details)
  );
}

export function getAuditDetailString(
  details: Prisma.JsonValue | null | undefined,
  key: AuditEventDetailStringKey,
) {
  if (!isAuditEventDetailRecord(details)) {
    return null;
  }

  const value = details?.[key];

  return typeof value === 'string' && value.trim().length > 0 ? value : null;
}
