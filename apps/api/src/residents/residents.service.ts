import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type {
  ResidentTimelineEntryType,
  ResidentTimelineMedia,
  TaskStatus,
} from '@prisma/client';
import { randomUUID } from 'crypto';
import { mkdir, unlink, writeFile } from 'fs/promises';
import { tmpdir } from 'os';
import { extname, join } from 'path';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { CreateManagerResidentDto } from './dto/create-manager-resident.dto';
import { CreateResidentTimelineEntryDto } from './dto/create-resident-timeline-entry.dto';
import { UpdateManagerResidentDto } from './dto/update-manager-resident.dto';

type UploadedEvidenceFile = {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
  size: number;
};

const entryTypeLabels: Record<ResidentTimelineEntryType, string> = {
  CARE_GIVEN: 'Care Given',
  OBSERVATION: 'Observation',
  PERSONAL_CARE: 'Personal Care',
  NUTRITION_HYDRATION: 'Nutrition / Hydration',
  MOBILITY_REPOSITIONING: 'Mobility / Repositioning',
  MEDICATION_NOTE: 'Medication Note',
  ESCALATION: 'Escalation',
};

@Injectable()
export class ResidentsService {
  constructor(private readonly prisma: PrismaService) {}

  private getMediaStorageDirectory() {
    return join(tmpdir(), 'sercesync', 'resident-timeline-media');
  }

  private async ensureMediaStorageDirectory() {
    const mediaDirectory = this.getMediaStorageDirectory();
    await mkdir(mediaDirectory, { recursive: true });
    return mediaDirectory;
  }

  private roomLabel(roomNumber: number) {
    return `Room ${roomNumber}`;
  }

  private normalizeResidentInput(
    input: CreateManagerResidentDto | UpdateManagerResidentDto,
  ) {
    return {
      ...('fullName' in input && input.fullName != null
        ? { fullName: input.fullName.trim() }
        : {}),
      ...('unitLabel' in input && input.unitLabel != null
        ? { unitLabel: input.unitLabel.trim() }
        : {}),
      ...('recognitionImageKey' in input && input.recognitionImageKey != null
        ? { recognitionImageKey: input.recognitionImageKey.trim() }
        : {}),
      ...('careSummary' in input && input.careSummary != null
        ? { careSummary: input.careSummary.trim() }
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
    };
  }

  private buildEntryTitle(
    type: ResidentTimelineEntryType,
    title: string | undefined,
  ) {
    const trimmed = title?.trim();
    return trimmed && trimmed.length > 0 ? trimmed : entryTypeLabels[type];
  }

  private isUniqueConstraintError(error: unknown) {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      error.code === 'P2002'
    );
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
            createdAt: 'desc',
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

  private mapTaskStatusToAlert(status: TaskStatus) {
    switch (status) {
      case 'OVERDUE':
        return 'Overdue follow-up';
      case 'ESCALATED':
        return 'Escalated item';
      case 'DEFERRED':
        return 'Deferred review';
      case 'COMPLETED':
        return 'Completed today';
      case 'PENDING':
      default:
        return 'Due this shift';
    }
  }

  private formatDueState(dueAt: Date | null) {
    if (!dueAt) {
      return 'No timed action due right now';
    }

    const diffMinutes = Math.round((dueAt.getTime() - Date.now()) / 60000);
    if (diffMinutes < 0) {
      return `Overdue by ${Math.abs(diffMinutes)} min`;
    }
    if (diffMinutes === 0) {
      return 'Due now';
    }
    if (diffMinutes < 60) {
      return `Due in ${diffMinutes} min`;
    }
    return `Due in ${Math.floor(diffMinutes / 60)} hr`;
  }

  private buildContextLine(
    tasks: Array<{
      title: string;
      status: TaskStatus;
      dueAt: Date | null;
    }>,
    careSummary: string,
  ) {
    const openTask = tasks.find(
      (task) => task.status !== 'COMPLETED' && task.status !== 'DEFERRED',
    );

    if (!openTask) {
      return careSummary;
    }

    return `${openTask.title} · ${this.formatDueState(openTask.dueAt)}`;
  }

  private buildAlerts(
    tasks: Array<{
      title: string;
      status: TaskStatus;
      dueAt: Date | null;
    }>,
  ) {
    const alerts = tasks
      .slice(0, 2)
      .map((task) => this.mapTaskStatusToAlert(task.status));

    return [...new Set(alerts)];
  }

  private mapTimelineMedia(media: ResidentTimelineMedia) {
    return {
      id: media.id,
      originalFileName: media.originalFileName,
      mediaType: media.mediaType,
      byteSize: media.byteSize,
      downloadPath: `/resident-media/${media.id}`,
      createdAt: media.createdAt,
    };
  }

  private mapTimelineEntry(entry: {
    id: string;
    type: ResidentTimelineEntryType;
    title: string;
    details: string;
    createdAt: Date;
    createdBy: {
      displayName: string;
    } | null;
    media?: ResidentTimelineMedia[];
  }) {
    return {
      id: entry.id,
      type: entry.type,
      title: entry.title,
      details: entry.details,
      authorName: entry.createdBy?.displayName ?? 'System note',
      timestamp: entry.createdAt,
      media: (entry.media ?? []).map((item) => this.mapTimelineMedia(item)),
    };
  }

  private mapResidentTask(
    task: {
      id: string;
      title: string;
      description: string | null;
      status: TaskStatus;
      dueAt: Date | null;
    },
    roomLabel: string,
    residentId: string,
    residentName: string,
  ) {
    return {
      id: task.id,
      title: task.title,
      description: task.description,
      status: task.status,
      dueAt: task.dueAt,
      residentId,
      residentName,
      room: roomLabel,
    };
  }

  private mapManagerResident(resident: {
    id: string;
    fullName: string;
    roomNumber: number;
    roomLabel: string;
    floorNumber: number;
    unitLabel: string;
    recognitionImageKey: string;
    careSummary: string;
    isActive: boolean;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: resident.id,
      fullName: resident.fullName,
      roomNumber: resident.roomNumber,
      roomLabel: resident.roomLabel,
      floorNumber: resident.floorNumber,
      unitLabel: resident.unitLabel,
      recognitionImageKey: resident.recognitionImageKey,
      careSummary: resident.careSummary,
      isActive: resident.isActive,
      createdAt: resident.createdAt,
      updatedAt: resident.updatedAt,
    };
  }

  private async persistResidentTimelineMedia(
    file: UploadedEvidenceFile,
    entryId: string,
    userId: string,
  ) {
    if (!file.mimetype.startsWith('image/')) {
      throw new BadRequestException('Resident evidence uploads must be images.');
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
      },
      orderBy: {
        roomNumber: 'asc',
      },
    });

