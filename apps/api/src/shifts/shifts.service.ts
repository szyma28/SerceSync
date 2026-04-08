import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ShiftsService {
  constructor(private readonly prisma: PrismaService) {}

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
      throw new NotFoundException('No active shift found for the current user.');
    }

    return {
      id: shift.id,
      name: shift.name,
      startsAt: shift.startsAt,
      endsAt: shift.endsAt,
      status: shift.status,
    };
  }
}
