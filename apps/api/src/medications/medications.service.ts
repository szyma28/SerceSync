import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  MedicationAdministrationEventType,
  MedicationChartStatus,
  MedicationChangeType,
  MedicationDoseStatus,
  MedicationOrderSourceType,
  MedicationReconciliationStatus,
  MedicationReconciliationTriggerType,
  MedicationScheduleAnchorType,
  MedicationStockTransactionType,
  Prisma,
  type AuditEventKind,
  type RoleKey,
  type ShiftStatus,
} from '@prisma/client';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { ManagerDashboardStreamService } from '../manager-dashboard-stream/manager-dashboard-stream.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateMedicationAllergyDto } from './dto/create-medication-allergy.dto';
import { CreateMedicationOrderDto } from './dto/create-medication-order.dto';
import { CreateMedicationReconciliationDto } from './dto/create-medication-reconciliation.dto';
import { CreateMedicationScheduleDto } from './dto/create-medication-schedule.dto';
import { CreateMedicationStockTransactionDto } from './dto/create-medication-stock-transaction.dto';
import { CreatePrnEventDto } from './dto/create-prn-event.dto';
import { CreatePrnProtocolDto } from './dto/create-prn-protocol.dto';
import { DeactivateMedicationOrderDto } from './dto/deactivate-medication-order.dto';
import { DeactivateMedicationScheduleDto } from './dto/deactivate-medication-schedule.dto';
import { CompleteMedicationReconciliationDto } from './dto/complete-medication-reconciliation.dto';
import { RecordDoseOutcomeDto } from './dto/record-dose-outcome.dto';
import { UpdateDoseStatusDto } from './dto/update-dose-status.dto';
import { UpdateMedicationOrderDto } from './dto/update-medication-order.dto';
import { UpdateMedicationScheduleDto } from './dto/update-medication-schedule.dto';
import { UpdatePrnProtocolDto } from './dto/update-prn-protocol.dto';
import {
  medicationControlledDrugNotice,
  medicationDowntimeNotice,
  medicationDowntimePackNotice,
  medicationWorkflowNote,
  medicationSafetyBanner,
  prnConfirmationWarningPrefix,
} from './medications.constants';

const medicationViewerRestrictionReason =
  'Only nurses and managers can view eMAR information.';
const medicationManagementRestrictionReason =
  'Only managers can create or update medication orders.';
const medicationRecordingRestrictionReason =
  'Only nurses can record medication administration.';
const medicationHandoverRestrictionReason =
  'Medication actions are blocked until the current shift handover is acknowledged.';
const prnEventTypes = new Set<MedicationAdministrationEventType>([
  MedicationAdministrationEventType.PRN_OFFERED,
  MedicationAdministrationEventType.PRN_ADMINISTERED,
  MedicationAdministrationEventType.PRN_REFUSED,
  MedicationAdministrationEventType.PRN_NOT_GIVEN,
]);
const reasonRequiredStatuses = new Set<MedicationDoseStatus>([
  MedicationDoseStatus.REFUSED,
  MedicationDoseStatus.OMITTED,
  MedicationDoseStatus.DELAYED,
  MedicationDoseStatus.NOT_AVAILABLE,
  MedicationDoseStatus.HELD,
]);
const mutableDoseStatuses = new Set<MedicationDoseStatus>([
  MedicationDoseStatus.DUE,
  MedicationDoseStatus.OVERDUE,
  MedicationDoseStatus.CANCELLED,
]);
const medicationAuditKinds: AuditEventKind[] = [
  'MEDICATION_CHART_CREATED',
  'MEDICATION_ORDER_CREATED',
  'MEDICATION_ORDER_UPDATED',
  'MEDICATION_ORDER_DEACTIVATED',
  'MEDICATION_SCHEDULE_CREATED',
  'MEDICATION_SCHEDULE_UPDATED',
  'MEDICATION_DOSE_INSTANCE_GENERATED',
  'MEDICATION_DOSE_ADMINISTERED',
  'MEDICATION_DOSE_REFUSED',
  'MEDICATION_DOSE_OMITTED',
  'MEDICATION_DOSE_DELAYED',
  'MEDICATION_DOSE_NOT_AVAILABLE',
  'MEDICATION_DOSE_HELD',
  'MEDICATION_PRN_EVENT_RECORDED',
  'MEDICATION_STOCK_TRANSACTION_RECORDED',
  'MEDICATION_ALLERGY_RECORDED',
  'MEDICATION_EXCEPTION_VIEWED',
  'MEDICATION_RECONCILIATION_STARTED',
  'MEDICATION_RECONCILIATION_COMPLETED',
  'MEDICATION_DOWNTIME_PACK_EXPORTED',
];
const controlledDrugWitnessTransactionTypes =
  new Set<MedicationStockTransactionType>([
    MedicationStockTransactionType.RECEIVED,
    MedicationStockTransactionType.RETURNED,
    MedicationStockTransactionType.DISPOSED,
    MedicationStockTransactionType.ADJUSTED,
  ]);
const controlledDrugReasonTransactionTypes =
  new Set<MedicationStockTransactionType>([
    MedicationStockTransactionType.RETURNED,
    MedicationStockTransactionType.DISPOSED,
    MedicationStockTransactionType.ADJUSTED,
  ]);
const weekdayLookup = [
  'SUNDAY',
  'MONDAY',
  'TUESDAY',
  'WEDNESDAY',
  'THURSDAY',
  'FRIDAY',
  'SATURDAY',
];

type MedicationShiftAccess = {
  id: string;
  name: string;
  status: ShiftStatus;
  startsAt: Date;
  endsAt: Date;
  floorNumber: number;
  unitLabel: string;
  handover: {
    acknowledgements: Array<{
      acknowledgedAt: Date;
      acknowledgedById: string;
    }>;
  } | null;
};

type MedicationExceptionStatus =
  | 'OVERDUE'
  | 'REFUSED'
  | 'OMITTED'
  | 'DELAYED'
  | 'NOT_AVAILABLE'
  | 'HELD';

type MedicationDueWindow = {
  anchorAt: Date;
  scheduledAt: Date;
  dueWindowStart: Date;
  dueWindowEnd: Date;
};

type MedicationAllergySnapshot = Pick<
  Prisma.MedicationAllergyIntoleranceGetPayload<{}>,
  'id' | 'substance' | 'reaction' | 'severity'
>;

type MedicationDoseInstanceSource = {
  id: string;
  residentId: string;
  shiftId: string;
  medicationOrderId: string;
  scheduleId: string;
  dueWindowStart: Date;
  dueWindowEnd: Date;
  status: MedicationDoseStatus;
  generatedAt: Date;
  recordedByUserId: string | null;
  recordedAt: Date | null;
  reason: string | null;
  notes: string | null;
  requiresWitness: boolean;
  witnessUserId: string | null;
  medicationOrder: {
    id: string;
    medicationName: string;
    formulation: string | null;
    strength: string | null;
    doseAmount: string;
    doseUnit: string;
    route: string;
    instructions: string;
    requiresWitness: boolean;
    resident: {
      id: string;
      fullName: string;
      roomLabel: string;
      floorNumber: number;
      unitLabel: string;
    };
  };
  schedule: {
    id: string;
    roundLabel: string;
    anchorType: MedicationScheduleAnchorType;
  };
};

type MedicationDoseInstanceView = {
  id: string;
  residentId: string;
  residentName: string;
  roomLabel: string;
  floorNumber: number;
  unitLabel: string;
  medicationOrderId: string;
  medicationName: string;
  formulation: string | null;
  strength: string | null;
  doseAmount: string;
  doseUnit: string;
  route: string;
  instructions: string;
  roundLabel: string;
  anchorType: MedicationScheduleAnchorType;
  dueWindowStart: Date;
  dueWindowEnd: Date;
  status: MedicationDoseStatus;
  generatedAt: Date;
  recordedByUserId: string | null;
  recordedByUserName: string | null;
  recordedAt: Date | null;
  reason: string | null;
  notes: string | null;
  requiresWitness: boolean;
  witnessUserId: string | null;
  witnessUserName: string | null;
  allergies: MedicationAllergySnapshot[];
};

type MedicationAdministrationEventSource = {
  id: string;
  doseInstanceId: string | null;
  residentId: string;
  shiftId: string;
  medicationOrderId: string;
  eventType: MedicationAdministrationEventType;
  doseGiven: string | null;
  doseUnit: string | null;
  reason: string | null;
  notes: string | null;
  recordedByUserId: string;
  recordedAt: Date;
  witnessUserId: string | null;
  createdAt: Date;
  medicationOrder: {
    medicationName: string;
    strength: string | null;
    formulation: string | null;
  };
  resident: {
    fullName: string;
    roomLabel: string;
  };
};

type MedicationAdministrationEventView = {
  id: string;
  doseInstanceId: string | null;
  residentId: string;
  residentName: string;
  roomLabel: string;
  shiftId: string;
  medicationOrderId: string;
  medicationName: string;
  strength: string | null;
  formulation: string | null;
  eventType: MedicationAdministrationEventType;
  doseGiven: string | null;
  doseUnit: string | null;
  reason: string | null;
  notes: string | null;
  recordedByUserId: string;
  recordedByUserName: string | null;
  recordedAt: Date;
  witnessUserId: string | null;
  witnessUserName: string | null;
  createdAt: Date;
};

type MedicationRoundGroup = {
  roundLabel: string;
  items: MedicationDoseInstanceView[];
};

type CsvCell = string | number | boolean | Date | null | undefined;

type MedicationOrderSnapshotSource = {
  medicationName: string;
  formulation: string | null;
  strength: string | null;
  doseAmount: string;
  doseUnit: string;
  route: string;
  instructions: string;
  startDate: Date;
  endDate: Date | null;
  isActive: boolean;
  isControlledDrug: boolean;
  requiresWitness: boolean;
  isPRN: boolean;
  sourceType: MedicationOrderSourceType;
  deactivationReason: string | null;
  deactivatedAt: Date | null;
};

