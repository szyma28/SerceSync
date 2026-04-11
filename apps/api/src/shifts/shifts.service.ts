import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ShiftsService {
  constructor(private readonly prisma: PrismaService) {}

  private toShiftSummary(
    shift: {
      id: string;
      name: string;
      startsAt: Date;
      endsAt: Date;
      status: string;
      floorNumber: number;
      unitLabel: string;
      handover?: {
        acknowledgements: Array<{
          acknowledgedAt: Date;
        }>;
      } | null;
    },
  ) {
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

  async getShiftOverviewForUser(userId: string) {
    const assignments = await this.prisma.shift.findMany({
      where: {
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
      orderBy: [{ startsAt: 'asc' }, { createdAt: 'asc' }],
    });

    const currentShift =
      assignments.find((assignment) => assignment.status === 'ACTIVE') ?? null;

    return {
      currentShift: currentShift ? this.toShiftSummary(currentShift) : null,
      assignments: assignments.map((assignment) =>
        this.toShiftSummary(assignment),
      ),
    };
  }
}
