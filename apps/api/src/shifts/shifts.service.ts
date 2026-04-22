import { Injectable, NotFoundException } from '@nestjs/common';
import type { ShiftStatus } from '@prisma/client';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { MedicationOperationalSummaryService } from '../medications/medication-operational-summary.service';
import type { MedicationTaskCompatibleSummary } from '../medications/medication-operational-summary.types';
import { PrismaService } from '../prisma/prisma.service';
import { buildMedicationTaskSummary } from '../tasks/task-medication-summary';

type ShiftSummaryInput = {
  id: string;
  name: string;
  startsAt: Date;
  endsAt: Date;
  status: ShiftStatus;
  floorNumber: number;
  unitLabel: string;
  handover: {
    acknowledgements: Array<{
      acknowledgedAt: Date;
    }>;
  } | null;
};

const emptyMedicationSummary: MedicationTaskCompatibleSummary = {
  total: 0,
  overdue: 0,
  dueWithinHour: 0,
  highPriority: 0,
  headline: null,
  warnings: [],
};

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

@Injectable()
export class ShiftsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly medicationOperationalSummaryService: MedicationOperationalSummaryService,
  ) {}

  private toShiftSummary(shift: ShiftSummaryInput) {
    const acknowledgement = shift.handover?.acknowledgements[0] ?? null;

    return {
      id: shift.id,
      name: shift.name,
      startsAt: shift.startsAt,
      endsAt: shift.endsAt,
      status: shift.status,
      floorNumber: shift.floorNumber,
      unitLabel: shift.unitLabel,
      handoverAcknowledged: acknowledgement !== null,
      handoverAcknowledgedAt: acknowledgement?.acknowledgedAt ?? null,
    };
  }

  async getCurrentShiftForUser(userId: string) {
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
              where: {
                acknowledgedById: userId,
              },
              select: {
                acknowledgedAt: true,
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

    return this.toShiftSummary(shift);
  }

  async getShiftOverviewForUser(user: AuthenticatedUser) {
    const currentShift = await this.prisma.shift.findFirst({
      where: {
        status: 'ACTIVE',
        assignedUsers: {
          some: {
            id: user.userId,
          },
        },
      },
      include: {
        handover: {
          include: {
            acknowledgements: {
              where: {
                acknowledgedById: user.userId,
              },
              select: {
                acknowledgedAt: true,
              },
            },
          },
        },
      },
      orderBy: {
        startsAt: 'desc',
      },
    });
    const medicationOperationalSummary =
      currentShift && user.role === 'NURSE'
        ? await this.medicationOperationalSummaryService.buildShiftOperationalSummary(
            currentShift.id,
          )
        : null;
    const medicationTaskSummary =
      currentShift && user.role === 'NURSE'
        ? buildMedicationTaskSummary(
            await this.prisma.task.findMany({
              where: {
                shiftId: currentShift.id,
              },
              select: {
                focus: true,
                status: true,
                dueAt: true,
                clinicalPriority: true,
              },
            }),
          )
        : emptyMedicationSummary;
    const medicationSummary = hasMedicationSignal(
      medicationOperationalSummary?.taskSummaryCompatible ?? null,
    )
      ? medicationOperationalSummary?.taskSummaryCompatible ?? emptyMedicationSummary
      : medicationTaskSummary;

    return {
      currentShift: currentShift ? this.toShiftSummary(currentShift) : null,
      medicationSummary,
      medicationOperationalSummary,
    };
  }
}