@Injectable()
export class MedicationsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly managerDashboardStream: ManagerDashboardStreamService,
  ) {}

  private sanitizeOptionalText(value?: string | null) {
    const trimmed = value?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : null;
  }

  private ensureRole(
    user: Pick<AuthenticatedUser, 'role'>,
    allowedRoles: RoleKey[],
    message: string,
  ) {
    if (!allowedRoles.includes(user.role)) {
      throw new ForbiddenException({
        message,
      });
    }
  }

  private requireReason(value: string | undefined | null, message: string) {
    const trimmed = value?.trim();
    if (!trimmed || trimmed.length < 3) {
      throw new BadRequestException(message);
    }

    return trimmed;
  }

  private normalizeDaysOfWeek(daysOfWeek?: string[] | null) {
    const normalized = (daysOfWeek ?? []).map((value) =>
      value.trim().toUpperCase(),
    );
    const invalid = normalized.find((value) => !weekdayLookup.includes(value));
    if (invalid) {
      throw new BadRequestException(
        `Unsupported dayOfWeek value \"${invalid}\". Use weekday names such as MONDAY or TUESDAY.`,
      );
    }

    return Array.from(new Set(normalized));
  }

  private normalizeFixedTimeLocal(value?: string | null) {
    const trimmed = value?.trim();
    if (!trimmed) {
      return null;
    }

    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(trimmed)) {
      throw new BadRequestException('fixedTimeLocal must use HH:mm format.');
    }

    return trimmed;
  }

  private toLocalDateKey(value: Date) {
    const year = value.getFullYear();
    const month = `${value.getMonth() + 1}`.padStart(2, '0');
    const day = `${value.getDate()}`.padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  private isOrderActiveOnOccurrenceDate(
    order: { startDate: Date; endDate: Date | null },
    occurrenceAt: Date,
  ) {
    const occurrenceDay = this.toLocalDateKey(occurrenceAt);
    const orderStart = this.toLocalDateKey(order.startDate);
    const orderEnd = order.endDate ? this.toLocalDateKey(order.endDate) : null;

    return (
      orderStart <= occurrenceDay &&
      (orderEnd == null || orderEnd >= occurrenceDay)
    );
  }

  private appliesOnOccurrenceDate(daysOfWeek: string[], occurrenceAt: Date) {
    if (daysOfWeek.length === 0) {
      return true;
    }

    return daysOfWeek.includes(weekdayLookup[occurrenceAt.getDay()]);
  }

  private buildAnchorTimeWithinShift(args: {
    shiftStartsAt: Date;
    shiftEndsAt: Date;
    fixedTimeLocal: string;
  }): Date | null {
    const [hours, minutes] = args.fixedTimeLocal.split(':').map(Number);
    const cursor = new Date(args.shiftStartsAt);
    cursor.setHours(0, 0, 0, 0);
    const lastCandidateDay = new Date(args.shiftEndsAt);
    lastCandidateDay.setHours(0, 0, 0, 0);

    while (cursor.getTime() <= lastCandidateDay.getTime()) {
      const anchor = new Date(cursor);
      anchor.setHours(hours, minutes, 0, 0);
      if (
        anchor.getTime() >= args.shiftStartsAt.getTime() &&
        anchor.getTime() < args.shiftEndsAt.getTime()
      ) {
        return anchor;
      }

      cursor.setDate(cursor.getDate() + 1);
    }

    return null;
  }

  private isOccurrenceWithinShift(args: {
    shiftStartsAt: Date;
    shiftEndsAt: Date;
    occurrenceAt: Date;
  }) {
    return (
      args.occurrenceAt.getTime() >= args.shiftStartsAt.getTime() &&
      args.occurrenceAt.getTime() < args.shiftEndsAt.getTime()
    );
  }

  private resolveDueWindow(args: {
    anchorType: MedicationScheduleAnchorType;
    shiftStartsAt: Date;
    shiftEndsAt: Date;
    handoverAcknowledgedAt: Date | null;
    fixedTimeLocal: string | null;
    windowStartOffsetMinutes: number | null;
    windowEndOffsetMinutes: number | null;
  }): MedicationDueWindow | null {
    let anchor: Date | null;
    switch (args.anchorType) {
      case MedicationScheduleAnchorType.SHIFT_START:
        anchor = new Date(args.shiftStartsAt);
        break;
      case MedicationScheduleAnchorType.HANDOVER_ACKNOWLEDGED:
        anchor = args.handoverAcknowledgedAt
          ? new Date(args.handoverAcknowledgedAt)
          : null;
        break;
      case MedicationScheduleAnchorType.FIXED_TIME:
        anchor = args.fixedTimeLocal
          ? this.buildAnchorTimeWithinShift({
              shiftStartsAt: args.shiftStartsAt,
              shiftEndsAt: args.shiftEndsAt,
              fixedTimeLocal: args.fixedTimeLocal,
            })
          : null;
        break;
      default:
        anchor = null;
        break;
    }

    if (!anchor) {
      return null;
    }

    const start = new Date(anchor);
    start.setMinutes(start.getMinutes() + (args.windowStartOffsetMinutes ?? 0));

    const end = new Date(anchor);
    end.setMinutes(end.getMinutes() + (args.windowEndOffsetMinutes ?? 60));

    if (end.getTime() <= start.getTime()) {
      end.setTime(start.getTime() + 60 * 60 * 1000);
    }

    return {
      anchorAt: anchor,
      scheduledAt:
        args.anchorType === MedicationScheduleAnchorType.FIXED_TIME
          ? anchor
          : start,
      dueWindowStart: start,
      dueWindowEnd: end,
    };
  }

  private parseQuantityValue(value: string, fieldName = 'quantity') {
    const trimmed = value.trim();
    if (!/^-?\d+(\.\d+)?$/.test(trimmed)) {
      throw new BadRequestException(
        `${fieldName} must be a numeric value stored as a string.`,
      );
    }

    const numeric = Number.parseFloat(trimmed);
    if (!Number.isFinite(numeric)) {
      throw new BadRequestException(
        `${fieldName} must be a numeric value stored as a string.`,
      );
    }

    return numeric;
  }

  private formatQuantityValue(value: number) {
    if (Number.isInteger(value)) {
      return `${value}`;
    }

    return value.toFixed(3).replace(/\.?0+$/, '');
  }

  private applyStockTransactionBalance(
    currentQuantity: string | null | undefined,
    transactionType: MedicationStockTransactionType,
    quantity: string,
  ) {
    const current = currentQuantity
      ? this.parseQuantityValue(currentQuantity, 'currentQuantity')
      : 0;
    const delta = this.parseQuantityValue(quantity);

    switch (transactionType) {
      case MedicationStockTransactionType.RECEIVED:
        return this.formatQuantityValue(current + delta);
      case MedicationStockTransactionType.ADMINISTERED:
      case MedicationStockTransactionType.DISPOSED:
      case MedicationStockTransactionType.RETURNED:
        return this.formatQuantityValue(current - delta);
      case MedicationStockTransactionType.ADJUSTED:
      default:
        return this.formatQuantityValue(delta);
    }
  }

  private async loadUserNameMap(userIds: Array<string | null | undefined>) {
    const uniqueIds = Array.from(
      new Set(userIds.filter((userId): userId is string => Boolean(userId))),
    );

    if (uniqueIds.length === 0) {
      return new Map<string, string>();
    }

    const users = await this.prisma.user.findMany({
      where: {
        id: {
          in: uniqueIds,
        },
      },
      select: {
        id: true,
        displayName: true,
      },
    });

    return new Map(users.map((entry) => [entry.id, entry.displayName]));
  }

  private async reconcileDoseInstancesForOrder(
    tx: Prisma.TransactionClient,
    args: {
      medicationOrderId: string;
      actedByUserId: string;
      cancellationReason: string;
      referenceTime?: Date;
    },
  ) {
    const referenceTime = args.referenceTime ?? new Date();
    const doseInstances = await tx.medicationDoseInstance.findMany({
      where: {
        medicationOrderId: args.medicationOrderId,
        status: {
          in: Array.from(mutableDoseStatuses),
        },
      },
      include: {
        medicationOrder: true,
        schedule: true,
        shift: {
          include: {
            handover: {
              include: {
                acknowledgements: {
                  orderBy: {
                    acknowledgedAt: 'asc',
                  },
                  select: {
                    acknowledgedAt: true,
                    acknowledgedById: true,
                  },
                },
              },
            },
          },
        },
      },
    });

    for (const doseInstance of doseInstances) {
      const handoverAcknowledgedAt =
        this.getEarliestHandoverAcknowledgement(doseInstance.shift);
      const dueWindow =
        doseInstance.medicationOrder.isActive &&
        !doseInstance.medicationOrder.isPRN &&
        doseInstance.schedule.active
          ? this.resolveDueWindow({
              anchorType: doseInstance.schedule.anchorType,
              shiftStartsAt: doseInstance.shift.startsAt,
              shiftEndsAt: doseInstance.shift.endsAt,
              handoverAcknowledgedAt,
              fixedTimeLocal: doseInstance.schedule.fixedTimeLocal,
              windowStartOffsetMinutes:
                doseInstance.schedule.windowStartOffsetMinutes,
              windowEndOffsetMinutes:
                doseInstance.schedule.windowEndOffsetMinutes,
            })
          : null;
      const shouldRemainActive =
        dueWindow != null &&
        this.isOccurrenceWithinShift({
          shiftStartsAt: doseInstance.shift.startsAt,
          shiftEndsAt: doseInstance.shift.endsAt,
          occurrenceAt: dueWindow.scheduledAt,
        }) &&
        this.appliesOnOccurrenceDate(
          doseInstance.schedule.daysOfWeek,
          dueWindow.scheduledAt,
        ) &&
        this.isOrderActiveOnOccurrenceDate(
          doseInstance.medicationOrder,
          dueWindow.scheduledAt,
        );

      if (!shouldRemainActive) {
        if (doseInstance.status !== MedicationDoseStatus.CANCELLED) {
          await tx.medicationDoseInstance.update({
            where: { id: doseInstance.id },
            data: {
              status: MedicationDoseStatus.CANCELLED,
              recordedByUserId: args.actedByUserId,
              recordedAt: referenceTime,
              reason: args.cancellationReason,
              notes:
                'Open dose instance invalidated after medication order or schedule change.',
              witnessUserId: null,
              requiresWitness: doseInstance.medicationOrder.requiresWitness,
            },
          });
        }
        continue;
      }

      const reconciledStatus =
        dueWindow.dueWindowEnd.getTime() < referenceTime.getTime()
          ? MedicationDoseStatus.OVERDUE
          : MedicationDoseStatus.DUE;
      await tx.medicationDoseInstance.update({
        where: { id: doseInstance.id },
        data: {
          dueWindowStart: dueWindow.dueWindowStart,
          dueWindowEnd: dueWindow.dueWindowEnd,
          status: reconciledStatus,
          requiresWitness: doseInstance.medicationOrder.requiresWitness,
          recordedByUserId: null,
          recordedAt: null,
          reason: null,
          notes: null,
          witnessUserId: null,
        },
      });
    }
  }

  private async resolveShiftAccess(
    shiftId: string,
    user: AuthenticatedUser,
    options?: { allowManagerOverride?: boolean },
  ) {
    const allowManagerOverride = options?.allowManagerOverride ?? true;
    const shift = await this.prisma.shift.findFirst({
      where: {
        id: shiftId,
        ...(user.role === 'MANAGER' && allowManagerOverride
          ? {}
          : {
              assignedUsers: {
                some: {
                  id: user.userId,
                },
              },
            }),
      },
      include: {
        handover: {
          include: {
            acknowledgements: {
              orderBy: {
                acknowledgedAt: 'asc',
              },
              select: {
                acknowledgedAt: true,
                acknowledgedById: true,
              },
            },
          },
        },
      },
    });

    if (!shift) {
      throw new NotFoundException(
        'The requested shift was not found in the current user scope.',
      );
    }

    return shift as MedicationShiftAccess;
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
      include: {
        handover: {
          include: {
            acknowledgements: {
              orderBy: {
                acknowledgedAt: 'asc',
              },
              select: {
                acknowledgedAt: true,
                acknowledgedById: true,
              },
            },
          },
        },
      },
      orderBy: {
        startsAt: 'desc',
      },
    });

    if (!shift) {
      throw new NotFoundException(
        'No active shift found for the current user.',
      );
    }

    return shift as MedicationShiftAccess;
  }

  private async findResidentInScope(
    residentId: string,
    user: AuthenticatedUser,
  ) {
    const resident = await this.prisma.resident.findUnique({
      where: {
        id: residentId,
      },
      select: {
        id: true,
        fullName: true,
        roomLabel: true,
        roomNumber: true,
        floorNumber: true,
        unitLabel: true,
        isActive: true,
      },
    });

    if (!resident) {
      throw new NotFoundException('Resident was not found.');
    }

    if (user.role === 'MANAGER') {
      return {
        resident,
        shift: null,
      };
    }

    const shift = await this.findCurrentShiftForUser(user.userId);
    if (resident.floorNumber !== shift.floorNumber) {
      throw new NotFoundException(
        'The requested resident was not found in the current user shift scope.',
      );
    }

    return {
      resident,
      shift,
    };
  }

  private getEarliestHandoverAcknowledgement(shift: MedicationShiftAccess) {
    return shift.handover?.acknowledgements[0]?.acknowledgedAt ?? null;
  }

  private getUserHandoverAcknowledgement(
    shift: MedicationShiftAccess,
    userId: string,
  ) {
    return (
      shift.handover?.acknowledgements.find(
        (acknowledgement) => acknowledgement.acknowledgedById === userId,
      )?.acknowledgedAt ?? null
    );
  }

  private ensureHandoverAcknowledged(
    shift: MedicationShiftAccess,
    user: AuthenticatedUser,
  ) {
    if (user.role === 'MANAGER') {
      return null;
    }

    const acknowledgedAt = this.getUserHandoverAcknowledgement(
      shift,
      user.userId,
    );
    if (!acknowledgedAt) {
      throw new ForbiddenException({
        message: medicationHandoverRestrictionReason,
      });
    }

    return acknowledgedAt;
  }

  private async ensureWitnessUser(
    witnessUserId: string | null,
    disallowUserId?: string,
  ) {
    if (!witnessUserId) {
      return null;
    }

    if (disallowUserId && witnessUserId === disallowUserId) {
      throw new BadRequestException(
        'Witness confirmation must come from a second authorised user.',
      );
    }

    const witness = await this.prisma.user.findUnique({
      where: { id: witnessUserId },
      include: {
        role: {
          select: {
            key: true,
          },
        },
      },
    });

    if (!witness || !['NURSE', 'MANAGER'].includes(witness.role.key)) {
      throw new BadRequestException(
        'Witness confirmation must come from an authorised nurse or manager.',
      );
    }

    return witness;
  }

  private async syncOverdueDoseInstances(shiftId: string) {
    const overdueInstances = await this.prisma.medicationDoseInstance.findMany({
      where: {
        shiftId,
        status: 'DUE',
        dueWindowEnd: {
          lt: new Date(),
        },
      },
      select: {
        id: true,
      },
    });

    if (overdueInstances.length === 0) {
      return;
    }

    await this.prisma.medicationDoseInstance.updateMany({
      where: {
        id: {
          in: overdueInstances.map((entry) => entry.id),
        },
      },
      data: {
        status: 'OVERDUE',
      },
    });
  }

  private async createAuditEvent(
    tx: Prisma.TransactionClient,
    args: {
      kind: AuditEventKind;
      userId?: string | null;
      shiftId?: string | null;
      residentId?: string | null;
      medicationOrderId?: string | null;
      medicationDoseInstanceId?: string | null;
      details?: Prisma.InputJsonValue;
    },
  ) {
    await tx.auditEvent.create({
      data: {
        kind: args.kind,
        userId: args.userId ?? null,
        shiftId: args.shiftId ?? null,
        residentId: args.residentId ?? null,
        medicationOrderId: args.medicationOrderId ?? null,
        medicationDoseInstanceId: args.medicationDoseInstanceId ?? null,
        details: args.details,
      },
    });
  }

  private async createMedicationTimelineEntry(
    tx: Prisma.TransactionClient,
    args: {
      residentId: string;
      shiftId?: string | null;
      createdById: string;
      title: string;
      details: string;
    },
  ) {
    return tx.residentTimelineEntry.create({
      data: {
        residentId: args.residentId,
        shiftId: args.shiftId ?? null,
        createdById: args.createdById,
        type: 'MEDICATION_NOTE',
        title: args.title,
        details: args.details,
      },
    });
  }

  private buildMedicationOrderSnapshot(
    order: MedicationOrderSnapshotSource,
  ): Prisma.InputJsonObject {
    return {
      medicationName: order.medicationName,
      formulation: order.formulation ?? null,
      strength: order.strength ?? null,
      doseAmount: order.doseAmount,
      doseUnit: order.doseUnit,
      route: order.route,
      instructions: order.instructions,
      startDate: order.startDate.toISOString(),
      endDate: order.endDate?.toISOString() ?? null,
      isActive: order.isActive,
      isControlledDrug: order.isControlledDrug,
      requiresWitness: order.requiresWitness,
      isPRN: order.isPRN,
      sourceType: order.sourceType,
      deactivationReason: order.deactivationReason ?? null,
      deactivatedAt: order.deactivatedAt?.toISOString() ?? null,
    };
  }

  private buildTimelineDetails(args: {
    eventType: MedicationAdministrationEventType;
    medicationName: string;
    strength?: string | null;
    actorName: string;
    roundLabel?: string | null;
    reason?: string | null;
  }) {
    const medicationLabel = [args.medicationName, args.strength]
      .filter(Boolean)
      .join(' ')
      .trim();

    switch (args.eventType) {
      case MedicationAdministrationEventType.ADMINISTERED:
        return `${medicationLabel} administered by ${args.actorName}.`;
      case MedicationAdministrationEventType.REFUSED:
        return `${args.roundLabel ?? 'Medication'} refused. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.OMITTED:
        return `${args.roundLabel ?? 'Medication'} omitted. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.DELAYED:
        return `${args.roundLabel ?? 'Medication'} delayed. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.NOT_AVAILABLE:
        return `${args.roundLabel ?? 'Medication'} not available. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.HELD:
        return `${args.roundLabel ?? 'Medication'} held. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.PRN_OFFERED:
        return `PRN ${medicationLabel} offered. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.PRN_ADMINISTERED:
        return `PRN ${medicationLabel} administered. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.PRN_REFUSED:
        return `PRN ${medicationLabel} refused. Reason: ${args.reason ?? 'No reason recorded'}.`;
      case MedicationAdministrationEventType.PRN_NOT_GIVEN:
        return `PRN ${medicationLabel} not given. Reason: ${args.reason ?? 'No reason recorded'}.`;
      default:
        return `${medicationLabel} event recorded by ${args.actorName}.`;
    }
  }

  private mapSchedule(schedule: {
    id: string;
    roundLabel: string;
    anchorType: MedicationScheduleAnchorType;
    windowStartOffsetMinutes: number | null;
    windowEndOffsetMinutes: number | null;
    fixedTimeLocal: string | null;
    daysOfWeek: string[];
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: schedule.id,
      roundLabel: schedule.roundLabel,
      anchorType: schedule.anchorType,
      windowStartOffsetMinutes: schedule.windowStartOffsetMinutes,
      windowEndOffsetMinutes: schedule.windowEndOffsetMinutes,
      fixedTimeLocal: schedule.fixedTimeLocal,
      daysOfWeek: schedule.daysOfWeek,
      active: schedule.active,
      createdAt: schedule.createdAt,
      updatedAt: schedule.updatedAt,
    };
  }

  private mapPrnProtocol(protocol: {
    id: string;
    indication: string;
    whenToOffer: string;
    doseInstructions: string;
    minimumIntervalMinutes: number | null;
    maxDosePer24Hours: number | null;
    expectedEffect: string | null;
    monitoringRequired: string | null;
    whenToEscalate: string | null;
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: protocol.id,
      indication: protocol.indication,
      whenToOffer: protocol.whenToOffer,
      doseInstructions: protocol.doseInstructions,
      minimumIntervalMinutes: protocol.minimumIntervalMinutes,
      maxDosePer24Hours: protocol.maxDosePer24Hours,
      expectedEffect: protocol.expectedEffect,
      monitoringRequired: protocol.monitoringRequired,
      whenToEscalate: protocol.whenToEscalate,
      active: protocol.active,
      createdAt: protocol.createdAt,
      updatedAt: protocol.updatedAt,
    };
  }

  private mapStockRecord(
    stockRecord: {
      id: string;
      currentQuantity: string;
      quantityUnit: string;
      lastCheckedByUserId: string | null;
      lastCheckedAt: Date | null;
      notes: string | null;
      updatedAt: Date;
    },
    userNames: Map<string, string>,
  ) {
    return {
      id: stockRecord.id,
      currentQuantity: stockRecord.currentQuantity,
      quantityUnit: stockRecord.quantityUnit,
      lastCheckedByUserId: stockRecord.lastCheckedByUserId,
      lastCheckedByUserName: stockRecord.lastCheckedByUserId
        ? (userNames.get(stockRecord.lastCheckedByUserId) ?? null)
        : null,
      lastCheckedAt: stockRecord.lastCheckedAt,
      notes: stockRecord.notes,
      updatedAt: stockRecord.updatedAt,
    };
  }

  private mapMedicationOrder(
    order: {
      id: string;
      medicationName: string;
      formulation: string | null;
      strength: string | null;
      doseAmount: string;
      doseUnit: string;
      route: string;
      instructions: string;
      startDate: Date;
      endDate: Date | null;
      isActive: boolean;
      isControlledDrug: boolean;
      requiresWitness: boolean;
      isPRN: boolean;
      sourceType: MedicationOrderSourceType;
      createdByUserId: string;
      updatedByUserId: string;
      createdAt: Date;
      updatedAt: Date;
      deactivatedAt: Date | null;
      deactivationReason: string | null;
      schedules?: Array<{
        id: string;
        roundLabel: string;
        anchorType: MedicationScheduleAnchorType;
        windowStartOffsetMinutes: number | null;
        windowEndOffsetMinutes: number | null;
        fixedTimeLocal: string | null;
        daysOfWeek: string[];
        active: boolean;
        createdAt: Date;
        updatedAt: Date;
      }>;
      prnProtocol?: {
        id: string;
        indication: string;
        whenToOffer: string;
        doseInstructions: string;
        minimumIntervalMinutes: number | null;
        maxDosePer24Hours: number | null;
        expectedEffect: string | null;
        monitoringRequired: string | null;
        whenToEscalate: string | null;
        active: boolean;
        createdAt: Date;
        updatedAt: Date;
      } | null;
      stockRecord?: {
        id: string;
        currentQuantity: string;
        quantityUnit: string;
        lastCheckedByUserId: string | null;
        lastCheckedAt: Date | null;
        notes: string | null;
        updatedAt: Date;
      } | null;
    },
    userNames: Map<string, string>,
  ) {
    return {
      id: order.id,
      medicationName: order.medicationName,
      formulation: order.formulation,
      strength: order.strength,
      doseAmount: order.doseAmount,
      doseUnit: order.doseUnit,
      route: order.route,
      instructions: order.instructions,
      startDate: order.startDate,
      endDate: order.endDate,
      isActive: order.isActive,
      isControlledDrug: order.isControlledDrug,
      requiresWitness: order.requiresWitness,
      isPRN: order.isPRN,
      sourceType: order.sourceType,
      createdByUserId: order.createdByUserId,
      createdByUserName: userNames.get(order.createdByUserId) ?? null,
      updatedByUserId: order.updatedByUserId,
      updatedByUserName: userNames.get(order.updatedByUserId) ?? null,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      deactivatedAt: order.deactivatedAt,
      deactivationReason: order.deactivationReason,
      schedules: (order.schedules ?? []).map((schedule) =>
        this.mapSchedule(schedule),
      ),
      prnProtocol: order.prnProtocol
        ? this.mapPrnProtocol(order.prnProtocol)
        : null,
      stock: order.stockRecord
        ? this.mapStockRecord(order.stockRecord, userNames)
        : null,
    };
  }

  private mapDoseInstance(
    doseInstance: MedicationDoseInstanceSource,
    userNames: Map<string, string>,
    allergiesByResidentId?: Map<string, MedicationAllergySnapshot[]>,
  ): MedicationDoseInstanceView {
    const resident = doseInstance.medicationOrder.resident;
    return {
      id: doseInstance.id,
      residentId: resident.id,
      residentName: resident.fullName,
      roomLabel: resident.roomLabel,
      floorNumber: resident.floorNumber,
      unitLabel: resident.unitLabel,
      medicationOrderId: doseInstance.medicationOrder.id,
      medicationName: doseInstance.medicationOrder.medicationName,
      formulation: doseInstance.medicationOrder.formulation,
      strength: doseInstance.medicationOrder.strength,
      doseAmount: doseInstance.medicationOrder.doseAmount,
      doseUnit: doseInstance.medicationOrder.doseUnit,
      route: doseInstance.medicationOrder.route,
      instructions: doseInstance.medicationOrder.instructions,
      roundLabel: doseInstance.schedule.roundLabel,
      anchorType: doseInstance.schedule.anchorType,
      dueWindowStart: doseInstance.dueWindowStart,
      dueWindowEnd: doseInstance.dueWindowEnd,
      status: doseInstance.status,
      generatedAt: doseInstance.generatedAt,
      recordedByUserId: doseInstance.recordedByUserId,
      recordedByUserName: doseInstance.recordedByUserId
        ? (userNames.get(doseInstance.recordedByUserId) ?? null)
        : null,
      recordedAt: doseInstance.recordedAt,
      reason: doseInstance.reason,
      notes: doseInstance.notes,
      requiresWitness: doseInstance.requiresWitness,
      witnessUserId: doseInstance.witnessUserId,
      witnessUserName: doseInstance.witnessUserId
        ? (userNames.get(doseInstance.witnessUserId) ?? null)
        : null,
      allergies:
        allergiesByResidentId?.get(resident.id)?.map((allergy) => ({
          ...allergy,
        })) ?? [],
    };
  }

  private mapAdministrationEvent(
    event: MedicationAdministrationEventSource,
    userNames: Map<string, string>,
  ): MedicationAdministrationEventView {
    return {
      id: event.id,
      doseInstanceId: event.doseInstanceId,
      residentId: event.residentId,
      residentName: event.resident.fullName,
      roomLabel: event.resident.roomLabel,
      shiftId: event.shiftId,
      medicationOrderId: event.medicationOrderId,
      medicationName: event.medicationOrder.medicationName,
      strength: event.medicationOrder.strength,
      formulation: event.medicationOrder.formulation,
      eventType: event.eventType,
      doseGiven: event.doseGiven,
      doseUnit: event.doseUnit,
      reason: event.reason,
      notes: event.notes,
      recordedByUserId: event.recordedByUserId,
      recordedByUserName: userNames.get(event.recordedByUserId) ?? null,
      recordedAt: event.recordedAt,
      witnessUserId: event.witnessUserId,
      witnessUserName: event.witnessUserId
        ? (userNames.get(event.witnessUserId) ?? null)
        : null,
      createdAt: event.createdAt,
    };
  }

  private mapMedicationChangeLog(
    changeLog: {
      id: string;
      medicationOrderId: string;
      residentId: string;
      changedByUserId: string;
      changeType: MedicationChangeType;
      previousValueJson: Prisma.JsonValue | null;
      newValueJson: Prisma.JsonValue | null;
      reason: string;
      createdAt: Date;
      medicationOrder: {
        medicationName: string;
      };
    },
    userNames: Map<string, string>,
  ) {
    return {
      id: changeLog.id,
      medicationOrderId: changeLog.medicationOrderId,
      residentId: changeLog.residentId,
      medicationName: changeLog.medicationOrder.medicationName,
      changedByUserId: changeLog.changedByUserId,
      changedByUserName: userNames.get(changeLog.changedByUserId) ?? null,
      changeType: changeLog.changeType,
      previousValueJson: changeLog.previousValueJson,
      newValueJson: changeLog.newValueJson,
      reason: changeLog.reason,
      createdAt: changeLog.createdAt,
    };
  }

  private mapMedicationReconciliation(
    reconciliation: {
      id: string;
      residentId: string;
      status: MedicationReconciliationStatus;
      triggerType: MedicationReconciliationTriggerType;
      downtimeStartedAt: Date | null;
      downtimeEndedAt: Date | null;
      paperRecordLocation: string | null;
      discrepancySummary: string | null;
      controlledDrugCheckSummary: string | null;
      notes: string | null;
      createdByUserId: string;
      completedByUserId: string | null;
      completedAt: Date | null;
      createdAt: Date;
      updatedAt: Date;
    },
    userNames: Map<string, string>,
  ) {
    return {
      id: reconciliation.id,
      residentId: reconciliation.residentId,
      status: reconciliation.status,
      triggerType: reconciliation.triggerType,
      downtimeStartedAt: reconciliation.downtimeStartedAt,
      downtimeEndedAt: reconciliation.downtimeEndedAt,
      paperRecordLocation: reconciliation.paperRecordLocation,
      discrepancySummary: reconciliation.discrepancySummary,
      controlledDrugCheckSummary: reconciliation.controlledDrugCheckSummary,
      notes: reconciliation.notes,
      createdByUserId: reconciliation.createdByUserId,
      createdByUserName: userNames.get(reconciliation.createdByUserId) ?? null,
      completedByUserId: reconciliation.completedByUserId,
      completedByUserName: reconciliation.completedByUserId
        ? (userNames.get(reconciliation.completedByUserId) ?? null)
        : null,
      completedAt: reconciliation.completedAt,
      createdAt: reconciliation.createdAt,
      updatedAt: reconciliation.updatedAt,
    };
  }

  private async ensureActiveChart(
    tx: Prisma.TransactionClient,
    residentId: string,
    actorUserId: string,
  ) {
    const existingChart = await tx.residentMedicationChart.findFirst({
      where: {
        residentId,
        status: MedicationChartStatus.ACTIVE,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    if (existingChart) {
      return {
        chart: existingChart,
        wasCreated: false,
      };
    }

    const chart = await tx.residentMedicationChart.create({
      data: {
        residentId,
        status: MedicationChartStatus.ACTIVE,
        createdByUserId: actorUserId,
      },
    });

    await this.createAuditEvent(tx, {
      kind: 'MEDICATION_CHART_CREATED',
      userId: actorUserId,
      residentId,
      details: {
        chartId: chart.id,
        status: chart.status,
      },
    });

    return {
      chart,
      wasCreated: true,
    };
  }

  async buildResidentMedicationProfile(
    residentId: string,
    user: AuthenticatedUser,
  ) {
    const { resident } = await this.findResidentInScope(residentId, user);

    const activeChart = await this.prisma.residentMedicationChart.findFirst({
      where: {
        residentId: resident.id,
        status: MedicationChartStatus.ACTIVE,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const [orders, allergies, recentEvents, changeLogs, reconciliations] =
      await Promise.all([
        this.prisma.medicationOrder.findMany({
          where: {
            residentId: resident.id,
          },
          include: {
            schedules: {
              orderBy: [{ roundLabel: 'asc' }, { createdAt: 'asc' }],
            },
            prnProtocol: true,
            stockRecord: true,
          },
          orderBy: [{ isPRN: 'asc' }, { medicationName: 'asc' }],
        }),
        this.prisma.medicationAllergyIntolerance.findMany({
          where: {
            residentId: resident.id,
          },
          orderBy: {
            createdAt: 'desc',
          },
        }),
        this.prisma.medicationAdministrationEvent.findMany({
          where: {
            residentId: resident.id,
          },
          include: {
            medicationOrder: {
              select: {
                medicationName: true,
                strength: true,
                formulation: true,
              },
            },
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
              },
            },
          },
          orderBy: {
            recordedAt: 'desc',
          },
          take: 20,
        }),
        this.prisma.medicationChangeLog.findMany({
          where: {
            residentId: resident.id,
          },
          include: {
            medicationOrder: {
              select: {
                medicationName: true,
              },
            },
          },
          orderBy: {
            createdAt: 'desc',
          },
          take: 20,
        }),
        this.prisma.medicationReconciliation.findMany({
          where: {
            residentId: resident.id,
          },
          orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
          take: 20,
        }),
      ]);

    const userNames = await this.loadUserNameMap([
      activeChart?.createdByUserId,
      activeChart?.reviewedByUserId,
      ...orders.flatMap((order) => [
        order.createdByUserId,
        order.updatedByUserId,
        order.stockRecord?.lastCheckedByUserId,
      ]),
      ...allergies.map((allergy) => allergy.recordedByUserId),
      ...recentEvents.flatMap((event) => [
        event.recordedByUserId,
        event.witnessUserId,
      ]),
      ...changeLogs.map((entry) => entry.changedByUserId),
      ...reconciliations.flatMap((entry) => [
        entry.createdByUserId,
        entry.completedByUserId,
      ]),
    ]);

    const mappedAllergies = allergies.map((entry) => ({
      id: entry.id,
      substance: entry.substance,
      reaction: entry.reaction,
      severity: entry.severity,
      recordedByUserId: entry.recordedByUserId,
      recordedByUserName: userNames.get(entry.recordedByUserId) ?? null,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    }));

    const mappedReconciliations = reconciliations.map((entry) =>
      this.mapMedicationReconciliation(entry, userNames),
    );
    const pendingReconciliations = mappedReconciliations.filter(
      (entry) => entry.status === MedicationReconciliationStatus.PENDING,
    );
    const controlledDrugOrders = orders.filter(
      (order) => order.isControlledDrug,
    );

    return {
      workflowNote: medicationWorkflowNote,
      downtimeNotice: medicationDowntimeNotice,
      downtimePackNotice: medicationDowntimePackNotice,
      safetyBanner: medicationSafetyBanner,
      controlledDrugNotice: medicationControlledDrugNotice,
      resident,
      chart: activeChart
        ? {
            id: activeChart.id,
            status: activeChart.status,
            createdByUserId: activeChart.createdByUserId,
            createdByUserName:
              userNames.get(activeChart.createdByUserId) ?? null,
            reviewedByUserId: activeChart.reviewedByUserId,
            reviewedByUserName: activeChart.reviewedByUserId
              ? (userNames.get(activeChart.reviewedByUserId) ?? null)
              : null,
            archivedAt: activeChart.archivedAt,
            createdAt: activeChart.createdAt,
            updatedAt: activeChart.updatedAt,
          }
        : null,
      allergies: mappedAllergies,
      scheduledMedications: orders
        .filter((order) => !order.isPRN)
        .map((order) => this.mapMedicationOrder(order, userNames)),
      prnMedications: orders
        .filter((order) => order.isPRN)
        .map((order) => this.mapMedicationOrder(order, userNames)),
      recentEvents: recentEvents.map((event) =>
        this.mapAdministrationEvent(event, userNames),
      ),
      stockOverview: orders
        .filter((order) => order.stockRecord != null)
        .map((order) => this.mapStockRecord(order.stockRecord!, userNames)),
      reconciliations: mappedReconciliations,
      changeHistory: changeLogs.map((entry) =>
        this.mapMedicationChangeLog(entry, userNames),
      ),
      operationalWorkflows: {
        downtimePackExportPath: `/residents/${resident.id}/emar/downtime-pack/export`,
        pendingReconciliationCount: pendingReconciliations.length,
        latestPendingReconciliation: pendingReconciliations[0] ?? null,
        controlledDrugMedicationCount: controlledDrugOrders.length,
      },
    };
  }

  async getResidentEmar(residentId: string, user: AuthenticatedUser) {
    this.ensureRole(
      user,
      ['NURSE', 'MANAGER'],
      medicationViewerRestrictionReason,
    );
    return this.buildResidentMedicationProfile(residentId, user);
  }

  async getResidentMedications(residentId: string, user: AuthenticatedUser) {
    const profile = await this.getResidentEmar(residentId, user);
    return {
      workflowNote: profile.workflowNote,
      resident: profile.resident,
      chart: profile.chart,
      allergies: profile.allergies,
      scheduledMedications: profile.scheduledMedications,
      prnMedications: profile.prnMedications,
    };
  }

  async getResidentMedicationEvents(
    residentId: string,
    user: AuthenticatedUser,
  ) {
    const profile = await this.getResidentEmar(residentId, user);
    return {
      workflowNote: profile.workflowNote,
      resident: profile.resident,
      recentEvents: profile.recentEvents,
    };
  }

  async getResidentMedicationReconciliations(
    residentId: string,
    user: AuthenticatedUser,
  ) {
    const profile = await this.getResidentEmar(residentId, user);
    return {
      workflowNote: profile.workflowNote,
      downtimeNotice: profile.downtimeNotice,
      downtimePackNotice: profile.downtimePackNotice,
      controlledDrugNotice: profile.controlledDrugNotice,
      resident: profile.resident,
      reconciliations: profile.reconciliations,
      operationalWorkflows: profile.operationalWorkflows,
    };
  }

  async createMedicationReconciliation(
    residentId: string,
    user: AuthenticatedUser,
    dto: CreateMedicationReconciliationDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);
    const { resident } = await this.findResidentInScope(residentId, user);
    const downtimeStartedAt = dto.downtimeStartedAt
      ? new Date(dto.downtimeStartedAt)
      : null;
    const downtimeEndedAt = dto.downtimeEndedAt
      ? new Date(dto.downtimeEndedAt)
      : null;
    if (
      downtimeStartedAt &&
      downtimeEndedAt &&
      downtimeEndedAt.getTime() < downtimeStartedAt.getTime()
    ) {
      throw new BadRequestException(
        'Downtime end must be on or after downtime start.',
      );
    }

    const reconciliation = await this.prisma.$transaction(async (tx) => {
      const created = await tx.medicationReconciliation.create({
        data: {
          residentId: resident.id,
          triggerType: dto.triggerType,
          downtimeStartedAt,
          downtimeEndedAt,
          paperRecordLocation: this.sanitizeOptionalText(
            dto.paperRecordLocation,
          ),
          notes: this.sanitizeOptionalText(dto.notes),
          createdByUserId: user.userId,
        },
      });

      await this.createMedicationTimelineEntry(tx, {
        residentId: resident.id,
        createdById: user.userId,
        title: 'Medication reconciliation opened',
        details:
          `${dto.triggerType.replace(/_/g, ' ')} reconciliation opened.` +
          (created.paperRecordLocation
            ? ` Paper record location: ${created.paperRecordLocation}.`
            : '') +
          (created.notes ? ` Notes: ${created.notes}.` : ''),
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_RECONCILIATION_STARTED',
        userId: user.userId,
        residentId: resident.id,
        details: {
          reconciliationId: created.id,
          triggerType: created.triggerType,
          downtimeStartedAt: created.downtimeStartedAt?.toISOString() ?? null,
          downtimeEndedAt: created.downtimeEndedAt?.toISOString() ?? null,
          paperRecordLocation: created.paperRecordLocation ?? null,
        },
      });

      return created;
    });

    const userNames = await this.loadUserNameMap([
      reconciliation.createdByUserId,
      reconciliation.completedByUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      downtimeNotice: medicationDowntimeNotice,
      reconciliation: this.mapMedicationReconciliation(
        reconciliation,
        userNames,
      ),
    };
  }

  async completeMedicationReconciliation(
    reconciliationId: string,
    user: AuthenticatedUser,
    dto: CompleteMedicationReconciliationDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);
    const reconciliation =
      await this.prisma.medicationReconciliation.findUnique({
        where: { id: reconciliationId },
      });
    if (!reconciliation) {
      throw new NotFoundException('Medication reconciliation was not found.');
    }
    if (reconciliation.status === MedicationReconciliationStatus.COMPLETED) {
      throw new BadRequestException(
        'Medication reconciliation has already been completed.',
      );
    }

    const { resident } = await this.findResidentInScope(
      reconciliation.residentId,
      user,
    );

    const completed = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.medicationReconciliation.update({
        where: { id: reconciliationId },
        data: {
          status: MedicationReconciliationStatus.COMPLETED,
          discrepancySummary: this.sanitizeOptionalText(dto.discrepancySummary),
          controlledDrugCheckSummary: this.sanitizeOptionalText(
            dto.controlledDrugCheckSummary,
          ),
          notes: this.sanitizeOptionalText(dto.notes) ?? reconciliation.notes,
          completedByUserId: user.userId,
          completedAt: new Date(),
        },
      });

      await this.createMedicationTimelineEntry(tx, {
        residentId: resident.id,
        createdById: user.userId,
        title: 'Medication reconciliation completed',
        details:
          `Medication reconciliation completed for ${updated.triggerType.replace(/_/g, ' ')}.` +
          (updated.discrepancySummary
            ? ` Discrepancies: ${updated.discrepancySummary}.`
            : ' No discrepancy summary recorded.') +
          (updated.controlledDrugCheckSummary
            ? ` Controlled-drug check: ${updated.controlledDrugCheckSummary}.`
            : ''),
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_RECONCILIATION_COMPLETED',
        userId: user.userId,
        residentId: resident.id,
        details: {
          reconciliationId: updated.id,
          triggerType: updated.triggerType,
          discrepancySummary: updated.discrepancySummary ?? null,
          controlledDrugCheckSummary:
            updated.controlledDrugCheckSummary ?? null,
        },
      });

      return updated;
    });

    const userNames = await this.loadUserNameMap([
      completed.createdByUserId,
      completed.completedByUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      reconciliation: this.mapMedicationReconciliation(completed, userNames),
    };
  }

  async createMedicationOrder(
    residentId: string,
    user: AuthenticatedUser,
    dto: CreateMedicationOrderDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);
    const { resident } = await this.findResidentInScope(residentId, user);

    const result = await this.prisma.$transaction(async (tx) => {
      const { chart } = await this.ensureActiveChart(
        tx,
        resident.id,
        user.userId,
      );
      const order = await tx.medicationOrder.create({
        data: {
          residentId: resident.id,
          chartId: chart.id,
          medicationName: dto.medicationName.trim(),
          formulation: this.sanitizeOptionalText(dto.formulation),
          strength: this.sanitizeOptionalText(dto.strength),
          doseAmount: dto.doseAmount.trim(),
          doseUnit: dto.doseUnit.trim(),
          route: dto.route.trim(),
          instructions: dto.instructions.trim(),
          startDate: new Date(dto.startDate),
          endDate: dto.endDate ? new Date(dto.endDate) : null,
          isControlledDrug: dto.isControlledDrug ?? false,
          requiresWitness: dto.requiresWitness ?? false,
          isPRN: dto.isPRN ?? false,
          sourceType: dto.sourceType ?? MedicationOrderSourceType.MANUAL_ENTRY,
          createdByUserId: user.userId,
          updatedByUserId: user.userId,
        },
        include: {
          schedules: true,
          prnProtocol: true,
          stockRecord: true,
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId: order.id,
          residentId: resident.id,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.CREATED,
          previousValueJson: Prisma.JsonNull,
          newValueJson: this.buildMedicationOrderSnapshot(order),
          reason:
            this.sanitizeOptionalText(dto.changeReason) ??
            'Medication order created during chart setup.',
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ORDER_CREATED',
        userId: user.userId,
        residentId: resident.id,
        medicationOrderId: order.id,
        details: {
          medicationName: order.medicationName,
          chartId: chart.id,
          isPRN: order.isPRN,
        },
      });

      return order;
    });

    const userNames = await this.loadUserNameMap([
      result.createdByUserId,
      result.updatedByUserId,
    ]);
    return {
      workflowNote: medicationWorkflowNote,
      medicationOrder: this.mapMedicationOrder(result, userNames),
    };
  }

  async updateMedicationOrder(
    medicationOrderId: string,
    user: AuthenticatedUser,
    dto: UpdateMedicationOrderDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const existing = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
      include: {
        schedules: true,
        prnProtocol: true,
        stockRecord: true,
      },
    });

    if (!existing) {
      throw new NotFoundException('Medication order was not found.');
    }

    const previousSnapshot = this.buildMedicationOrderSnapshot(existing);

    const result = await this.prisma.$transaction(async (tx) => {
      const order = await tx.medicationOrder.update({
        where: { id: medicationOrderId },
        data: {
          ...(dto.medicationName != null
            ? { medicationName: dto.medicationName.trim() }
            : {}),
          ...(dto.formulation !== undefined
            ? { formulation: this.sanitizeOptionalText(dto.formulation) }
            : {}),
          ...(dto.strength !== undefined
            ? { strength: this.sanitizeOptionalText(dto.strength) }
            : {}),
          ...(dto.doseAmount != null
            ? { doseAmount: dto.doseAmount.trim() }
            : {}),
          ...(dto.doseUnit != null ? { doseUnit: dto.doseUnit.trim() } : {}),
          ...(dto.route != null ? { route: dto.route.trim() } : {}),
          ...(dto.instructions != null
            ? { instructions: dto.instructions.trim() }
            : {}),
          ...(dto.startDate != null
            ? { startDate: new Date(dto.startDate) }
            : {}),
          ...(dto.endDate !== undefined
            ? { endDate: dto.endDate ? new Date(dto.endDate) : null }
            : {}),
          ...(dto.isControlledDrug !== undefined
            ? { isControlledDrug: dto.isControlledDrug }
            : {}),
          ...(dto.requiresWitness !== undefined
            ? { requiresWitness: dto.requiresWitness }
            : {}),
          ...(dto.isPRN !== undefined ? { isPRN: dto.isPRN } : {}),
          ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
          ...(dto.sourceType !== undefined
            ? { sourceType: dto.sourceType }
            : {}),
          updatedByUserId: user.userId,
        },
        include: {
          schedules: true,
          prnProtocol: true,
          stockRecord: true,
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId: order.id,
          residentId: order.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.UPDATED,
          previousValueJson: previousSnapshot,
          newValueJson: this.buildMedicationOrderSnapshot(order),
          reason: dto.reason.trim(),
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ORDER_UPDATED',
        userId: user.userId,
        residentId: order.residentId,
        medicationOrderId: order.id,
        details: {
          medicationName: order.medicationName,
          reason: dto.reason.trim(),
        },
      });

      await this.reconcileDoseInstancesForOrder(tx, {
        medicationOrderId: order.id,
        actedByUserId: user.userId,
        cancellationReason: `Medication order updated: ${dto.reason.trim()}`,
      });

      return order;
    });

    const userNames = await this.loadUserNameMap([
      result.createdByUserId,
      result.updatedByUserId,
    ]);
    return {
      workflowNote: medicationWorkflowNote,
      medicationOrder: this.mapMedicationOrder(result, userNames),
    };
  }

  async deactivateMedicationOrder(
    medicationOrderId: string,
    user: AuthenticatedUser,
    dto: DeactivateMedicationOrderDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const existing = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
      include: {
        schedules: true,
        prnProtocol: true,
        stockRecord: true,
      },
    });

    if (!existing) {
      throw new NotFoundException('Medication order was not found.');
    }

    const previousSnapshot = this.buildMedicationOrderSnapshot(existing);

    const now = new Date();
    const result = await this.prisma.$transaction(async (tx) => {
      const order = await tx.medicationOrder.update({
        where: { id: medicationOrderId },
        data: {
          isActive: false,
          deactivatedAt: now,
          deactivationReason: dto.reason.trim(),
          updatedByUserId: user.userId,
        },
        include: {
          schedules: true,
          prnProtocol: true,
          stockRecord: true,
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId: order.id,
          residentId: order.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.DEACTIVATED,
          previousValueJson: previousSnapshot,
          newValueJson: this.buildMedicationOrderSnapshot(order),
          reason: dto.reason.trim(),
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ORDER_DEACTIVATED',
        userId: user.userId,
        residentId: order.residentId,
        medicationOrderId: order.id,
        details: {
          medicationName: order.medicationName,
          reason: dto.reason.trim(),
        },
      });

      await this.reconcileDoseInstancesForOrder(tx, {
        medicationOrderId: order.id,
        actedByUserId: user.userId,
        cancellationReason: `Medication order deactivated: ${dto.reason.trim()}`,
        referenceTime: now,
      });

      return order;
    });

    const userNames = await this.loadUserNameMap([
      result.createdByUserId,
      result.updatedByUserId,
    ]);
    return {
      workflowNote: medicationWorkflowNote,
      medicationOrder: this.mapMedicationOrder(result, userNames),
    };
  }

  async createMedicationSchedule(
    medicationOrderId: string,
    user: AuthenticatedUser,
    dto: CreateMedicationScheduleDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const order = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
    });

    if (!order) {
      throw new NotFoundException('Medication order was not found.');
    }
    if (order.isPRN) {
      throw new BadRequestException(
        'PRN medication orders cannot have scheduled rounds.',
      );
    }

    const daysOfWeek = this.normalizeDaysOfWeek(dto.daysOfWeek);
    const fixedTimeLocal = this.normalizeFixedTimeLocal(dto.fixedTimeLocal);

    const schedule = await this.prisma.$transaction(async (tx) => {
      const created = await tx.medicationSchedule.create({
        data: {
          medicationOrderId,
          roundLabel: dto.roundLabel,
          anchorType: dto.anchorType,
          windowStartOffsetMinutes: dto.windowStartOffsetMinutes ?? null,
          windowEndOffsetMinutes: dto.windowEndOffsetMinutes ?? null,
          fixedTimeLocal,
          daysOfWeek,
          active: true,
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId,
          residentId: order.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.SCHEDULE_CHANGED,
          previousValueJson: Prisma.JsonNull,
          newValueJson: {
            scheduleId: created.id,
            roundLabel: created.roundLabel,
            anchorType: created.anchorType,
            windowStartOffsetMinutes: created.windowStartOffsetMinutes,
            windowEndOffsetMinutes: created.windowEndOffsetMinutes,
            fixedTimeLocal: created.fixedTimeLocal,
            daysOfWeek: created.daysOfWeek,
            active: created.active,
          },
          reason: 'Medication schedule recorded for the medication chart.',
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_SCHEDULE_CREATED',
        userId: user.userId,
        residentId: order.residentId,
        medicationOrderId,
        details: {
          scheduleId: created.id,
          roundLabel: created.roundLabel,
        },
      });

      return created;
    });

    return {
      workflowNote: medicationWorkflowNote,
      schedule: this.mapSchedule(schedule),
    };
  }

  async updateMedicationSchedule(
    scheduleId: string,
    user: AuthenticatedUser,
    dto: UpdateMedicationScheduleDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const existing = await this.prisma.medicationSchedule.findUnique({
      where: { id: scheduleId },
      include: {
        medicationOrder: true,
      },
    });

    if (!existing) {
      throw new NotFoundException('Medication schedule was not found.');
    }

    const daysOfWeek =
      dto.daysOfWeek !== undefined
        ? this.normalizeDaysOfWeek(dto.daysOfWeek)
        : existing.daysOfWeek;
    const fixedTimeLocal =
      dto.fixedTimeLocal !== undefined
        ? this.normalizeFixedTimeLocal(dto.fixedTimeLocal)
        : existing.fixedTimeLocal;

    const schedule = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.medicationSchedule.update({
        where: { id: scheduleId },
        data: {
          ...(dto.roundLabel !== undefined
            ? { roundLabel: dto.roundLabel }
            : {}),
          ...(dto.anchorType !== undefined
            ? { anchorType: dto.anchorType }
            : {}),
          ...(dto.windowStartOffsetMinutes !== undefined
            ? { windowStartOffsetMinutes: dto.windowStartOffsetMinutes }
            : {}),
          ...(dto.windowEndOffsetMinutes !== undefined
            ? { windowEndOffsetMinutes: dto.windowEndOffsetMinutes }
            : {}),
          ...(dto.fixedTimeLocal !== undefined ? { fixedTimeLocal } : {}),
          ...(dto.daysOfWeek !== undefined ? { daysOfWeek } : {}),
          ...(dto.active !== undefined ? { active: dto.active } : {}),
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId: existing.medicationOrderId,
          residentId: existing.medicationOrder.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.SCHEDULE_CHANGED,
          previousValueJson: {
            roundLabel: existing.roundLabel,
            anchorType: existing.anchorType,
            windowStartOffsetMinutes: existing.windowStartOffsetMinutes,
            windowEndOffsetMinutes: existing.windowEndOffsetMinutes,
            fixedTimeLocal: existing.fixedTimeLocal,
            daysOfWeek: existing.daysOfWeek,
            active: existing.active,
          },
          newValueJson: {
            roundLabel: updated.roundLabel,
            anchorType: updated.anchorType,
            windowStartOffsetMinutes: updated.windowStartOffsetMinutes,
            windowEndOffsetMinutes: updated.windowEndOffsetMinutes,
            fixedTimeLocal: updated.fixedTimeLocal,
            daysOfWeek: updated.daysOfWeek,
            active: updated.active,
          },
          reason: dto.reason.trim(),
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_SCHEDULE_UPDATED',
        userId: user.userId,
        residentId: existing.medicationOrder.residentId,
        medicationOrderId: existing.medicationOrderId,
        details: {
          scheduleId: updated.id,
          roundLabel: updated.roundLabel,
          reason: dto.reason.trim(),
        },
      });

      await this.reconcileDoseInstancesForOrder(tx, {
        medicationOrderId: existing.medicationOrderId,
        actedByUserId: user.userId,
        cancellationReason: `Medication schedule updated: ${dto.reason.trim()}`,
      });

      return updated;
    });

    return {
      workflowNote: medicationWorkflowNote,
      schedule: this.mapSchedule(schedule),
    };
  }

  async deactivateMedicationSchedule(
    scheduleId: string,
    user: AuthenticatedUser,
    dto: DeactivateMedicationScheduleDto,
  ) {
    return this.updateMedicationSchedule(scheduleId, user, {
      active: false,
      reason: dto.reason,
    });
  }

  async createPrnProtocol(
    medicationOrderId: string,
    user: AuthenticatedUser,
    dto: CreatePrnProtocolDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const order = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
    });

    if (!order) {
      throw new NotFoundException('Medication order was not found.');
    }
    if (!order.isPRN) {
      throw new BadRequestException(
        'Only PRN medication orders can have PRN protocols.',
      );
    }

    const protocol = await this.prisma.$transaction(async (tx) => {
      const created = await tx.pRNProtocol.upsert({
        where: {
          medicationOrderId,
        },
        update: {
          indication: dto.indication.trim(),
          whenToOffer: dto.whenToOffer.trim(),
          doseInstructions: dto.doseInstructions.trim(),
          minimumIntervalMinutes: dto.minimumIntervalMinutes ?? null,
          maxDosePer24Hours: dto.maxDosePer24Hours ?? null,
          expectedEffect: this.sanitizeOptionalText(dto.expectedEffect),
          monitoringRequired: this.sanitizeOptionalText(dto.monitoringRequired),
          whenToEscalate: this.sanitizeOptionalText(dto.whenToEscalate),
          active: true,
        },
        create: {
          residentId: order.residentId,
          medicationOrderId,
          indication: dto.indication.trim(),
          whenToOffer: dto.whenToOffer.trim(),
          doseInstructions: dto.doseInstructions.trim(),
          minimumIntervalMinutes: dto.minimumIntervalMinutes ?? null,
          maxDosePer24Hours: dto.maxDosePer24Hours ?? null,
          expectedEffect: this.sanitizeOptionalText(dto.expectedEffect),
          monitoringRequired: this.sanitizeOptionalText(dto.monitoringRequired),
          whenToEscalate: this.sanitizeOptionalText(dto.whenToEscalate),
          active: true,
          createdByUserId: user.userId,
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId,
          residentId: order.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.PRN_PROTOCOL_CHANGED,
          previousValueJson: Prisma.JsonNull,
          newValueJson: {
            indication: created.indication,
            whenToOffer: created.whenToOffer,
            doseInstructions: created.doseInstructions,
            minimumIntervalMinutes: created.minimumIntervalMinutes,
            maxDosePer24Hours: created.maxDosePer24Hours,
            expectedEffect: created.expectedEffect,
            monitoringRequired: created.monitoringRequired,
            whenToEscalate: created.whenToEscalate,
            active: created.active,
          },
          reason: 'PRN protocol recorded for the medication chart.',
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ORDER_UPDATED',
        userId: user.userId,
        residentId: order.residentId,
        medicationOrderId,
        details: {
          medicationName: order.medicationName,
          changeType: 'PRN_PROTOCOL_CREATED',
        },
      });

      return created;
    });

    return {
      workflowNote: medicationWorkflowNote,
      prnProtocol: this.mapPrnProtocol(protocol),
    };
  }

  async updatePrnProtocol(
    prnProtocolId: string,
    user: AuthenticatedUser,
    dto: UpdatePrnProtocolDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);

    const existing = await this.prisma.pRNProtocol.findUnique({
      where: { id: prnProtocolId },
      include: {
        medicationOrder: true,
      },
    });

    if (!existing) {
      throw new NotFoundException('PRN protocol was not found.');
    }

    const protocol = await this.prisma.$transaction(async (tx) => {
      const updated = await tx.pRNProtocol.update({
        where: { id: prnProtocolId },
        data: {
          ...(dto.indication !== undefined
            ? { indication: dto.indication.trim() }
            : {}),
          ...(dto.whenToOffer !== undefined
            ? { whenToOffer: dto.whenToOffer.trim() }
            : {}),
          ...(dto.doseInstructions !== undefined
            ? { doseInstructions: dto.doseInstructions.trim() }
            : {}),
          ...(dto.minimumIntervalMinutes !== undefined
            ? { minimumIntervalMinutes: dto.minimumIntervalMinutes }
            : {}),
          ...(dto.maxDosePer24Hours !== undefined
            ? { maxDosePer24Hours: dto.maxDosePer24Hours }
            : {}),
          ...(dto.expectedEffect !== undefined
            ? { expectedEffect: this.sanitizeOptionalText(dto.expectedEffect) }
            : {}),
          ...(dto.monitoringRequired !== undefined
            ? {
                monitoringRequired: this.sanitizeOptionalText(
                  dto.monitoringRequired,
                ),
              }
            : {}),
          ...(dto.whenToEscalate !== undefined
            ? { whenToEscalate: this.sanitizeOptionalText(dto.whenToEscalate) }
            : {}),
          ...(dto.active !== undefined ? { active: dto.active } : {}),
        },
      });

      await tx.medicationChangeLog.create({
        data: {
          medicationOrderId: existing.medicationOrderId,
          residentId: existing.residentId,
          changedByUserId: user.userId,
          changeType: MedicationChangeType.PRN_PROTOCOL_CHANGED,
          previousValueJson: {
            indication: existing.indication,
            whenToOffer: existing.whenToOffer,
            doseInstructions: existing.doseInstructions,
            minimumIntervalMinutes: existing.minimumIntervalMinutes,
            maxDosePer24Hours: existing.maxDosePer24Hours,
            expectedEffect: existing.expectedEffect,
            monitoringRequired: existing.monitoringRequired,
            whenToEscalate: existing.whenToEscalate,
            active: existing.active,
          },
          newValueJson: {
            indication: updated.indication,
            whenToOffer: updated.whenToOffer,
            doseInstructions: updated.doseInstructions,
            minimumIntervalMinutes: updated.minimumIntervalMinutes,
            maxDosePer24Hours: updated.maxDosePer24Hours,
            expectedEffect: updated.expectedEffect,
            monitoringRequired: updated.monitoringRequired,
            whenToEscalate: updated.whenToEscalate,
            active: updated.active,
          },
          reason: dto.reason.trim(),
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ORDER_UPDATED',
        userId: user.userId,
        residentId: existing.residentId,
        medicationOrderId: existing.medicationOrderId,
        details: {
          medicationName: existing.medicationOrder.medicationName,
          changeType: 'PRN_PROTOCOL_UPDATED',
          reason: dto.reason.trim(),
        },
      });

      return updated;
    });

    return {
      workflowNote: medicationWorkflowNote,
      prnProtocol: this.mapPrnProtocol(protocol),
    };
  }

  async recordMedicationAllergy(
    residentId: string,
    user: AuthenticatedUser,
    dto: CreateMedicationAllergyDto,
  ) {
    this.ensureRole(user, ['MANAGER'], medicationManagementRestrictionReason);
    const { resident } = await this.findResidentInScope(residentId, user);

    const allergy = await this.prisma.$transaction(async (tx) => {
      const created = await tx.medicationAllergyIntolerance.create({
        data: {
          residentId: resident.id,
          substance: dto.substance.trim(),
          reaction: this.sanitizeOptionalText(dto.reaction),
          severity: this.sanitizeOptionalText(dto.severity),
          recordedByUserId: user.userId,
        },
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_ALLERGY_RECORDED',
        userId: user.userId,
        residentId: resident.id,
        details: {
          substance: created.substance,
          severity: created.severity,
        },
      });

      return created;
    });

    const userNames = await this.loadUserNameMap([allergy.recordedByUserId]);
    return {
      workflowNote: medicationWorkflowNote,
      allergy: {
        id: allergy.id,
        substance: allergy.substance,
        reaction: allergy.reaction,
        severity: allergy.severity,
        recordedByUserId: allergy.recordedByUserId,
        recordedByUserName: userNames.get(allergy.recordedByUserId) ?? null,
        createdAt: allergy.createdAt,
        updatedAt: allergy.updatedAt,
      },
    };
  }

  async generateMedicationRound(shiftId: string, user: AuthenticatedUser) {
    this.ensureRole(
      user,
      ['NURSE', 'MANAGER'],
      medicationViewerRestrictionReason,
    );
    const shift = await this.resolveShiftAccess(shiftId, user);
    const handoverAcknowledgedAt =
      this.getEarliestHandoverAcknowledgement(shift);

    const orders = await this.prisma.medicationOrder.findMany({
      where: {
        isActive: true,
        isPRN: false,
        resident: {
          floorNumber: shift.floorNumber,
          isActive: true,
        },
      },
      include: {
        resident: {
          select: {
            id: true,
            fullName: true,
            roomLabel: true,
            floorNumber: true,
            unitLabel: true,
          },
        },
        schedules: {
          where: {
            active: true,
          },
          orderBy: {
            createdAt: 'asc',
          },
        },
      },
      orderBy: [{ medicationName: 'asc' }],
    });

    const createdInstances = [] as string[];
    for (const order of orders) {
      for (const schedule of order.schedules) {
        const dueWindow = this.resolveDueWindow({
          anchorType: schedule.anchorType,
          shiftStartsAt: shift.startsAt,
          shiftEndsAt: shift.endsAt,
          handoverAcknowledgedAt,
          fixedTimeLocal: schedule.fixedTimeLocal,
          windowStartOffsetMinutes: schedule.windowStartOffsetMinutes,
          windowEndOffsetMinutes: schedule.windowEndOffsetMinutes,
        });

        if (!dueWindow) {
          continue;
        }

        if (
          !this.isOccurrenceWithinShift({
            shiftStartsAt: shift.startsAt,
            shiftEndsAt: shift.endsAt,
            occurrenceAt: dueWindow.scheduledAt,
          })
        ) {
          continue;
        }

        if (
          !this.appliesOnOccurrenceDate(
            schedule.daysOfWeek,
            dueWindow.scheduledAt,
          )
        ) {
          continue;
        }

        if (!this.isOrderActiveOnOccurrenceDate(order, dueWindow.scheduledAt)) {
          continue;
        }

        const existing = await this.prisma.medicationDoseInstance.findUnique({
          where: {
            shiftId_scheduleId: {
              shiftId: shift.id,
              scheduleId: schedule.id,
            },
          },
        });

        if (existing) {
          if (mutableDoseStatuses.has(existing.status)) {
            const refreshedStatus =
              dueWindow.dueWindowEnd.getTime() < Date.now()
                ? MedicationDoseStatus.OVERDUE
                : MedicationDoseStatus.DUE;
            await this.prisma.medicationDoseInstance.update({
              where: {
                id: existing.id,
              },
              data: {
                dueWindowStart: dueWindow.dueWindowStart,
                dueWindowEnd: dueWindow.dueWindowEnd,
                status: refreshedStatus,
                requiresWitness: order.requiresWitness,
                recordedByUserId: null,
                recordedAt: null,
                reason: null,
                notes: null,
                witnessUserId: null,
              },
            });
          }
          continue;
        }

        const created = await this.prisma.$transaction(async (tx) => {
          const doseInstance = await tx.medicationDoseInstance.create({
            data: {
              residentId: order.residentId,
              medicationOrderId: order.id,
              scheduleId: schedule.id,
              shiftId: shift.id,
              dueWindowStart: dueWindow.dueWindowStart,
              dueWindowEnd: dueWindow.dueWindowEnd,
              status:
                dueWindow.dueWindowEnd.getTime() < Date.now()
                  ? MedicationDoseStatus.OVERDUE
                  : MedicationDoseStatus.DUE,
              generatedAt: new Date(),
              requiresWitness: order.requiresWitness,
            },
          });

          await this.createAuditEvent(tx, {
            kind: 'MEDICATION_DOSE_INSTANCE_GENERATED',
            userId: user.userId,
            shiftId: shift.id,
            residentId: order.residentId,
            medicationOrderId: order.id,
            medicationDoseInstanceId: doseInstance.id,
            details: {
              medicationName: order.medicationName,
              roundLabel: schedule.roundLabel,
              dueWindowStart: dueWindow.dueWindowStart.toISOString(),
              dueWindowEnd: dueWindow.dueWindowEnd.toISOString(),
            },
          });

          return doseInstance;
        });

        createdInstances.push(created.id);
      }
    }

    await this.syncOverdueDoseInstances(shift.id);

    return {
      workflowNote: medicationWorkflowNote,
      shift: {
        id: shift.id,
        name: shift.name,
        floorNumber: shift.floorNumber,
        unitLabel: shift.unitLabel,
        startsAt: shift.startsAt,
        endsAt: shift.endsAt,
        handoverAcknowledged: handoverAcknowledgedAt != null,
        handoverAcknowledgedAt,
      },
      generatedCount: createdInstances.length,
      generatedDoseInstanceIds: createdInstances,
    };
  }

  async getMedicationRound(shiftId: string, user: AuthenticatedUser) {
    this.ensureRole(
      user,
      ['NURSE', 'MANAGER'],
      medicationViewerRestrictionReason,
    );
    const shift = await this.resolveShiftAccess(shiftId, user);
    const userAcknowledgedAt = this.ensureHandoverAcknowledged(shift, user);

    await this.generateMedicationRound(shiftId, user);
    await this.syncOverdueDoseInstances(shift.id);

    const [doseInstances, allergies, witnessCandidates] = await Promise.all([
      this.prisma.medicationDoseInstance.findMany({
        where: {
          shiftId: shift.id,
          status: {
            not: MedicationDoseStatus.CANCELLED,
          },
        },
        include: {
          medicationOrder: {
            include: {
              resident: {
                select: {
                  id: true,
                  fullName: true,
                  roomLabel: true,
                  floorNumber: true,
                  unitLabel: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              roundLabel: true,
              anchorType: true,
            },
          },
        },
        orderBy: [
          { dueWindowStart: 'asc' },
          { medicationOrder: { resident: { roomLabel: 'asc' } } },
          { medicationOrder: { medicationName: 'asc' } },
        ],
      }),
      this.prisma.medicationAllergyIntolerance.findMany({
        where: {
          resident: {
            floorNumber: shift.floorNumber,
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      }),
      this.prisma.shift.findUnique({
        where: {
          id: shift.id,
        },
        select: {
          assignedUsers: {
            select: {
              id: true,
              displayName: true,
              role: {
                select: {
                  key: true,
                },
              },
            },
            orderBy: {
              displayName: 'asc',
            },
          },
        },
      }),
    ]);

    const userNames = await this.loadUserNameMap(
      doseInstances.flatMap((entry) => [
        entry.recordedByUserId,
        entry.witnessUserId,
      ]),
    );
    const allergiesByResidentId = new Map<string, MedicationAllergySnapshot[]>();
    for (const allergy of allergies) {
      const current = allergiesByResidentId.get(allergy.residentId) ?? [];
      current.push({
        id: allergy.id,
        substance: allergy.substance,
        reaction: allergy.reaction,
        severity: allergy.severity,
      });
      allergiesByResidentId.set(allergy.residentId, current);
    }

    const groupedRounds = new Map<string, MedicationDoseInstanceView[]>();
    for (const instance of doseInstances) {
      const roundKey = instance.schedule.roundLabel;
      const mapped = this.mapDoseInstance(
        instance,
        userNames,
        allergiesByResidentId,
      );
      const entries = groupedRounds.get(roundKey) ?? [];
      entries.push(mapped);
      groupedRounds.set(roundKey, entries);
    }

    return {
      workflowNote: medicationWorkflowNote,
      safetyBanner: medicationSafetyBanner,
      shift: {
        id: shift.id,
        name: shift.name,
        floorNumber: shift.floorNumber,
        unitLabel: shift.unitLabel,
        startsAt: shift.startsAt,
        endsAt: shift.endsAt,
        handoverAcknowledged:
          user.role === 'MANAGER'
            ? this.getEarliestHandoverAcknowledgement(shift) != null
            : userAcknowledgedAt != null,
        handoverAcknowledgedAt:
          user.role === 'MANAGER'
            ? this.getEarliestHandoverAcknowledgement(shift)
            : userAcknowledgedAt,
      },
      witnessCandidates:
        witnessCandidates?.assignedUsers
          .filter(
            (candidate) =>
              ['NURSE', 'MANAGER'].includes(candidate.role.key) &&
              candidate.id != user.userId,
          )
          .map((candidate) => ({
            id: candidate.id,
            displayName: candidate.displayName,
            role: candidate.role.key,
          })) ?? [],
      groupedRounds: Array.from(groupedRounds.entries()).map(
        ([roundLabel, items]): MedicationRoundGroup => ({
          roundLabel,
          items,
        }),
      ),
    };
  }

  private async createAutomaticAdministrationStockTransaction(
    tx: Prisma.TransactionClient,
    args: {
      medicationOrderId: string;
      residentId: string;
      recordedByUserId: string;
      witnessUserId?: string | null;
      quantity?: string | null;
      quantityUnit?: string | null;
    },
  ) {
    const stockRecord = await tx.medicationStockRecord.findUnique({
      where: {
        medicationOrderId: args.medicationOrderId,
      },
    });

    if (!stockRecord) {
      return null;
    }

    const quantity = args.quantity ?? '1';
    const updatedStockRecord = await tx.medicationStockRecord.update({
      where: {
        id: stockRecord.id,
      },
      data: {
        currentQuantity: this.applyStockTransactionBalance(
          stockRecord.currentQuantity,
          MedicationStockTransactionType.ADMINISTERED,
          quantity,
        ),
        quantityUnit: args.quantityUnit ?? stockRecord.quantityUnit,
        lastCheckedByUserId: args.recordedByUserId,
        lastCheckedAt: new Date(),
      },
    });

    return tx.medicationStockTransaction.create({
      data: {
        stockRecordId: updatedStockRecord.id,
        residentId: args.residentId,
        medicationOrderId: args.medicationOrderId,
        transactionType: MedicationStockTransactionType.ADMINISTERED,
        quantity,
        quantityUnit: args.quantityUnit ?? stockRecord.quantityUnit,
        recordedByUserId: args.recordedByUserId,
        witnessUserId: args.witnessUserId ?? null,
        reason: 'Created automatically from administered medication event.',
      },
    });
  }

  private async recordDoseOutcome(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
    outcome: MedicationDoseStatus,
    eventType: MedicationAdministrationEventType,
    auditKind: AuditEventKind,
  ) {
    this.ensureRole(user, ['NURSE'], medicationRecordingRestrictionReason);

    const doseInstance = await this.prisma.medicationDoseInstance.findUnique({
      where: { id: doseInstanceId },
      include: {
        medicationOrder: {
          include: {
            resident: {
              select: {
                id: true,
                fullName: true,
                roomLabel: true,
                floorNumber: true,
                unitLabel: true,
              },
            },
          },
        },
        schedule: {
          select: {
            roundLabel: true,
          },
        },
      },
    });

    if (!doseInstance) {
      throw new NotFoundException('Medication dose instance was not found.');
    }

    const shift = await this.resolveShiftAccess(doseInstance.shiftId, user, {
      allowManagerOverride: false,
    });
    this.ensureHandoverAcknowledged(shift, user);

    const actionableStatuses: MedicationDoseStatus[] = [
      MedicationDoseStatus.DUE,
      MedicationDoseStatus.OVERDUE,
    ];

    if (!actionableStatuses.includes(doseInstance.status)) {
      throw new BadRequestException(
        'A final medication outcome has already been recorded for this dose instance.',
      );
    }

    const reason = reasonRequiredStatuses.has(outcome)
      ? this.requireReason(
          dto.reason,
          'A reason is required for this medication outcome.',
        )
      : this.sanitizeOptionalText(dto.reason);
    const notes = this.sanitizeOptionalText(dto.notes);
    const witness = await this.ensureWitnessUser(
      dto.witnessUserId ?? null,
      user.userId,
    );

    if (doseInstance.requiresWitness && !witness) {
      throw new BadRequestException(
        'Witness confirmation is required for this medication before submission.',
      );
    }

    const actorName = user.displayName;
    const recordedAt = new Date();

    const result = await this.prisma.$transaction(async (tx) => {
      const updatedDoseInstance = await tx.medicationDoseInstance.update({
        where: { id: doseInstanceId },
        data: {
          status: outcome,
          recordedByUserId: user.userId,
          recordedAt,
          reason,
          notes,
          witnessUserId: witness?.id ?? null,
        },
        include: {
          medicationOrder: {
            include: {
              resident: {
                select: {
                  id: true,
                  fullName: true,
                  roomLabel: true,
                  floorNumber: true,
                  unitLabel: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              roundLabel: true,
              anchorType: true,
            },
          },
        },
      });

      const administrationEvent = await tx.medicationAdministrationEvent.create(
        {
          data: {
            doseInstanceId: doseInstanceId,
            residentId: updatedDoseInstance.residentId,
            medicationOrderId: updatedDoseInstance.medicationOrderId,
            shiftId: updatedDoseInstance.shiftId,
            eventType,
            doseGiven: this.sanitizeOptionalText(dto.doseGiven),
            doseUnit:
              this.sanitizeOptionalText(dto.doseUnit) ??
              updatedDoseInstance.medicationOrder.doseUnit,
            reason,
            notes,
            recordedByUserId: user.userId,
            recordedAt,
            witnessUserId: witness?.id ?? null,
          },
          include: {
            medicationOrder: {
              select: {
                medicationName: true,
                strength: true,
                formulation: true,
              },
            },
            resident: {
              select: {
                fullName: true,
                roomLabel: true,
              },
            },
          },
        },
      );

      if (eventType === MedicationAdministrationEventType.ADMINISTERED) {
        await this.createAutomaticAdministrationStockTransaction(tx, {
          medicationOrderId: updatedDoseInstance.medicationOrderId,
          residentId: updatedDoseInstance.residentId,
          recordedByUserId: user.userId,
          witnessUserId: witness?.id ?? null,
          quantity: this.sanitizeOptionalText(dto.doseGiven),
          quantityUnit: this.sanitizeOptionalText(dto.doseUnit),
        });
      }

      await this.createMedicationTimelineEntry(tx, {
        residentId: updatedDoseInstance.residentId,
        shiftId: updatedDoseInstance.shiftId,
        createdById: user.userId,
        title: `${updatedDoseInstance.medicationOrder.medicationName} ${eventType.toLowerCase().replace(/_/g, ' ')}`,
        details: this.buildTimelineDetails({
          eventType,
          medicationName: updatedDoseInstance.medicationOrder.medicationName,
          strength: updatedDoseInstance.medicationOrder.strength,
          actorName,
          roundLabel: updatedDoseInstance.schedule.roundLabel,
          reason,
        }),
      });

      await this.createAuditEvent(tx, {
        kind: auditKind,
        userId: user.userId,
        shiftId: updatedDoseInstance.shiftId,
        residentId: updatedDoseInstance.residentId,
        medicationOrderId: updatedDoseInstance.medicationOrderId,
        medicationDoseInstanceId: updatedDoseInstance.id,
        details: {
          medicationName: updatedDoseInstance.medicationOrder.medicationName,
          eventType,
          reason,
          witnessUserId: witness?.id ?? null,
        },
      });

      return {
        updatedDoseInstance,
        administrationEvent,
      };
    });

    this.managerDashboardStream.publishShiftUpdate(
      shift.id,
      'medication-updated',
    );

    const userNames = await this.loadUserNameMap([
      result.updatedDoseInstance.recordedByUserId,
      result.updatedDoseInstance.witnessUserId,
      result.administrationEvent.recordedByUserId,
      result.administrationEvent.witnessUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      safetyBanner: medicationSafetyBanner,
      doseInstance: this.mapDoseInstance(result.updatedDoseInstance, userNames),
      administrationEvent: this.mapAdministrationEvent(
        result.administrationEvent,
        userNames,
      ),
    };
  }

  async updateDoseInstanceStatus(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: UpdateDoseStatusDto,
  ) {
    switch (dto.status) {
      case MedicationDoseStatus.ADMINISTERED:
        return this.administerDose(doseInstanceId, user, dto);
      case MedicationDoseStatus.REFUSED:
        return this.refuseDose(doseInstanceId, user, dto);
      case MedicationDoseStatus.OMITTED:
        return this.omitDose(doseInstanceId, user, dto);
      case MedicationDoseStatus.DELAYED:
        return this.delayDose(doseInstanceId, user, dto);
      case MedicationDoseStatus.NOT_AVAILABLE:
        return this.markDoseNotAvailable(doseInstanceId, user, dto);
      case MedicationDoseStatus.HELD:
        return this.holdDose(doseInstanceId, user, dto);
      default:
        throw new BadRequestException(
          'Only final medication recording outcomes are supported by this endpoint.',
        );
    }
  }

  async administerDose(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.ADMINISTERED,
      MedicationAdministrationEventType.ADMINISTERED,
      'MEDICATION_DOSE_ADMINISTERED',
    );
  }

  async refuseDose(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.REFUSED,
      MedicationAdministrationEventType.REFUSED,
      'MEDICATION_DOSE_REFUSED',
    );
  }

  async omitDose(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.OMITTED,
      MedicationAdministrationEventType.OMITTED,
      'MEDICATION_DOSE_OMITTED',
    );
  }

  async delayDose(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.DELAYED,
      MedicationAdministrationEventType.DELAYED,
      'MEDICATION_DOSE_DELAYED',
    );
  }

  async markDoseNotAvailable(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.NOT_AVAILABLE,
      MedicationAdministrationEventType.NOT_AVAILABLE,
      'MEDICATION_DOSE_NOT_AVAILABLE',
    );
  }

  async holdDose(
    doseInstanceId: string,
    user: AuthenticatedUser,
    dto: RecordDoseOutcomeDto,
  ) {
    return this.recordDoseOutcome(
      doseInstanceId,
      user,
      dto,
      MedicationDoseStatus.HELD,
      MedicationAdministrationEventType.HELD,
      'MEDICATION_DOSE_HELD',
    );
  }

  async recordPrnEvent(
    residentId: string,
    user: AuthenticatedUser,
    dto: CreatePrnEventDto,
  ) {
    this.ensureRole(user, ['NURSE'], medicationRecordingRestrictionReason);
    if (!prnEventTypes.has(dto.eventType)) {
      throw new BadRequestException(
        'PRN event recording only supports PRN offered, administered, refused or not-given outcomes.',
      );
    }

    const { resident, shift } = await this.findResidentInScope(
      residentId,
      user,
    );
    if (!shift) {
      throw new BadRequestException(
        'PRN medication recording requires an active shift.',
      );
    }
    this.ensureHandoverAcknowledged(shift, user);

    const order = await this.prisma.medicationOrder.findFirst({
      where: {
        id: dto.medicationOrderId,
        residentId: resident.id,
        isPRN: true,
        isActive: true,
      },
      include: {
        prnProtocol: true,
      },
    });

    if (!order) {
      throw new NotFoundException(
        'The requested PRN medication order was not found.',
      );
    }

    const witness = await this.ensureWitnessUser(
      dto.witnessUserId ?? null,
      user.userId,
    );
    if (order.requiresWitness && !witness) {
      throw new BadRequestException(
        'Witness confirmation is required for this PRN medication before submission.',
      );
    }

    const reason = this.requireReason(
      dto.reason,
      'A reason or symptom summary is required for PRN medication recording.',
    );
    const recordedAt = new Date();

    const lastPrnAdministration = order.prnProtocol?.minimumIntervalMinutes
      ? await this.prisma.medicationAdministrationEvent.findFirst({
          where: {
            residentId: resident.id,
            medicationOrderId: order.id,
            eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
          },
          orderBy: {
            recordedAt: 'desc',
          },
        })
      : null;
    const recentPrnAdministrationCount =
      dto.eventType === MedicationAdministrationEventType.PRN_ADMINISTERED &&
      order.prnProtocol?.maxDosePer24Hours != null
        ? await this.prisma.medicationAdministrationEvent.count({
            where: {
              residentId: resident.id,
              medicationOrderId: order.id,
              eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
              recordedAt: {
                gte: new Date(recordedAt.getTime() - 24 * 60 * 60 * 1000),
              },
            },
          })
        : null;

    if (
      dto.eventType === MedicationAdministrationEventType.PRN_ADMINISTERED &&
      order.prnProtocol?.minimumIntervalMinutes != null &&
      lastPrnAdministration != null
    ) {
      const elapsedMinutes =
        (recordedAt.getTime() - lastPrnAdministration.recordedAt.getTime()) /
        (60 * 1000);
      if (elapsedMinutes < order.prnProtocol.minimumIntervalMinutes) {
        throw new BadRequestException(
          `This PRN cannot be administered yet. Minimum interval is ${order.prnProtocol.minimumIntervalMinutes} minutes; last administration was recorded at ${lastPrnAdministration.recordedAt.toISOString()}.`,
        );
      }
    }

    if (
      dto.eventType === MedicationAdministrationEventType.PRN_ADMINISTERED &&
      recentPrnAdministrationCount != null &&
      order.prnProtocol?.maxDosePer24Hours != null &&
      recentPrnAdministrationCount >= order.prnProtocol.maxDosePer24Hours
    ) {
      throw new BadRequestException(
        `This PRN has already reached the configured 24-hour limit of ${order.prnProtocol.maxDosePer24Hours} administrations.`,
      );
    }

    const warningParts = [
      order.prnProtocol?.minimumIntervalMinutes != null &&
      lastPrnAdministration != null
        ? `${prnConfirmationWarningPrefix} This PRN was last recorded at ${lastPrnAdministration.recordedAt.toISOString()}.`
        : order.prnProtocol?.minimumIntervalMinutes != null
          ? prnConfirmationWarningPrefix
          : null,
      recentPrnAdministrationCount != null &&
      order.prnProtocol?.maxDosePer24Hours != null
        ? (() => {
            const nextAdministrationCount = recentPrnAdministrationCount + 1;
            if (nextAdministrationCount > order.prnProtocol.maxDosePer24Hours) {
              return `This PRN would become administration ${nextAdministrationCount} in the last 24 hours, above the configured limit of ${order.prnProtocol.maxDosePer24Hours}.`;
            }
            if (
              nextAdministrationCount === order.prnProtocol.maxDosePer24Hours
            ) {
              return `This PRN reaches the configured 24-hour limit of ${order.prnProtocol.maxDosePer24Hours}.`;
            }
            return null;
          })()
        : null,
    ].filter((value): value is string => value != null && value.length > 0);
    const warning = warningParts.length > 0 ? warningParts.join(' ') : null;

    const administrationEvent = await this.prisma.$transaction(async (tx) => {
      const created = await tx.medicationAdministrationEvent.create({
        data: {
          residentId: resident.id,
          medicationOrderId: order.id,
          shiftId: shift.id,
          eventType: dto.eventType,
          doseGiven: this.sanitizeOptionalText(dto.doseGiven),
          doseUnit: this.sanitizeOptionalText(dto.doseUnit) ?? order.doseUnit,
          reason,
          notes: this.sanitizeOptionalText(dto.notes),
          recordedByUserId: user.userId,
          recordedAt,
          witnessUserId: witness?.id ?? null,
        },
        include: {
          medicationOrder: {
            select: {
              medicationName: true,
              strength: true,
              formulation: true,
            },
          },
          resident: {
            select: {
              fullName: true,
              roomLabel: true,
            },
          },
        },
      });

      if (
        dto.eventType === MedicationAdministrationEventType.PRN_ADMINISTERED
      ) {
        await this.createAutomaticAdministrationStockTransaction(tx, {
          medicationOrderId: order.id,
          residentId: resident.id,
          recordedByUserId: user.userId,
          witnessUserId: witness?.id ?? null,
          quantity: this.sanitizeOptionalText(dto.doseGiven),
          quantityUnit: this.sanitizeOptionalText(dto.doseUnit),
        });
      }

      await this.createMedicationTimelineEntry(tx, {
        residentId: resident.id,
        shiftId: shift.id,
        createdById: user.userId,
        title: `${order.medicationName} ${dto.eventType.toLowerCase().replace(/_/g, ' ')}`,
        details: this.buildTimelineDetails({
          eventType: dto.eventType,
          medicationName: order.medicationName,
          strength: order.strength,
          actorName: user.displayName,
          reason,
        }),
      });

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_PRN_EVENT_RECORDED',
        userId: user.userId,
        shiftId: shift.id,
        residentId: resident.id,
        medicationOrderId: order.id,
        details: {
          medicationName: order.medicationName,
          eventType: dto.eventType,
          reason,
          warning,
        },
      });

      return created;
    });

    this.managerDashboardStream.publishShiftUpdate(
      shift.id,
      'medication-updated',
    );

    const userNames = await this.loadUserNameMap([
      administrationEvent.recordedByUserId,
      administrationEvent.witnessUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      warning,
      administrationEvent: this.mapAdministrationEvent(
        administrationEvent,
        userNames,
      ),
    };
  }

  async getMedicationStock(medicationOrderId: string, user: AuthenticatedUser) {
    this.ensureRole(
      user,
      ['NURSE', 'MANAGER'],
      medicationViewerRestrictionReason,
    );
    const stockRecord = await this.prisma.medicationStockRecord.findUnique({
      where: {
        medicationOrderId,
      },
    });

    if (!stockRecord) {
      throw new NotFoundException('Medication stock record was not found.');
    }

    const order = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
    });
    if (!order) {
      throw new NotFoundException('Medication order was not found.');
    }

    await this.findResidentInScope(order.residentId, user);
    const userNames = await this.loadUserNameMap([
      stockRecord.lastCheckedByUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      controlledDrugNotice: medicationControlledDrugNotice,
      stock: this.mapStockRecord(stockRecord, userNames),
      controlledDrugWorkflow: {
        isControlledDrug: order.isControlledDrug,
        witnessRequiredForManualTransactions:
          order.isControlledDrug || order.requiresWitness,
        witnessRequiredTransactionTypes: Array.from(
          controlledDrugWitnessTransactionTypes,
        ),
        reasonRequiredTransactionTypes: Array.from(
          controlledDrugReasonTransactionTypes,
        ),
      },
    };
  }

  async createStockTransaction(
    medicationOrderId: string,
    user: AuthenticatedUser,
    dto: CreateMedicationStockTransactionDto,
  ) {
    this.ensureRole(
      user,
      ['NURSE', 'MANAGER'],
      medicationViewerRestrictionReason,
    );

    const order = await this.prisma.medicationOrder.findUnique({
      where: { id: medicationOrderId },
    });
    if (!order) {
      throw new NotFoundException('Medication order was not found.');
    }

    await this.findResidentInScope(order.residentId, user);
    const reason = this.sanitizeOptionalText(dto.reason);
    const witness = await this.ensureWitnessUser(
      dto.witnessUserId ?? null,
      user.userId,
    );
    if (
      (order.requiresWitness ||
        (order.isControlledDrug &&
          controlledDrugWitnessTransactionTypes.has(dto.transactionType))) &&
      !witness
    ) {
      throw new BadRequestException(
        'Witness confirmation is required for this stock transaction.',
      );
    }
    if (
      order.isControlledDrug &&
      controlledDrugReasonTransactionTypes.has(dto.transactionType) &&
      !reason
    ) {
      throw new BadRequestException(
        'A reason is required when recording controlled-drug returns, disposals or stock adjustments.',
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      const existingStockRecord = await tx.medicationStockRecord.findUnique({
        where: {
          medicationOrderId,
        },
      });
      const nextQuantity = this.applyStockTransactionBalance(
        existingStockRecord?.currentQuantity,
        dto.transactionType,
        dto.quantity,
      );
      const stockRecord = await tx.medicationStockRecord.upsert({
        where: {
          medicationOrderId,
        },
        update: {
          currentQuantity: nextQuantity,
          quantityUnit: dto.quantityUnit,
          lastCheckedByUserId: user.userId,
          lastCheckedAt: new Date(),
          notes: reason,
        },
        create: {
          residentId: order.residentId,
          medicationOrderId,
          currentQuantity: nextQuantity,
          quantityUnit: dto.quantityUnit,
          lastCheckedByUserId: user.userId,
          lastCheckedAt: new Date(),
          notes: reason,
        },
      });

      const transaction = await tx.medicationStockTransaction.create({
        data: {
          stockRecordId: stockRecord.id,
          residentId: order.residentId,
          medicationOrderId,
          transactionType: dto.transactionType,
          quantity: dto.quantity,
          quantityUnit: dto.quantityUnit,
          recordedByUserId: user.userId,
          witnessUserId: witness?.id ?? null,
          reason,
        },
      });

      if (order.isControlledDrug) {
        const witnessLabel = witness?.displayName
          ? ` Witnessed by ${witness.displayName}.`
          : '';
        const reasonLabel = reason ? ` Reason: ${reason}.` : '';
        await this.createMedicationTimelineEntry(tx, {
          residentId: order.residentId,
          createdById: user.userId,
          title: `Controlled drug stock ${dto.transactionType.toLowerCase()}`,
          details:
            `Controlled drug stock transaction recorded: ${dto.transactionType} ${dto.quantity} ${dto.quantityUnit}.` +
            witnessLabel +
            reasonLabel,
        });
      }

      await this.createAuditEvent(tx, {
        kind: 'MEDICATION_STOCK_TRANSACTION_RECORDED',
        userId: user.userId,
        residentId: order.residentId,
        medicationOrderId,
        details: {
          transactionType: dto.transactionType,
          quantity: dto.quantity,
          quantityUnit: dto.quantityUnit,
        },
      });

      return {
        stockRecord,
        transaction,
      };
    });

    const userNames = await this.loadUserNameMap([
      result.stockRecord.lastCheckedByUserId,
      result.transaction.recordedByUserId,
      result.transaction.witnessUserId,
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      controlledDrugNotice: medicationControlledDrugNotice,
      stock: this.mapStockRecord(result.stockRecord, userNames),
      transaction: {
        id: result.transaction.id,
        transactionType: result.transaction.transactionType,
        quantity: result.transaction.quantity,
        quantityUnit: result.transaction.quantityUnit,
        reason: result.transaction.reason,
        recordedByUserId: result.transaction.recordedByUserId,
        recordedByUserName:
          userNames.get(result.transaction.recordedByUserId) ?? null,
        witnessUserId: result.transaction.witnessUserId,
        witnessUserName: result.transaction.witnessUserId
          ? (userNames.get(result.transaction.witnessUserId) ?? null)
          : null,
        createdAt: result.transaction.createdAt,
      },
      controlledDrugWorkflow: {
        isControlledDrug: order.isControlledDrug,
        witnessRequiredForManualTransactions:
          order.isControlledDrug || order.requiresWitness,
      },
    };
  }

  async getManagerMedicationExceptions(
    shiftId?: string,
    user?: Pick<AuthenticatedUser, 'userId'>,
  ) {
    const shiftIds = shiftId
      ? [shiftId]
      : (
          await this.prisma.shift.findMany({
            where: {
              status: 'ACTIVE',
            },
            select: {
              id: true,
            },
          })
        ).map((shift) => shift.id);

    if (shiftIds.length === 0) {
      return {
        workflowNote: medicationWorkflowNote,
        exceptions: [],
        recentPrnEvents: [],
        recentChanges: [],
      };
    }

    await Promise.all(
      shiftIds.map((entry) => this.syncOverdueDoseInstances(entry)),
    );

    const [doseInstances, prnEvents, changeLogs] = await Promise.all([
      this.prisma.medicationDoseInstance.findMany({
        where: {
          shiftId: {
            in: shiftIds,
          },
          status: {
            in: [
              MedicationDoseStatus.OVERDUE,
              MedicationDoseStatus.REFUSED,
              MedicationDoseStatus.OMITTED,
              MedicationDoseStatus.DELAYED,
              MedicationDoseStatus.NOT_AVAILABLE,
              MedicationDoseStatus.HELD,
            ],
          },
        },
        include: {
          medicationOrder: {
            include: {
              resident: {
                select: {
                  id: true,
                  fullName: true,
                  roomLabel: true,
                  floorNumber: true,
                  unitLabel: true,
                },
              },
            },
          },
          schedule: {
            select: {
              id: true,
              roundLabel: true,
              anchorType: true,
            },
          },
        },
        orderBy: [{ dueWindowEnd: 'asc' }],
        take: 50,
      }),
      this.prisma.medicationAdministrationEvent.findMany({
        where: {
          shiftId: {
            in: shiftIds,
          },
          eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
        },
        include: {
          medicationOrder: {
            select: {
              medicationName: true,
              strength: true,
              formulation: true,
            },
          },
          resident: {
            select: {
              fullName: true,
              roomLabel: true,
            },
          },
        },
        orderBy: {
          recordedAt: 'desc',
        },
        take: 20,
      }),
      this.prisma.medicationChangeLog.findMany({
        where: {
          createdAt: {
            gte: new Date(Date.now() - 48 * 60 * 60 * 1000),
          },
        },
        include: {
          medicationOrder: {
            select: {
              medicationName: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
        take: 20,
      }),
    ]);

    const userNames = await this.loadUserNameMap([
      ...doseInstances.flatMap((entry) => [
        entry.recordedByUserId,
        entry.witnessUserId,
      ]),
      ...prnEvents.flatMap((entry) => [
        entry.recordedByUserId,
        entry.witnessUserId,
      ]),
      ...changeLogs.map((entry) => entry.changedByUserId),
    ]);

    const payload = {
      workflowNote: medicationWorkflowNote,
      exceptions: doseInstances.map((entry) => {
        const mapped = this.mapDoseInstance(entry, userNames);
        return {
          id: mapped.id,
          shiftId: entry.shiftId,
          residentId: mapped.residentId,
          residentName: mapped.residentName,
          roomLabel: mapped.roomLabel,
          floorNumber: mapped.floorNumber,
          unitLabel: mapped.unitLabel,
          medicationOrderId: mapped.medicationOrderId,
          medicationName: mapped.medicationName,
          dueWindowStart: mapped.dueWindowStart,
          dueWindowEnd: mapped.dueWindowEnd,
          status: mapped.status as MedicationExceptionStatus,
          recordedByUserId: mapped.recordedByUserId,
          recordedByUserName: mapped.recordedByUserName,
          recordedAt: mapped.recordedAt,
          reason: mapped.reason,
          notes: mapped.notes,
          residentEmarPath: `/residents/${mapped.residentId}/emar`,
          doseInstanceId: mapped.id,
          roundLabel: mapped.roundLabel,
        };
      }),
      recentPrnEvents: prnEvents.map((entry) =>
        this.mapAdministrationEvent(entry, userNames),
      ),
      recentChanges: changeLogs.map((entry) =>
        this.mapMedicationChangeLog(entry, userNames),
      ),
    };

    if (user?.userId) {
      await this.prisma.auditEvent.create({
        data: {
          kind: 'MEDICATION_EXCEPTION_VIEWED',
          userId: user.userId,
          shiftId: shiftId ?? null,
          details: {
            exceptionCount: payload.exceptions.length,
            shiftId: shiftId ?? null,
          },
        },
      });
    }

    return payload;
  }

  async getManagerOverdueMedication(shiftId?: string) {
    const payload = await this.getManagerMedicationExceptions(shiftId);
    return {
      workflowNote: payload.workflowNote,
      overdueMedication: payload.exceptions.filter(
        (entry) => entry.status === 'OVERDUE',
      ),
    };
  }

  async getManagerMedicationReconciliationQueue(
    user?: Pick<AuthenticatedUser, 'userId'>,
  ) {
    const reconciliations = await this.prisma.medicationReconciliation.findMany(
      {
        where: {
          status: MedicationReconciliationStatus.PENDING,
        },
        include: {
          resident: {
            select: {
              id: true,
              fullName: true,
              roomLabel: true,
              floorNumber: true,
              unitLabel: true,
            },
          },
        },
        orderBy: [{ createdAt: 'asc' }],
        take: 50,
      },
    );

    const userNames = await this.loadUserNameMap(
      reconciliations.flatMap((entry) => [
        entry.createdByUserId,
        entry.completedByUserId,
      ]),
    );

    const queue = reconciliations.map((entry) => ({
      ...this.mapMedicationReconciliation(entry, userNames),
      residentName: entry.resident.fullName,
      roomLabel: entry.resident.roomLabel,
      floorNumber: entry.resident.floorNumber,
      unitLabel: entry.resident.unitLabel,
      residentEmarPath: `/residents/${entry.resident.id}/emar`,
    }));

    if (user?.userId) {
      await this.prisma.auditEvent.create({
        data: {
          kind: 'MEDICATION_EXCEPTION_VIEWED',
          userId: user.userId,
          details: {
            reconciliationQueueCount: queue.length,
          },
        },
      });
    }

    return {
      workflowNote: medicationWorkflowNote,
      downtimeNotice: medicationDowntimeNotice,
      controlledDrugNotice: medicationControlledDrugNotice,
      reconciliations: queue,
    };
  }

  async getManagerMedicationAudit() {
    const auditEvents = await this.prisma.auditEvent.findMany({
      where: {
        kind: {
          in: medicationAuditKinds,
        },
      },
      include: {
        user: {
          select: {
            displayName: true,
            email: true,
          },
        },
        shift: {
          select: {
            name: true,
            floorNumber: true,
            unitLabel: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 100,
    });

    const [orders, residents] = await Promise.all([
      this.prisma.medicationOrder.findMany({
        where: {
          id: {
            in: Array.from(
              new Set(
                auditEvents
                  .map((entry) => entry.medicationOrderId)
                  .filter((value): value is string => Boolean(value)),
              ),
            ),
          },
        },
        select: {
          id: true,
          medicationName: true,
        },
      }),
      this.prisma.resident.findMany({
        where: {
          id: {
            in: Array.from(
              new Set(
                auditEvents
                  .map((entry) => entry.residentId)
                  .filter((value): value is string => Boolean(value)),
              ),
            ),
          },
        },
        select: {
          id: true,
          fullName: true,
          roomLabel: true,
        },
      }),
    ]);

    const ordersById = new Map(orders.map((entry) => [entry.id, entry]));
    const residentsById = new Map(residents.map((entry) => [entry.id, entry]));

    return {
      workflowNote: medicationWorkflowNote,
      auditEvents: auditEvents.map((event) => ({
        id: event.id,
        kind: event.kind,
        actorUserId: event.userId,
        actorName: event.user?.displayName ?? null,
        actorEmail: event.user?.email ?? null,
        residentId: event.residentId,
        residentName: event.residentId
          ? (residentsById.get(event.residentId)?.fullName ?? null)
          : null,
        roomLabel: event.residentId
          ? (residentsById.get(event.residentId)?.roomLabel ?? null)
          : null,
        medicationOrderId: event.medicationOrderId,
        medicationName: event.medicationOrderId
          ? (ordersById.get(event.medicationOrderId)?.medicationName ?? null)
          : null,
        medicationDoseInstanceId: event.medicationDoseInstanceId,
        shiftId: event.shiftId,
        shiftName: event.shift?.name ?? null,
        shiftFloorNumber: event.shift?.floorNumber ?? null,
        shiftUnitLabel: event.shift?.unitLabel ?? null,
        details: event.details,
        createdAt: event.createdAt,
      })),
    };
  }

  async buildManagerMedicationOverview(shiftId?: string) {
    const [exceptions, overdue] = await Promise.all([
      this.getManagerMedicationExceptions(shiftId),
      this.getManagerOverdueMedication(shiftId),
    ]);

    return {
      workflowNote: medicationWorkflowNote,
      totals: {
        overdue: overdue.overdueMedication.length,
        refused: exceptions.exceptions.filter(
          (entry) => entry.status === 'REFUSED',
        ).length,
        omitted: exceptions.exceptions.filter(
          (entry) => entry.status === 'OMITTED',
        ).length,
        delayed: exceptions.exceptions.filter(
          (entry) => entry.status === 'DELAYED',
        ).length,
        notAvailable: exceptions.exceptions.filter(
          (entry) => entry.status === 'NOT_AVAILABLE',
        ).length,
        held: exceptions.exceptions.filter((entry) => entry.status === 'HELD')
          .length,
        recentPrnAdministrations: exceptions.recentPrnEvents.length,
      },
      exceptions: exceptions.exceptions,
      recentPrnEvents: exceptions.recentPrnEvents,
      recentChanges: exceptions.recentChanges,
    };
  }

  private toCsvCell(value: CsvCell) {
    if (value == null) {
      return '';
    }

    const rendered =
      value instanceof Date ? value.toISOString() : String(value);
    if (/[",\n]/.test(rendered)) {
      return `"${rendered.replace(/"/g, '""')}"`;
    }

    return rendered;
  }

  private buildCsv(
    headers: readonly string[],
    rows: ReadonlyArray<ReadonlyArray<CsvCell>>,
  ) {
    const headerRow = headers.map((header) => this.toCsvCell(header)).join(',');
    const bodyRows = rows.map((row) =>
      row.map((cell) => this.toCsvCell(cell)).join(','),
    );
    return [headerRow, ...bodyRows].join('\n');
  }

  async exportResidentEmarCsv(residentId: string, user: AuthenticatedUser) {
    const payload = await this.getResidentEmar(residentId, user);
    const rows = [
      ...payload.scheduledMedications.map((entry) => [
        payload.resident.fullName,
        'SCHEDULED',
        entry.medicationName,
        entry.strength,
        entry.formulation,
        entry.doseAmount,
        entry.doseUnit,
        entry.route,
        entry.instructions,
        entry.startDate,
        entry.endDate,
        entry.isActive,
      ]),
      ...payload.prnMedications.map((entry) => [
        payload.resident.fullName,
        'PRN',
        entry.medicationName,
        entry.strength,
        entry.formulation,
        entry.doseAmount,
        entry.doseUnit,
        entry.route,
        entry.instructions,
        entry.startDate,
        entry.endDate,
        entry.isActive,
      ]),
    ];

    return this.buildCsv(
      [
        'Resident',
        'MedicationType',
        'MedicationName',
        'Strength',
        'Formulation',
        'DoseAmount',
        'DoseUnit',
        'Route',
        'Instructions',
        'StartDate',
        'EndDate',
        'IsActive',
      ],
      rows,
    );
  }

  async exportResidentDowntimePackCsv(
    residentId: string,
    user: AuthenticatedUser,
  ) {
    const payload = await this.getResidentEmar(residentId, user);

    await this.prisma.auditEvent.create({
      data: {
        kind: 'MEDICATION_DOWNTIME_PACK_EXPORTED',
        userId: user.userId,
        residentId,
        details: {
          scheduledMedicationCount: payload.scheduledMedications.length,
          prnMedicationCount: payload.prnMedications.length,
          reconciliationCount: payload.reconciliations.length,
        },
      },
    });

    const rows = [
      ...payload.scheduledMedications.map((entry) => [
        'MEDICATION',
        'SCHEDULED',
        entry.medicationName,
        entry.strength,
        entry.formulation,
        entry.doseAmount,
        entry.doseUnit,
        entry.route,
        entry.instructions,
        entry.isControlledDrug,
        entry.requiresWitness,
        entry.startDate,
        entry.endDate,
      ]),
      ...payload.prnMedications.map((entry) => [
        'MEDICATION',
        'PRN',
        entry.medicationName,
        entry.strength,
        entry.formulation,
        entry.doseAmount,
        entry.doseUnit,
        entry.route,
        entry.prnProtocol?.doseInstructions ?? entry.instructions,
        entry.isControlledDrug,
        entry.requiresWitness,
        entry.startDate,
        entry.endDate,
      ]),
      ...payload.allergies.map((entry) => [
        'ALLERGY',
        '',
        entry.substance,
        entry.severity,
        '',
        '',
        '',
        '',
        entry.reaction,
        '',
        '',
        '',
        '',
      ]),
      ...payload.reconciliations.map((entry) => [
        'RECONCILIATION',
        entry.triggerType,
        entry.status,
        '',
        '',
        '',
        '',
        '',
        entry.discrepancySummary ?? entry.notes,
        '',
        '',
        entry.downtimeStartedAt,
        entry.downtimeEndedAt,
      ]),
    ];

    return this.buildCsv(
      [
        'RowType',
        'MedicationTypeOrTrigger',
        'MedicationNameOrStatus',
        'StrengthOrSeverity',
        'Formulation',
        'DoseAmount',
        'DoseUnit',
        'Route',
        'InstructionsOrNotes',
        'IsControlledDrug',
        'RequiresWitness',
        'StartDate',
        'EndDate',
      ],
      [
        [
          'META',
          payload.resident.fullName,
          payload.resident.roomLabel,
          payload.downtimePackNotice,
          payload.controlledDrugNotice,
          '',
          '',
          '',
          '',
          '',
          '',
          new Date(),
          '',
        ],
        ...rows,
      ],
    );
  }

  async exportMedicationRoundCsv(shiftId: string, user: AuthenticatedUser) {
    const payload = await this.getMedicationRound(shiftId, user);
    const rows = payload.groupedRounds.flatMap((group) =>
      group.items.map((entry) => [
        group.roundLabel,
        entry.residentName,
        entry.roomLabel,
        entry.medicationName,
        entry.strength,
        entry.doseAmount,
        entry.doseUnit,
        entry.route,
        entry.dueWindowStart,
        entry.dueWindowEnd,
        entry.status,
      ]),
    );

    return this.buildCsv(
      [
        'RoundLabel',
        'ResidentName',
        'RoomLabel',
        'MedicationName',
        'Strength',
        'DoseAmount',
        'DoseUnit',
        'Route',
        'DueWindowStart',
        'DueWindowEnd',
        'Status',
      ],
      rows,
    );
  }

  async exportMedicationAuditCsv() {
    const payload = await this.getManagerMedicationAudit();
    return this.buildCsv(
      [
        'AuditEventId',
        'Kind',
        'ActorName',
        'ResidentName',
        'MedicationName',
        'ShiftName',
        'CreatedAt',
      ],
      payload.auditEvents.map((entry) => [
        entry.id,
        entry.kind,
        entry.actorName,
        entry.residentName,
        entry.medicationName,
        entry.shiftName,
        entry.createdAt,
      ]),
    );
  }
}
