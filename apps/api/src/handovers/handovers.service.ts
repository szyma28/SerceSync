import { Injectable, NotFoundException } from '@nestjs/common';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class HandoversService {
  constructor(private readonly prisma: PrismaService) {}

  private async findCurrentHandoverForUser(userId: string) {
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
            },
          },
        },
      },
      orderBy: {
        startsAt: 'desc',
      },
    });

    if (!shift || !shift.handover) {
      throw new NotFoundException(
        'No active handover was found for the current user.',
      );
    }

    return {
      shift,
      handover: shift.handover,
      acknowledgement: shift.handover.acknowledgements[0] ?? null,
    };
  }

  private toResponse(
    user: AuthenticatedUser,
    shift: {
      id: string;
      name: string;
      startsAt: Date;
      endsAt: Date;
      status: string;
    },
    handover: {
      id: string;
      summary: string;
      createdAt: Date;
      updatedAt: Date;
    },
    acknowledgement: {
      acknowledgedAt: Date;
    } | null,
  ) {
    return {
      shift: {
        id: shift.id,
        name: shift.name,
        startsAt: shift.startsAt,
        endsAt: shift.endsAt,
        status: shift.status,
      },
      handover: {
        id: handover.id,
        summary: handover.summary,
        createdAt: handover.createdAt,
        updatedAt: handover.updatedAt,
      },
      currentUser: {
        id: user.userId,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
      },
      acknowledged: acknowledgement !== null,
      acknowledgedAt: acknowledgement?.acknowledgedAt ?? null,
    };
  }

  async getCurrentHandover(user: AuthenticatedUser) {
    const { shift, handover, acknowledgement } =
      await this.findCurrentHandoverForUser(user.userId);

    return this.toResponse(user, shift, handover, acknowledgement);
  }

  async acknowledgeCurrentHandover(user: AuthenticatedUser) {
    const { shift, handover, acknowledgement } =
      await this.findCurrentHandoverForUser(user.userId);

    if (acknowledgement) {
      return this.toResponse(user, shift, handover, acknowledgement);
    }

    const createdAcknowledgement = await this.prisma.$transaction(async (tx) => {
      const newAcknowledgement = await tx.handoverAcknowledgement.create({
        data: {
          handoverId: handover.id,
          acknowledgedById: user.userId,
        },
      });

      await tx.auditEvent.create({
        data: {
          kind: 'HANDOVER_ACKNOWLEDGED',
          userId: user.userId,
          shiftId: shift.id,
          details: {
            handoverId: handover.id,
          },
        },
      });

      return newAcknowledgement;
    });

    return this.toResponse(user, shift, handover, createdAcknowledgement);
  }
}
