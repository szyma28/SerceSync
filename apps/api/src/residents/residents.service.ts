import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type {
  AuditEventKind,
  IncidentMedia,
  ResidentTimelineMedia,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { mkdir, unlink, writeFile } from 'fs/promises';
import { tmpdir } from 'os';
import { extname, join } from 'path';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import {
  getAuditDetailString,
  type AuditEventDetails,
} from '../audit-event-details';
import { ManagerDashboardStreamService } from '../manager-dashboard-stream/manager-dashboard-stream.service';
import { MedicationOperationalSummaryService } from '../medications/medication-operational-summary.service';
import type { MedicationTaskCompatibleSummary } from '../medications/medication-operational-summary.types';
import { MedicationsService } from '../medications/medications.service';
import { mapMedicationExceptionFeedItem } from '../medications/manager-medication-exception-feed';
import { PrismaService } from '../prisma/prisma.service';
import { buildTaskActionPermissions } from '../tasks/task-action-permissions';
import { buildMedicationTaskSummary } from '../tasks/task-medication-summary';
import { buildResidentPriorityState } from './resident-priority';
import { CreateManagerResidentDto } from './dto/create-manager-resident.dto';
import { CreateResidentIncidentDto } from './dto/create-resident-incident.dto';
import { CreateResidentTimelineEntryDto } from './dto/create-resident-timeline-entry.dto';
import { UpdateManagerResidentDto } from './dto/update-manager-resident.dto';
import {
  activeIncidentStatuses,
  buildEntryTitle,
  incidentInclude,
  isSafeResidentEvidenceUpload,
} from './residents.constants';
import {
  buildAlerts,
  buildContextLine,
  buildManagerComplianceSeries,
  buildManagerDashboardExceptionFeed,
  buildManagerDashboardMetrics,
  getDashboardTaskStatus,
  mapIncident,
  mapIncidentCreatedActivityFeedItem,
  mapIncidentTransitionActivityFeedItem,
  mapManagerResident,
  mapResidentListItem,
  mapResidentTask,
  mapTaskActivityFeedItem,
  mapTimelineActivityFeedItem,
  mapTimelineEntry,
} from './residents.presentation';

type UploadedEvidenceFile = {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
  size: number;
};

type TaskActivityBadgeConfig = {
  badge: 'COMPLETED' | 'DEFERRED' | 'ESCALATED';
  tone: 'success' | 'warning';
};

const taskActivityBadgeByKind: Record<
  Extract<
    AuditEventKind,
    'TASK_COMPLETED' | 'TASK_DEFERRED' | 'TASK_ESCALATED'
  >,
  TaskActivityBadgeConfig
> = {
  TASK_COMPLETED: {
    badge: 'COMPLETED',
    tone: 'success',
  },
  TASK_DEFERRED: {
    badge: 'DEFERRED',
    tone: 'warning',
  },
  TASK_ESCALATED: {
    badge: 'ESCALATED',
    tone: 'warning',
  },
};

const medicationNoteRestrictionReason = 'Only nurses can add medication notes.';
const emptyMedicationSummary: MedicationTaskCompatibleSummary = {
  total: 0,
  overdue: 0,
  dueWithinHour: 0,
  highPriority: 0,
  headline: null,
  warnings: [],
};

const maxClientEventFutureSkewMs = 5 * 60 * 1000;
const maxClientEventAgeMs = 72 * 60 * 60 * 1000;

function hasMedicationSignal(summary: MedicationTaskCompatibleSummary | null) {
  return (
    summary != null &&
    (summary.total > 0 ||
      summary.overdue > 0 ||
      summary.dueWithinHour > 0 ||
      summary.highPriority > 0 ||
      summary.headline != null ||
      summary.warnings.length > 0)
  );
}

type ResidentAccessAuditArgs = {
  user: AuthenticatedUser;
  resident: {
    id: string;
    fullName: string;
    roomLabel: string;
    floorNumber: number;
    unitLabel: string;
  };
  shiftId?: string | null;
  medicationContentVisible: boolean;
  activeIncidentCount?: number;
  currentTaskCount?: number;
};

function getTaskActivityBadgeConfig(
  kind: AuditEventKind,
): TaskActivityBadgeConfig | null {
  switch (kind) {
    case 'TASK_COMPLETED':
      return taskActivityBadgeByKind.TASK_COMPLETED;
    case 'TASK_DEFERRED':
      return taskActivityBadgeByKind.TASK_DEFERRED;
    case 'TASK_ESCALATED':
      return taskActivityBadgeByKind.TASK_ESCALATED;
    default:
      return null;
  }
}

@Injectable()
export class ResidentsService {
  private readonly logger = new Logger(ResidentsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly managerDashboardStream: ManagerDashboardStreamService,
    private readonly medicationsService: MedicationsService,
    private readonly medicationOperationalSummaryService: MedicationOperationalSummaryService,
  ) {}

  private getMediaStorageDirectory() {
    return join(tmpdir(), 'sercesync', 'resident-timeline-media');
  }

  private getIncidentMediaStorageDirectory() {
    return join(tmpdir(), 'sercesync', 'incident-media');
  }

  private async ensureMediaStorageDirectory() {
    const mediaDirectory = this.getMediaStorageDirectory();
    await mkdir(mediaDirectory, { recursive: true });
    return mediaDirectory;
  }

  private async ensureIncidentMediaStorageDirectory() {
    const mediaDirectory = this.getIncidentMediaStorageDirectory();
    await mkdir(mediaDirectory, { recursive: true });
    return mediaDirectory;
  }

  private logCleanupWarning(message: string, error: Error) {
    const details = error.message;
    this.logger.warn(`${message} (${details})`);
  }

  private async cleanupResidentTimelineMediaRollback(
    mediaRecord: ResidentTimelineMedia,
  ) {
    const storagePath = join(
      this.getMediaStorageDirectory(),
      mediaRecord.storageKey,
    );

    try {
      await this.prisma.residentTimelineMedia.delete({
        where: {
          id: mediaRecord.id,
        },
      });
    } catch (error) {
      this.logCleanupWarning(
        `Failed to remove resident timeline media record ${mediaRecord.id} during rollback`,
        error instanceof Error ? error : new Error(String(error)),
      );
    }

    try {
      await unlink(storagePath);
    } catch (error) {
      this.logCleanupWarning(
        `Failed to remove resident timeline media file ${storagePath} during rollback`,
        error instanceof Error ? error : new Error(String(error)),
      );
    }
  }

  private async cleanupIncidentMediaRollback(mediaRecord: IncidentMedia) {
    const storagePath = join(
      this.getIncidentMediaStorageDirectory(),
      mediaRecord.storageKey,
    );

    try {
      await this.prisma.incidentMedia.delete({
        where: {
          id: mediaRecord.id,
        },
      });
    } catch (error) {
      this.logCleanupWarning(
        `Failed to remove incident media record ${mediaRecord.id} during rollback`,
        error instanceof Error ? error : new Error(String(error)),
      );
    }

    try {
      await unlink(storagePath);
    } catch (error) {
      this.logCleanupWarning(
        `Failed to remove incident media file ${storagePath} during rollback`,
        error instanceof Error ? error : new Error(String(error)),
      );
    }
  }

  private roomLabel(roomNumber: number) {
    return `Room ${roomNumber}`;
  }

  private requireTrimmedText(value: string, fieldName: string) {
    const trimmedValue = value.trim();
    if (!trimmedValue) {
      throw new BadRequestException(`${fieldName} is required.`);
    }

    return trimmedValue;
  }

  private normalizeOptionalTrimmedText(
    value: string | null | undefined,
    fieldName: string,
  ) {
    if (value == null) {
      return undefined;
    }

    return this.requireTrimmedText(value, fieldName);
  }

  private async createResidentAccessAuditEvent(args: ResidentAccessAuditArgs) {
    await this.prisma.auditEvent.create({
      data: {
        kind: 'RESIDENT_RECORD_VIEWED',
        userId: args.user.userId,
        shiftId: args.shiftId ?? null,
        residentId: args.resident.id,
        details: {
          residentId: args.resident.id,
          residentName: args.resident.fullName,
          roomLabel: args.resident.roomLabel,
          floorNumber: args.resident.floorNumber,
          unitLabel: args.resident.unitLabel,
          viewerRole: args.user.role,
          medicationContentVisible: args.medicationContentVisible,
          activeIncidentCount: args.activeIncidentCount ?? null,
          currentTaskCount: args.currentTaskCount ?? null,
          accessScope: args.shiftId ? 'active-shift-floor-scope' : 'global',
        } satisfies AuditEventDetails,
      },
    });
  }

  private resolveClientEventTime(
    rawTimestamp: string | undefined,
    fieldName: 'recordedAt' | 'occurredAt',
  ) {
    if (!rawTimestamp) {
      return new Date();
    }

    const timestamp = new Date(rawTimestamp);
    const now = Date.now();
    const timestampMs = timestamp.getTime();

    if (Number.isNaN(timestampMs)) {
      throw new BadRequestException(`${fieldName} must be a valid ISO date.`);
    }

    if (timestampMs > now + maxClientEventFutureSkewMs) {
      throw new BadRequestException(
        `${fieldName} cannot be more than 5 minutes in the future.`,
      );
    }

    if (timestampMs < now - maxClientEventAgeMs) {
      throw new BadRequestException(
        `${fieldName} cannot be older than 72 hours without a supervised late-entry workflow.`,
      );
    }

    return timestamp;
  }

  private normalizeCreateResidentInput(input: CreateManagerResidentDto) {
    const aboutMe = this.requireTrimmedText(input.aboutMe, 'aboutMe');

    return {
      fullName: this.requireTrimmedText(input.fullName, 'fullName'),
      roomNumber: input.roomNumber,
      roomLabel: this.roomLabel(input.roomNumber),
      floorNumber: input.floorNumber,
      unitLabel: this.requireTrimmedText(input.unitLabel, 'unitLabel'),
      recognitionImageKey: this.requireTrimmedText(
        input.recognitionImageKey,
        'recognitionImageKey',
      ),
      careSummary: aboutMe,
      aboutMe,
      baselinePriority: input.baselinePriority,
      isActive: input.isActive ?? true,
    };
  }

  private normalizeUpdateResidentInput(input: UpdateManagerResidentDto) {
    return {
      ...('fullName' in input && input.fullName != null
        ? {
            fullName: this.normalizeOptionalTrimmedText(
              input.fullName,
              'fullName',
            ),
          }
        : {}),
      ...('unitLabel' in input && input.unitLabel != null
        ? {
            unitLabel: this.normalizeOptionalTrimmedText(
              input.unitLabel,
              'unitLabel',
            ),
          }
        : {}),
      ...('recognitionImageKey' in input && input.recognitionImageKey != null
        ? {
            recognitionImageKey: this.normalizeOptionalTrimmedText(
              input.recognitionImageKey,
              'recognitionImageKey',
            ),
          }
        : {}),
      ...('aboutMe' in input && input.aboutMe != null
        ? (() => {
            const aboutMe = this.normalizeOptionalTrimmedText(
              input.aboutMe,
              'aboutMe',
            );

            return aboutMe == null
              ? {}
              : {
                  aboutMe,
                  careSummary: aboutMe,
                };
          })()
        : {}),
      ...('roomNumber' in input && input.roomNumber != null
        ? {
            roomNumber: input.roomNumber,
            roomLabel: this.roomLabel(input.roomNumber),
          }
        : {}),
      ...('floorNumber' in input && input.floorNumber != null
        ? { floorNumber: input.floorNumber }
        : {}),
      ...('isActive' in input && input.isActive != null
        ? { isActive: input.isActive }
        : {}),
      ...('baselinePriority' in input && input.baselinePriority != null
        ? { baselinePriority: input.baselinePriority }
        : {}),
    };
  }

  private toManagerShiftSummary(shift: {
    id: string;
    name: string;
    status: string;
    unitLabel: string;
    floorNumber: number;
    startsAt: Date;
    endsAt: Date;
    assignedUsers?: Array<{
      id: string;
      email: string;
      displayName: string;
      role: {
        key: string;
      };
    }>;
  }) {
    return {
      id: shift.id,
      name: shift.name,
      status: shift.status,
      unitLabel: shift.unitLabel,
      floorNumber: shift.floorNumber,
      startsAt: shift.startsAt,
      endsAt: shift.endsAt,
      assignedUsers:
        shift.assignedUsers?.map((user) => ({
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          role: user.role.key,
        })) ?? [],
    };
  }

  private async findActiveManagerShiftById(shiftId: string) {
    const shift = await this.prisma.shift.findFirst({
      where: {
        id: shiftId,
        status: 'ACTIVE',
      },
      select: {
        id: true,
        name: true,
        status: true,
        unitLabel: true,
        floorNumber: true,
        startsAt: true,
        endsAt: true,
      },
    });

    if (!shift) {
      throw new NotFoundException(
        'Active shift was not found for the manager dashboard.',
      );
    }

    return shift;
  }

  private async findActiveDashboardShiftById(shiftId: string) {
    const shift = await this.prisma.shift.findFirst({
      where: {
        id: shiftId,
        status: 'ACTIVE',
      },
      include: {
        assignedUsers: {
          select: {
            id: true,
            email: true,
            displayName: true,
            role: {
              select: {
                key: true,
              },
            },
          },
        },
        handover: {
          include: {
            acknowledgements: {
              select: {
                acknowledgedById: true,
                acknowledgedAt: true,
              },
            },
          },
        },
        tasks: {
          include: {
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
          },
          orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
        },
      },
    });

    if (!shift) {
      throw new NotFoundException(
        'Active shift was not found for the manager dashboard.',
      );
    }

    return shift;
  }

  private async findActiveDashboardShifts() {
    const shifts = await this.prisma.shift.findMany({
      where: {
        status: 'ACTIVE',
      },
      include: {
        assignedUsers: {
          select: {
            id: true,
            email: true,
            displayName: true,
            role: {
              select: {
                key: true,
              },
            },
          },
        },
        handover: {
          include: {
            acknowledgements: {
              select: {
                acknowledgedById: true,
                acknowledgedAt: true,
              },
            },
          },
        },
        tasks: {
          include: {
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
          },
          orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
        },
      },
      orderBy: [{ startsAt: 'desc' }, { floorNumber: 'asc' }],
    });

    if (shifts.length === 0) {
      throw new NotFoundException(
        'Active shift was not found for the manager dashboard.',
      );
    }

    return shifts;
  }

  async ensureManagerDashboardShiftAccess(shiftId: string) {
    await this.findActiveDashboardShiftById(shiftId);
  }

  private incidentMatchesShiftScope(
    incident: {
      resident: {
        floorNumber: number;
        unitLabel: string;
        isActive: boolean;
      };
    },
    shift: {
      floorNumber: number;
      unitLabel: string;
    },
  ) {
    return (
      incident.resident.isActive &&
      incident.resident.floorNumber === shift.floorNumber &&
      incident.resident.unitLabel === shift.unitLabel
    );
  }

  private validateTimelineEntryPayload(
    createResidentTimelineEntryDto: CreateResidentTimelineEntryDto,
  ) {
    const hasPersonalCareSubtype =
      createResidentTimelineEntryDto.personalCareSubtype != null;
    const hasMealType = createResidentTimelineEntryDto.mealType != null;
    const hasMealIntakeAmount =
      createResidentTimelineEntryDto.mealIntakeAmount != null;
    const hasStructuredMealFields = hasMealType || hasMealIntakeAmount;
    const hasStructuredMealLog =
      createResidentTimelineEntryDto.type === 'NUTRITION_HYDRATION' &&
      hasMealType &&
      hasMealIntakeAmount;
    const hasDetails =
      (createResidentTimelineEntryDto.details?.trim().length ?? 0) > 0;

    if (
      createResidentTimelineEntryDto.type === 'PERSONAL_CARE' &&
      !hasPersonalCareSubtype
    ) {
      throw new BadRequestException(
        'personalCareSubtype is required when type is PERSONAL_CARE.',
      );
    }

    if (
      createResidentTimelineEntryDto.type !== 'PERSONAL_CARE' &&
      hasPersonalCareSubtype
    ) {
      throw new BadRequestException(
        'personalCareSubtype is only allowed when type is PERSONAL_CARE.',
      );
    }

    if (
      createResidentTimelineEntryDto.type !== 'NUTRITION_HYDRATION' &&
      hasStructuredMealFields
    ) {
      throw new BadRequestException(
        'mealType and mealIntakeAmount are only allowed when type is NUTRITION_HYDRATION.',
      );
    }

    if (hasMealType !== hasMealIntakeAmount) {
      throw new BadRequestException(
        'mealType and mealIntakeAmount must be provided together.',
      );
    }

    if (!hasDetails && !hasStructuredMealLog) {
      throw new BadRequestException(
        'details is required unless a structured meal intake log is provided.',
      );
    }
  }

  private resolveTimelineEntryDetails(
    createResidentTimelineEntryDto: CreateResidentTimelineEntryDto,
  ) {
    const trimmedDetails = createResidentTimelineEntryDto.details?.trim();
    if (trimmedDetails) {
      return trimmedDetails;
    }

    if (
      createResidentTimelineEntryDto.type === 'NUTRITION_HYDRATION' &&
      createResidentTimelineEntryDto.mealType &&
      createResidentTimelineEntryDto.mealIntakeAmount
    ) {
      return 'No additional concerns noted.';
    }

    throw new BadRequestException('details is required.');
  }

  private async getManagerActivityFeed(
    activeShifts: Array<{
      id: string;
      floorNumber: number;
      unitLabel: string;
    }>,
  ) {
    const shiftIds = activeShifts.map((shift) => shift.id);
    const shiftById = new Map(activeShifts.map((shift) => [shift.id, shift]));

    const [timelineEntries, taskEvents, createdIncidents, incidentEvents] =
      await Promise.all([
        this.prisma.residentTimelineEntry.findMany({
          where: {
            shiftId: {
              in: shiftIds,
            },
          },
          include: {
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
            createdBy: {
              select: {
                displayName: true,
              },
            },
          },
          orderBy: {
            recordedAt: 'desc',
          },
          take: 18,
        }),
        this.prisma.auditEvent.findMany({
          where: {
            shiftId: {
              in: shiftIds,
            },
            kind: {
              in: ['TASK_COMPLETED', 'TASK_DEFERRED', 'TASK_ESCALATED'],
            },
          },
          include: {
            user: {
              select: {
                displayName: true,
              },
            },
            task: {
              select: {
                id: true,
                title: true,
                statusNote: true,
                resident: {
                  select: {
                    fullName: true,
                    roomLabel: true,
                    floorNumber: true,
                    unitLabel: true,
                  },
                },
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 18,
        }),
        this.prisma.incident.findMany({
          where: {
            shiftId: {
              in: shiftIds,
            },
            resident: {
              isActive: true,
            },
          },
          include: {
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
            createdBy: {
              select: {
                displayName: true,
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 18,
        }),
        this.prisma.auditEvent.findMany({
          where: {
            shiftId: {
              in: shiftIds,
            },
            kind: {
              in: ['INCIDENT_ACKNOWLEDGED', 'INCIDENT_RESOLVED'],
            },
          },
          include: {
            user: {
              select: {
                displayName: true,
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 18,
        }),
      ]);

    const incidentIds = incidentEvents
      .map((event) => getAuditDetailString(event.details, 'incidentId'))
      .filter((incidentId): incidentId is string => incidentId != null);

    const transitionIncidents = incidentIds.length
      ? await this.prisma.incident.findMany({
          where: {
            id: {
              in: incidentIds,
            },
          },
          include: {
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
          },
        })
      : [];

    const incidentsById = new Map(
      transitionIncidents.map((incident) => [incident.id, incident]),
    );

    return [
      ...timelineEntries
        .map((entry) => {
          if (!entry.shiftId) {
            return null;
          }

          return mapTimelineActivityFeedItem({
            ...entry,
            shiftId: entry.shiftId,
          });
        })
        .filter((item): item is NonNullable<typeof item> => item !== null),
      ...taskEvents
        .map((event) => {
          if (!event.task) {
            return null;
          }

          const config = getTaskActivityBadgeConfig(event.kind);
          if (!config) {
            return null;
          }

          const shiftId = event.shiftId;
          if (!shiftId) {
            return null;
          }

          const shiftScope = shiftById.get(shiftId);
          if (!shiftScope) {
            return null;
          }

          return mapTaskActivityFeedItem(
            {
              id: event.task.id,
              shiftId,
              title: event.task.title,
              statusNote: event.task.statusNote,
              resident: event.task.resident,
              updatedAt: event.createdAt,
              updatedBy: event.user,
            },
            config.badge,
            config.tone,
            shiftScope,
          );
        })
        .filter((item): item is NonNullable<typeof item> => item !== null),
      ...createdIncidents
        .map((incident) => {
          if (!incident.shiftId) {
            return null;
          }

          return mapIncidentCreatedActivityFeedItem({
            id: incident.id,
            shiftId: incident.shiftId,
            title: incident.title,
            details: incident.details,
            severity: incident.severity,
            occurredAt: incident.createdAt,
            actorName: incident.createdBy?.displayName ?? null,
            resident: incident.resident,
          });
        })
        .filter((item): item is NonNullable<typeof item> => item !== null),
      ...incidentEvents
        .map((event) => {
          const incidentId = getAuditDetailString(event.details, 'incidentId');
          if (!incidentId) {
            return null;
          }

          const incident = incidentsById.get(incidentId);
          if (!incident) {
            return null;
          }

          if (!incident.shiftId) {
            return null;
          }

          return mapIncidentTransitionActivityFeedItem({
            eventId: event.id,
            shiftId: incident.shiftId,
            incident: {
              id: incident.id,
              shiftId: incident.shiftId,
              title: incident.title,
              details: incident.details,
              severity: incident.severity,
              occurredAt: incident.createdAt,
              actorName: null,
              resident: incident.resident,
            },
            actorName: event.user?.displayName ?? null,
            occurredAt: event.createdAt,
            action:
              event.kind === 'INCIDENT_RESOLVED' ? 'RESOLVED' : 'ACKNOWLEDGED',
          });
        })
        .filter((item): item is NonNullable<typeof item> => item !== null),
    ]
      .sort(
        (left, right) => right.occurredAt.getTime() - left.occurredAt.getTime(),
      )
      .slice(0, 12);
  }

  private async getResidentPrioritySnapshot(residentId: string) {
    const resident = await this.prisma.resident.findUnique({
      where: {
        id: residentId,
      },
      select: {
        id: true,
        baselinePriority: true,
        incidents: {
          where: {
            status: {
              in: activeIncidentStatuses,
            },
          },
          select: {
            severity: true,
            status: true,
          },
        },
      },
    });

    if (!resident) {
      throw new NotFoundException('Resident was not found.');
    }

    return {
      id: resident.id,
      ...buildResidentPriorityState({
        baselinePriority: resident.baselinePriority,
        incidents: resident.incidents,
      }),
    };
  }

  private async findCurrentShiftForUser(userId: string) {
    const shift = await this.prisma.shift.findFirst({
      where: {
        status: 'ACTIVE',
        assignedUsers: {
          some: {
            id: userId,
          },
        },
      },
      orderBy: {
        startsAt: 'desc',
      },
    });

    if (!shift) {
      throw new NotFoundException(
        'No active shift was found for the current user.',
      );
    }

    return shift;
  }

  private async findResidentInUserScope(residentId: string, userId: string) {
    const shift = await this.findCurrentShiftForUser(userId);

    const resident = await this.prisma.resident.findFirst({
      where: {
        id: residentId,
        isActive: true,
        floorNumber: shift.floorNumber,
      },
      include: {
        tasks: {
          where: {
            shiftId: shift.id,
          },
          orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
        },
        incidents: {
          where: {
            status: {
              in: activeIncidentStatuses,
            },
          },
          include: {
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
          },
          orderBy: [{ severity: 'desc' }, { occurredAt: 'desc' }],
        },
        timelineEntries: {
          include: {
            createdBy: true,
            media: {
              orderBy: {
                createdAt: 'asc',
              },
            },
          },
          orderBy: {
            recordedAt: 'desc',
          },
          take: 12,
        },
      },
    });

    if (!resident) {
      throw new NotFoundException(
        'The requested resident was not found in the current user shift scope.',
      );
    }

    return { shift, resident };
  }

  private canViewMedicationResidentContent(
    user: Pick<AuthenticatedUser, 'role'>,
  ) {
    return user.role === 'NURSE';
  }

  private filterResidentTasksForRole<
    T extends {
      focus: string;
    },
  >(tasks: T[], user: Pick<AuthenticatedUser, 'role'>) {
    if (this.canViewMedicationResidentContent(user)) {
      return tasks;
    }

    return tasks.filter((task) => task.focus !== 'MEDICATION');
  }

  private async persistResidentTimelineMedia(
    file: UploadedEvidenceFile,
    entryId: string,
    userId: string,
  ) {
    if (!isSafeResidentEvidenceUpload(file)) {
      throw new BadRequestException(
        'Resident evidence uploads must be PNG, JPEG, or WebP images.',
      );
    }

    const mediaDirectory = await this.ensureMediaStorageDirectory();
    const fileExtension = extname(file.originalname) || '.bin';
    const storageKey = `${randomUUID()}${fileExtension}`;
    const storagePath = join(mediaDirectory, storageKey);

    await writeFile(storagePath, file.buffer);

    return this.prisma.residentTimelineMedia.create({
      data: {
        entryId,
        originalFileName: file.originalname,
        mediaType: file.mimetype,
        byteSize: file.size,
        storageKey,
        uploadedById: userId,
      },
    });
  }

  private async persistIncidentMedia(
    file: UploadedEvidenceFile,
    incidentId: string,
    userId: string,
  ) {
    if (!isSafeResidentEvidenceUpload(file)) {
      throw new BadRequestException(
        'Incident evidence uploads must be PNG, JPEG, or WebP images.',
      );
    }

    const mediaDirectory = await this.ensureIncidentMediaStorageDirectory();
    const fileExtension = extname(file.originalname) || '.bin';
    const storageKey = `${randomUUID()}${fileExtension}`;
    const storagePath = join(mediaDirectory, storageKey);

    await writeFile(storagePath, file.buffer);

    return this.prisma.incidentMedia.create({
      data: {
        incidentId,
        originalFileName: file.originalname,
        mediaType: file.mimetype,
        byteSize: file.size,
        storageKey,
        uploadedById: userId,
      },
    });
  }

  async getResidents(user: AuthenticatedUser) {
    const shift = await this.findCurrentShiftForUser(user.userId);

    const residents = await this.prisma.resident.findMany({
      where: {
        floorNumber: shift.floorNumber,
        isActive: true,
      },
      include: {
        tasks: {
          where: {
            shiftId: shift.id,
          },
          orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
        },
        incidents: {
          where: {
            status: {
              in: activeIncidentStatuses,
            },
          },
          select: {
            severity: true,
            status: true,
          },
        },
      },
      orderBy: {
        roomNumber: 'asc',
      },
    });

    return {
      floorNumber: shift.floorNumber,
      unitLabel: shift.unitLabel,
      residents: residents.map((resident) => {
        const visibleTasks = this.filterResidentTasksForRole(
          resident.tasks,
          user,
        );

        return mapResidentListItem(
          {
            ...resident,
            tasks: visibleTasks,
          },
          shift,
        );
      }),
    };
  }

  async getResidentById(residentId: string, user: AuthenticatedUser) {
    const { shift, resident } = await this.findResidentInUserScope(
      residentId,
      user.userId,
    );

    const priorityState = buildResidentPriorityState({
      baselinePriority: resident.baselinePriority,
      incidents: resident.incidents,
    });
    const visibleTasks = this.filterResidentTasksForRole(resident.tasks, user);
    const medicationOperationalSummary = this.canViewMedicationResidentContent(
      user,
    )
      ? await this.medicationOperationalSummaryService.buildResidentOperationalSummary(
          resident.id,
        )
      : null;
    const medicationTaskSummary = this.canViewMedicationResidentContent(user)
      ? buildMedicationTaskSummary(visibleTasks)
      : emptyMedicationSummary;
    const medicationSummary = this.canViewMedicationResidentContent(user)
      ? hasMedicationSignal(
          medicationOperationalSummary?.taskSummaryCompatible ?? null,
        )
        ? (medicationOperationalSummary?.taskSummaryCompatible ??
          emptyMedicationSummary)
        : medicationTaskSummary
      : emptyMedicationSummary;
    const medicationProfile = this.canViewMedicationResidentContent(user)
      ? await this.medicationsService.buildResidentMedicationProfile(
          resident.id,
          user,
        )
      : null;

    await this.createResidentAccessAuditEvent({
      user,
      resident,
      shiftId: shift.id,
      medicationContentVisible: medicationProfile != null,
      activeIncidentCount: resident.incidents.length,
      currentTaskCount: visibleTasks.length,
    });

    return {
      id: resident.id,
      fullName: resident.fullName,
      roomLabel: resident.roomLabel,
      floorNumber: resident.floorNumber,
      unitLabel: resident.unitLabel,
      recognitionImageKey: resident.recognitionImageKey,
      aboutMe: resident.aboutMe,
      todaySummary: resident.careSummary,
      assignmentContext: `Assigned to ${shift.unitLabel} for this shift`,
      contextLine: buildContextLine(
        visibleTasks,
        resident.careSummary,
        Date.now(),
        medicationSummary,
      ),
      alerts: buildAlerts(visibleTasks, medicationSummary),
      ...priorityState,
      medicationSummary,
      medicationOperationalSummary,
      medicationProfile,
      activeIncidents: resident.incidents.map((incident) =>
        mapIncident(incident),
      ),
      currentTasks: visibleTasks
        .map((task) => ({
          ...mapResidentTask(
            task,
            resident.roomLabel,
            resident.id,
            resident.fullName,
          ),
          ...buildTaskActionPermissions(task, {
            currentUserId: user.userId,
            currentUserRole: user.role,
          }),
        }))
        .filter(
          (task) => task.status !== 'COMPLETED' && task.status !== 'DEFERRED',
        ),
      timeline: resident.timelineEntries.map((entry) =>
        mapTimelineEntry(entry),
      ),
    };
  }

  async createResidentTimelineEntry(
    residentId: string,
    user: AuthenticatedUser,
    createResidentTimelineEntryDto: CreateResidentTimelineEntryDto,
    evidenceFile?: UploadedEvidenceFile,
  ) {
    this.validateTimelineEntryPayload(createResidentTimelineEntryDto);

    if (
      createResidentTimelineEntryDto.type === 'MEDICATION_NOTE' &&
      user.role !== 'NURSE'
    ) {
      throw new ForbiddenException({
        message: medicationNoteRestrictionReason,
        code: 'MEDICATION_NOTE_NURSE_REQUIRED',
      });
    }

    const { shift, resident } = await this.findResidentInUserScope(
      residentId,
      user.userId,
    );
    const clientRequestId =
      createResidentTimelineEntryDto.clientRequestId?.trim() || null;
    const recordedAt = this.resolveClientEventTime(
      createResidentTimelineEntryDto.recordedAt,
      'recordedAt',
    );

    if (clientRequestId) {
      const existingEntry = await this.prisma.residentTimelineEntry.findFirst({
        where: {
          residentId: resident.id,
          createdById: user.userId,
          clientRequestId,
        },
        include: {
          createdBy: true,
          media: {
            orderBy: {
              createdAt: 'asc',
            },
          },
        },
      });

      if (existingEntry) {
        return {
          entry: mapTimelineEntry(existingEntry),
        };
      }
    }

    let mediaRecord: ResidentTimelineMedia | null = null;

    try {
      const createdEntry = await this.prisma.$transaction(async (tx) => {
        const entry = await tx.residentTimelineEntry.create({
          data: {
            residentId: resident.id,
            type: createResidentTimelineEntryDto.type,
            personalCareSubtype:
              createResidentTimelineEntryDto.personalCareSubtype ?? null,
            mealType: createResidentTimelineEntryDto.mealType ?? null,
            mealIntakeAmount:
              createResidentTimelineEntryDto.mealIntakeAmount ?? null,
            title: buildEntryTitle(
              createResidentTimelineEntryDto.type,
              createResidentTimelineEntryDto.title,
              createResidentTimelineEntryDto.personalCareSubtype,
              createResidentTimelineEntryDto.mealType,
              createResidentTimelineEntryDto.mealIntakeAmount,
            ),
            details: this.resolveTimelineEntryDetails(
              createResidentTimelineEntryDto,
            ),
            clientRequestId,
            createdById: user.userId,
            shiftId: shift.id,
            recordedAt,
          },
          include: {
            createdBy: true,
          },
        });

        await tx.auditEvent.create({
          data: {
            kind: 'RESIDENT_TIMELINE_ENTRY_CREATED',
            userId: user.userId,
            shiftId: shift.id,
            details: {
              residentId: resident.id,
              residentName: resident.fullName,
              entryType: entry.type,
              entryTitle: entry.title,
              personalCareSubtype: entry.personalCareSubtype,
              mealType: entry.mealType,
              mealIntakeAmount: entry.mealIntakeAmount,
              mediaAttached: Boolean(evidenceFile),
            } satisfies AuditEventDetails,
          },
        });

        return entry;
      });

      if (evidenceFile) {
        mediaRecord = await this.persistResidentTimelineMedia(
          evidenceFile,
          createdEntry.id,
          user.userId,
        );

        await this.prisma.auditEvent.create({
          data: {
            kind: 'RESIDENT_TIMELINE_MEDIA_ATTACHED',
            userId: user.userId,
            shiftId: shift.id,
            details: {
              residentId: resident.id,
              residentName: resident.fullName,
              entryId: createdEntry.id,
              mediaType: mediaRecord.mediaType,
              originalFileName: mediaRecord.originalFileName,
            } satisfies AuditEventDetails,
          },
        });
      }

      this.managerDashboardStream.publishShiftUpdate(
        shift.id,
        'timeline-entry-created',
      );

      return {
        entry: mapTimelineEntry({
          ...createdEntry,
          personalCareSubtype: createdEntry.personalCareSubtype,
          mealType: createdEntry.mealType,
          mealIntakeAmount: createdEntry.mealIntakeAmount,
          media: mediaRecord ? [mediaRecord] : [],
        }),
      };
    } catch (error) {
      if (
        clientRequestId &&
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existingEntry = await this.prisma.residentTimelineEntry.findFirst(
          {
            where: {
              residentId: resident.id,
              createdById: user.userId,
              clientRequestId,
            },
            include: {
              createdBy: true,
              media: {
                orderBy: {
                  createdAt: 'asc',
                },
              },
            },
          },
        );

        if (existingEntry) {
          return {
            entry: mapTimelineEntry(existingEntry),
          };
        }
      }

      if (mediaRecord) {
        await this.cleanupResidentTimelineMediaRollback(mediaRecord);
      }
      throw error;
    }
  }

  async createResidentIncident(
    residentId: string,
    user: AuthenticatedUser,
    createResidentIncidentDto: CreateResidentIncidentDto,
    evidenceFile?: UploadedEvidenceFile,
  ) {
    const { shift, resident } = await this.findResidentInUserScope(
      residentId,
      user.userId,
    );

    const clientRequestId =
      createResidentIncidentDto.clientRequestId?.trim() || null;
    const occurredAt = this.resolveClientEventTime(
      createResidentIncidentDto.occurredAt,
      'occurredAt',
    );

    if (clientRequestId) {
      const existingIncident = await this.prisma.incident.findFirst({
        where: {
          residentId: resident.id,
          createdById: user.userId,
          clientRequestId,
        },
        include: incidentInclude,
      });

      if (existingIncident) {
        return {
          incident: mapIncident(existingIncident),
          resident: await this.getResidentPrioritySnapshot(resident.id),
        };
      }
    }

    let mediaRecord: IncidentMedia | null = null;

    try {
      const incident = await this.prisma.$transaction(async (tx) => {
        const createdIncident = await tx.incident.create({
          data: {
            residentId: resident.id,
            shiftId: shift.id,
            createdById: user.userId,
            severity: createResidentIncidentDto.severity,
            category: createResidentIncidentDto.category,
            title: this.requireTrimmedText(
              createResidentIncidentDto.title,
              'title',
            ),
            details: this.requireTrimmedText(
              createResidentIncidentDto.details,
              'details',
            ),
            clientRequestId,
            occurredAt,
          },
          include: incidentInclude,
        });

        await tx.auditEvent.create({
          data: {
            kind: 'INCIDENT_CREATED',
            userId: user.userId,
            shiftId: shift.id,
            details: {
              incidentId: createdIncident.id,
              residentId: resident.id,
              residentName: resident.fullName,
              severity: createdIncident.severity,
              status: createdIncident.status,
              category: createdIncident.category,
              title: createdIncident.title,
              occurredAt: createdIncident.occurredAt,
              mediaAttached: Boolean(evidenceFile),
            } satisfies AuditEventDetails,
          },
        });

        return createdIncident;
      });

      if (evidenceFile) {
        mediaRecord = await this.persistIncidentMedia(
          evidenceFile,
          incident.id,
          user.userId,
        );

        await this.prisma.auditEvent.create({
          data: {
            kind: 'INCIDENT_MEDIA_ATTACHED',
            userId: user.userId,
            shiftId: shift.id,
            details: {
              incidentId: incident.id,
              residentId: resident.id,
              residentName: resident.fullName,
              mediaType: mediaRecord.mediaType,
              originalFileName: mediaRecord.originalFileName,
            } satisfies AuditEventDetails,
          },
        });
      }

      const residentPriority = await this.getResidentPrioritySnapshot(
        resident.id,
      );

      this.managerDashboardStream.publishShiftUpdate(
        shift.id,
        'incident-created',
      );

      return {
        incident: mapIncident({
          ...incident,
          media: mediaRecord ? [mediaRecord] : incident.media,
        }),
        resident: residentPriority,
      };
    } catch (error) {
      if (
        clientRequestId &&
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const existingIncident = await this.prisma.incident.findFirst({
          where: {
            residentId: resident.id,
            createdById: user.userId,
            clientRequestId,
          },
          include: incidentInclude,
        });

        if (existingIncident) {
          return {
            incident: mapIncident(existingIncident),
            resident: await this.getResidentPrioritySnapshot(resident.id),
          };
        }
      }

      if (mediaRecord) {
        await this.cleanupIncidentMediaRollback(mediaRecord);
      }
      throw error;
    }
  }

  async acknowledgeManagerIncident(
    incidentId: string,
    user: AuthenticatedUser,
    shiftId: string,
  ) {
    const shift = await this.findActiveManagerShiftById(shiftId);
    const existingIncident = await this.prisma.incident.findUnique({
      where: {
        id: incidentId,
      },
      include: incidentInclude,
    });

    if (!existingIncident) {
      throw new NotFoundException('Incident was not found.');
    }

    if (!this.incidentMatchesShiftScope(existingIncident, shift)) {
      throw new NotFoundException('Incident was not found.');
    }

    if (existingIncident.status !== 'OPEN') {
      throw new BadRequestException('Only open incidents can be acknowledged.');
    }

    const acknowledgedAt = new Date();
    const incident = await this.prisma.$transaction(async (tx) => {
      const transition = await tx.incident.updateMany({
        where: {
          id: incidentId,
          status: 'OPEN',
        },
        data: {
          status: 'ACKNOWLEDGED',
          acknowledgedAt,
          acknowledgedById: user.userId,
        },
      });

      if (transition.count !== 1) {
        throw new BadRequestException(
          'Only open incidents can be acknowledged.',
        );
      }

      const updatedIncident = await tx.incident.findUniqueOrThrow({
        where: {
          id: incidentId,
        },
        include: incidentInclude,
      });

      await tx.auditEvent.create({
        data: {
          kind: 'INCIDENT_ACKNOWLEDGED',
          userId: user.userId,
          shiftId: updatedIncident.shiftId,
          details: {
            incidentId: updatedIncident.id,
            residentId: updatedIncident.residentId,
            residentName: updatedIncident.resident.fullName,
            severity: updatedIncident.severity,
            status: updatedIncident.status,
          } satisfies AuditEventDetails,
        },
      });

      return updatedIncident;
    });

    this.managerDashboardStream.publishShiftUpdate(
      incident.shiftId,
      'incident-acknowledged',
    );

    return {
      incident: mapIncident(incident),
      resident: await this.getResidentPrioritySnapshot(incident.resident.id),
    };
  }

  async resolveManagerIncident(
    incidentId: string,
    user: AuthenticatedUser,
    shiftId: string,
  ) {
    const shift = await this.findActiveManagerShiftById(shiftId);
    const existingIncident = await this.prisma.incident.findUnique({
      where: {
        id: incidentId,
      },
      include: incidentInclude,
    });

    if (!existingIncident) {
      throw new NotFoundException('Incident was not found.');
    }

    if (!this.incidentMatchesShiftScope(existingIncident, shift)) {
      throw new NotFoundException('Incident was not found.');
    }

    if (existingIncident.status !== 'ACKNOWLEDGED') {
      throw new BadRequestException(
        'Only acknowledged incidents can be resolved.',
      );
    }

    const resolvedAt = new Date();
    const incident = await this.prisma.$transaction(async (tx) => {
      const transition = await tx.incident.updateMany({
        where: {
          id: incidentId,
          status: 'ACKNOWLEDGED',
        },
        data: {
          status: 'RESOLVED',
          resolvedAt,
          resolvedById: user.userId,
        },
      });

      if (transition.count !== 1) {
        throw new BadRequestException(
          'Only acknowledged incidents can be resolved.',
        );
      }

      const updatedIncident = await tx.incident.findUniqueOrThrow({
        where: {
          id: incidentId,
        },
        include: incidentInclude,
      });

      await tx.auditEvent.create({
        data: {
          kind: 'INCIDENT_RESOLVED',
          userId: user.userId,
          shiftId: updatedIncident.shiftId,
          details: {
            incidentId: updatedIncident.id,
            residentId: updatedIncident.residentId,
            residentName: updatedIncident.resident.fullName,
            severity: updatedIncident.severity,
            status: updatedIncident.status,
          } satisfies AuditEventDetails,
        },
      });

      return updatedIncident;
    });

    this.managerDashboardStream.publishShiftUpdate(
      incident.shiftId,
      'incident-resolved',
    );

    return {
      incident: mapIncident(incident),
      resident: await this.getResidentPrioritySnapshot(incident.resident.id),
    };
  }

  async getManagerResidents() {
    const residents = await this.prisma.resident.findMany({
      include: {
        incidents: {
          where: {
            status: {
              in: activeIncidentStatuses,
            },
          },
          select: {
            severity: true,
            status: true,
          },
        },
      },
      orderBy: [
        { floorNumber: 'asc' },
        { unitLabel: 'asc' },
        { roomNumber: 'asc' },
        { fullName: 'asc' },
      ],
    });

    return {
      residents: residents.map((resident) => mapManagerResident(resident)),
    };
  }

  async getManagerActiveShifts() {
    const activeShifts = await this.prisma.shift.findMany({
      where: {
        status: 'ACTIVE',
      },
      select: {
        id: true,
        name: true,
        status: true,
        unitLabel: true,
        floorNumber: true,
        startsAt: true,
        endsAt: true,
        assignedUsers: {
          select: {
            id: true,
            email: true,
            displayName: true,
            role: {
              select: {
                key: true,
              },
            },
          },
        },
      },
      orderBy: {
        startsAt: 'desc',
      },
    });

    return {
      activeShifts: activeShifts.map((shift) =>
        this.toManagerShiftSummary(shift),
      ),
    };
  }

  async getManagerDashboard(shiftId?: string) {
    const activeShifts = shiftId
      ? [await this.findActiveDashboardShiftById(shiftId)]
      : await this.findActiveDashboardShifts();
    const shiftIds = activeShifts.map((shift) => shift.id);
    const shiftById = new Map(activeShifts.map((shift) => [shift.id, shift]));

    const [incidents, activityFeed, medicationOverview] = await Promise.all([
      this.prisma.incident.findMany({
        where: {
          status: {
            in: activeIncidentStatuses,
          },
          shiftId: {
            in: shiftIds,
          },
          resident: {
            isActive: true,
          },
        },
        include: {
          resident: {
            select: {
              fullName: true,
              roomLabel: true,
              floorNumber: true,
              unitLabel: true,
            },
          },
        },
        orderBy: [{ createdAt: 'desc' }],
      }),
      this.getManagerActivityFeed(
        activeShifts.map((shift) => ({
          id: shift.id,
          floorNumber: shift.floorNumber,
          unitLabel: shift.unitLabel,
        })),
      ),
      this.medicationsService.buildManagerMedicationOverview(shiftId),
    ]);

    const normalizedTasks = activeShifts.flatMap((activeShift) =>
      activeShift.tasks.map((task) => ({
        ...task,
        dashboardStatus: getDashboardTaskStatus(task),
      })),
    );
    const metrics = buildManagerDashboardMetrics({
      activeShifts,
      normalizedTasks,
      activeIncidentCount: incidents.length,
    });

    const medicationExceptionFeed = medicationOverview.exceptions.map((entry) =>
      mapMedicationExceptionFeedItem({
        id: entry.id,
        shiftId: entry.shiftId,
        residentName: entry.residentName,
        roomLabel: entry.roomLabel,
        floorNumber: entry.floorNumber,
        unitLabel: entry.unitLabel,
        medicationName: entry.medicationName,
        dueWindowEnd: entry.dueWindowEnd,
        status: entry.status,
        recordedByUserName: entry.recordedByUserName,
        recordedAt: entry.recordedAt,
        reason: entry.reason,
        notes: entry.notes,
        roundLabel: entry.roundLabel,
      }),
    );

    const exceptionFeed = buildManagerDashboardExceptionFeed({
      incidents,
      medicationExceptionFeed,
      normalizedTasks,
      shiftById,
    });

    const shiftStartsAt = new Date(
      Math.min(
        ...activeShifts.map((activeShift) => activeShift.startsAt.getTime()),
      ),
    );
    const shiftEndsAt = new Date(
      Math.max(
        ...activeShifts.map((activeShift) => activeShift.endsAt.getTime()),
      ),
    );
    const complianceSeries = buildManagerComplianceSeries({
      shiftStartsAt,
      shiftEndsAt,
      overdueTasks: metrics.overdueTasks,
      escalatedItems: metrics.escalatedItems,
      unreadHandovers: metrics.unreadHandovers,
    });

    return {
      activeShift: this.toManagerShiftSummary(activeShifts[0]),
      activeShifts: activeShifts.map((activeShift) =>
        this.toManagerShiftSummary(activeShift),
      ),
      metrics,
      activityFeed,
      exceptionFeed,
      complianceSeries,
      medicationOverview,
    };
  }

  async createManagerResident(
    createManagerResidentDto: CreateManagerResidentDto,
  ) {
    const normalizedInput = this.normalizeCreateResidentInput(
      createManagerResidentDto,
    );

    try {
      const resident = await this.prisma.resident.create({
        data: {
          fullName: normalizedInput.fullName,
          roomNumber: normalizedInput.roomNumber,
          roomLabel: normalizedInput.roomLabel,
          floorNumber: normalizedInput.floorNumber,
          unitLabel: normalizedInput.unitLabel,
          recognitionImageKey: normalizedInput.recognitionImageKey,
          careSummary: normalizedInput.careSummary,
          aboutMe: normalizedInput.aboutMe,
          baselinePriority: normalizedInput.baselinePriority,
          isActive: normalizedInput.isActive,
        },
      });

      return {
        resident: mapManagerResident({
          ...resident,
          incidents: [],
        }),
      };
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'A resident already exists for that floor and room number.',
        );
      }
      throw error;
    }
  }

  async updateManagerResident(
    residentId: string,
    updateManagerResidentDto: UpdateManagerResidentDto,
  ) {
    const existingResident = await this.prisma.resident.findUnique({
      where: {
        id: residentId,
      },
    });

    if (!existingResident) {
      throw new NotFoundException('Resident was not found.');
    }

    const normalizedInput = this.normalizeUpdateResidentInput(
      updateManagerResidentDto,
    );

    try {
      const resident = await this.prisma.resident.update({
        where: {
          id: residentId,
        },
        data: normalizedInput,
        include: {
          incidents: {
            where: {
              status: {
                in: activeIncidentStatuses,
              },
            },
            select: {
              severity: true,
              status: true,
            },
          },
        },
      });

      return {
        resident: mapManagerResident(resident),
      };
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'A resident already exists for that floor and room number.',
        );
      }
      throw error;
    }
  }

  async getResidentMedia(mediaId: string, user: AuthenticatedUser) {
    const media = await this.prisma.residentTimelineMedia.findUnique({
      where: {
        id: mediaId,
      },
      include: {
        entry: {
          include: {
            resident: true,
          },
        },
      },
    });

    if (!media) {
      throw new NotFoundException('Resident media was not found.');
    }

    if (user.role !== 'MANAGER') {
      await this.findResidentInUserScope(media.entry.resident.id, user.userId);
    }

    return {
      ...media,
      storagePath: join(this.getMediaStorageDirectory(), media.storageKey),
    };
  }
}