    return {
      floorNumber: shift.floorNumber,
      unitLabel: shift.unitLabel,
      residents: residents.map((resident) => ({
        id: resident.id,
        fullName: resident.fullName,
        roomLabel: resident.roomLabel,
        floorNumber: resident.floorNumber,
        unitLabel: resident.unitLabel,
        recognitionImageKey: resident.recognitionImageKey,
        todaySummary: resident.careSummary,
        assignmentContext: `Assigned to ${shift.unitLabel} for this shift`,
        contextLine: this.buildContextLine(
          resident.tasks,
          resident.careSummary,
        ),
        alerts: this.buildAlerts(resident.tasks),
      })),
    };
  }

  async getResidentById(residentId: string, user: AuthenticatedUser) {
    const { shift, resident } = await this.findResidentInUserScope(
      residentId,
      user.userId,
    );

    return {
      id: resident.id,
      fullName: resident.fullName,
      roomLabel: resident.roomLabel,
      floorNumber: resident.floorNumber,
      unitLabel: resident.unitLabel,
      recognitionImageKey: resident.recognitionImageKey,
      todaySummary: resident.careSummary,
      assignmentContext: `Assigned to ${shift.unitLabel} for this shift`,
      contextLine: this.buildContextLine(resident.tasks, resident.careSummary),
      alerts: this.buildAlerts(resident.tasks),
      currentTasks: resident.tasks.map((task) =>
        this.mapResidentTask(
          task,
          resident.roomLabel,
          resident.id,
          resident.fullName,
        ),
      ),
      timeline: resident.timelineEntries.map((entry) =>
        this.mapTimelineEntry(entry),
      ),
    };
  }

  async createResidentTimelineEntry(
    residentId: string,
    user: AuthenticatedUser,
    createResidentTimelineEntryDto: CreateResidentTimelineEntryDto,
    evidenceFile?: UploadedEvidenceFile,
  ) {
    const { shift, resident } = await this.findResidentInUserScope(
      residentId,
      user.userId,
    );

    let mediaRecord: ResidentTimelineMedia | null = null;

    try {
      const createdEntry = await this.prisma.$transaction(async (tx) => {
        const entry = await tx.residentTimelineEntry.create({
          data: {
            residentId: resident.id,
            type: createResidentTimelineEntryDto.type,
            title: this.buildEntryTitle(
              createResidentTimelineEntryDto.type,
              createResidentTimelineEntryDto.title,
            ),
            details: createResidentTimelineEntryDto.details.trim(),
            createdById: user.userId,
            shiftId: shift.id,
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
              mediaAttached: Boolean(evidenceFile),
            },
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
            },
          },
        });
      }

      return {
        entry: this.mapTimelineEntry({
          ...createdEntry,
          media: mediaRecord ? [mediaRecord] : [],
        }),
      };
    } catch (error) {
      if (mediaRecord) {
        const storagePath = join(
          this.getMediaStorageDirectory(),
          mediaRecord.storageKey,
        );
        await unlink(storagePath).catch(() => undefined);
      }
      throw error;
    }
  }

  async getManagerResidents() {
    const residents = await this.prisma.resident.findMany({
      orderBy: [{ floorNumber: 'asc' }, { roomNumber: 'asc' }],
    });

    return {
      residents: residents.map((resident) => this.mapManagerResident(resident)),
    };
  }

  async createManagerResident(createManagerResidentDto: CreateManagerResidentDto) {
    const normalizedInput = this.normalizeResidentInput(createManagerResidentDto);

    try {
      const resident = await this.prisma.resident.create({
        data: {
          fullName: normalizedInput.fullName!,
          roomNumber: normalizedInput.roomNumber!,
          roomLabel: normalizedInput.roomLabel!,
          floorNumber: normalizedInput.floorNumber!,
          unitLabel: normalizedInput.unitLabel!,
          recognitionImageKey: normalizedInput.recognitionImageKey!,
          careSummary: normalizedInput.careSummary!,
          isActive: createManagerResidentDto.isActive ?? true,
        },
      });

      return {
        resident: this.mapManagerResident(resident),
      };
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
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

    try {
      const resident = await this.prisma.resident.update({
        where: {
          id: residentId,
        },
        data: this.normalizeResidentInput(updateManagerResidentDto),
      });

      return {
        resident: this.mapManagerResident(resident),
      };
    } catch (error) {
      if (this.isUniqueConstraintError(error)) {
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
