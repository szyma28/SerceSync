import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import type {
  AuditEventKind,
  TaskClinicalPriority,
  TaskFocus,
  TaskStatus,
} from '@prisma/client';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { type AuditEventDetails } from '../audit-event-details';
import {
  ManagerDashboardStreamService,
  type ManagerDashboardUpdateReason,
} from '../manager-dashboard-stream/manager-dashboard-stream.service';
import { PrismaService } from '../prisma/prisma.service';
import { CompleteTaskDto } from './dto/complete-task.dto';
import { TaskReasonDto } from './dto/task-reason.dto';
import {
  buildTaskActionPermissions,
  medicationRestrictionReason,
} from './task-action-permissions';

const taskStatusSortOrder: Record<TaskStatus, number> = {
  PENDING: 0,
  OVERDUE: 1,
  DEFERRED: 2,
  ESCALATED: 3,
  COMPLETED: 4,
};

@Injectable()
export class TasksService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly managerDashboardStream: ManagerDashboardStreamService,
  ) {}

  private sanitizeNote(value: string | undefined) {
    const trimmed = value?.trim();
    return trimmed ? trimmed : null;
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

  private async syncOverdueTasks(shiftId: string) {
    await this.prisma.task.updateMany({
      where: {
        shiftId,
        status: 'PENDING',
        dueAt: {
          lt: new Date(),
        },
      },
      data: {
        status: 'OVERDUE',
      },
    });
  }

  private toTaskSummary(
    task: {
      id: string;
      title: string;
      description: string | null;
      focus: TaskFocus;
      clinicalPriority: TaskClinicalPriority;
      status: TaskStatus;
      dueAt: Date | null;
      statusNote: string | null;
      statusUpdatedAt: Date | null;
      assignedUserId: string | null;
      residentId: string | null;
      resident: {
        fullName: string;
        roomLabel: string;
      } | null;
    },
    user: AuthenticatedUser,
  ) {
    const actionPermissions = buildTaskActionPermissions(task, {
      currentUserId: user.userId,
      currentUserRole: user.role,
    });

    return {
      id: task.id,
      title: task.title,
      description: task.description,
      focus: task.focus,
      clinicalPriority: task.clinicalPriority,
      status: task.status,
      dueAt: task.dueAt,
      statusNote: task.statusNote,
      statusUpdatedAt: task.statusUpdatedAt,
      assignedUserId: task.assignedUserId,
      residentId: task.residentId,
      residentName: task.resident?.fullName ?? null,
      room: task.resident?.roomLabel ?? null,
      ...actionPermissions,
    };
  }

  private async findActionableTask(taskId: string, user: AuthenticatedUser) {
    const shift = await this.findCurrentShiftForUser(user.userId);
    await this.syncOverdueTasks(shift.id);

    const task = await this.prisma.task.findFirst({
      where: {
        id: taskId,
        shiftId: shift.id,
      },
      include: {
        resident: true,
      },
    });

    if (!task) {
      throw new NotFoundException(
        'The requested task was not found in the current user shift.',
      );
    }

    if (task.focus === 'MEDICATION' && user.role !== 'NURSE') {
      throw new ForbiddenException({
        message: medicationRestrictionReason,
        code: 'MEDICATION_NURSE_REQUIRED',
      });
    }

    if (task.assignedUserId !== user.userId) {
      throw new NotFoundException(
        'The requested task was not found in the current user shift.',
      );
    }

    if (task.status !== 'PENDING' && task.status !== 'OVERDUE') {
      throw new BadRequestException(
        `Task is already ${task.status.toLowerCase()} and cannot be updated again.`,
      );
    }

    return { shift, task };
  }

  private async transitionTask(
    taskId: string,
    user: AuthenticatedUser,
    nextStatus: TaskStatus,
    auditKind: AuditEventKind,
    note: string | null,
  ) {
    const { shift, task } = await this.findActionableTask(taskId, user);
    const now = new Date();

    const updatedTask = await this.prisma.$transaction(async (tx) => {
      const taskRecord = await tx.task.update({
        where: { id: task.id },
        data: {
          status: nextStatus,
          statusNote: note,
          statusUpdatedAt: now,
        },
        include: {
          resident: true,
        },
      });

      await tx.auditEvent.create({
        data: {
          kind: auditKind,
          userId: user.userId,
          shiftId: shift.id,
          taskId: task.id,
          details: {
            fromStatus: task.status,
            toStatus: nextStatus,
            note,
          } satisfies AuditEventDetails,
        },
      });

      return taskRecord;
    });

    let updateReason: ManagerDashboardUpdateReason | null = null;
    switch (nextStatus) {
      case 'COMPLETED':
        updateReason = 'task-completed';
        break;
      case 'DEFERRED':
        updateReason = 'task-deferred';
        break;
      case 'ESCALATED':
        updateReason = 'task-escalated';
        break;
      default:
        break;
    }

    if (updateReason) {
      this.managerDashboardStream.publishShiftUpdate(shift.id, updateReason);
    }

    return {
      task: this.toTaskSummary(updatedTask, user),
    };
  }

  async getCurrentTasks(user: AuthenticatedUser) {
    const shift = await this.findCurrentShiftForUser(user.userId);
    await this.syncOverdueTasks(shift.id);
    const shouldIncludeMedicationTasks = user.role === 'NURSE';

    const tasks = await this.prisma.task.findMany({
      where: {
        shiftId: shift.id,
        status: {
          notIn: ['COMPLETED', 'DEFERRED'],
        },
        OR: [
          {
            assignedUserId: user.userId,
          },
          ...(shouldIncludeMedicationTasks
            ? [
                {
                  focus: 'MEDICATION' as const,
                },
              ]
            : []),
        ],
      },
      include: {
        resident: true,
      },
    });

    const sortedTasks = tasks.sort((left, right) => {
      const statusDelta =
        taskStatusSortOrder[left.status] - taskStatusSortOrder[right.status];

      if (statusDelta !== 0) {
        return statusDelta;
      }

      const leftDueAt = left.dueAt?.getTime() ?? Number.MAX_SAFE_INTEGER;
      const rightDueAt = right.dueAt?.getTime() ?? Number.MAX_SAFE_INTEGER;

      if (leftDueAt !== rightDueAt) {
        return leftDueAt - rightDueAt;
      }

      return left.createdAt.getTime() - right.createdAt.getTime();
    });

    return {
      shift: {
        id: shift.id,
        name: shift.name,
        startsAt: shift.startsAt,
        endsAt: shift.endsAt,
        status: shift.status,
        floorNumber: shift.floorNumber,
        unitLabel: shift.unitLabel,
      },
      currentUser: {
        id: user.userId,
        email: user.email,
        displayName: user.displayName,
        role: user.role,
      },
      tasks: sortedTasks.map((task) => this.toTaskSummary(task, user)),
    };
  }

  async completeTask(
    taskId: string,
    user: AuthenticatedUser,
    completeTaskDto: CompleteTaskDto,
  ) {
    return this.transitionTask(
      taskId,
      user,
      'COMPLETED',
      'TASK_COMPLETED',
      this.sanitizeNote(completeTaskDto.note),
    );
  }

  async deferTask(
    taskId: string,
    user: AuthenticatedUser,
    taskReasonDto: TaskReasonDto,
  ) {
    return this.transitionTask(
      taskId,
      user,
      'DEFERRED',
      'TASK_DEFERRED',
      this.sanitizeNote(taskReasonDto.reason),
    );
  }

  async escalateTask(
    taskId: string,
    user: AuthenticatedUser,
    taskReasonDto: TaskReasonDto,
  ) {
    return this.transitionTask(
      taskId,
      user,
      'ESCALATED',
      'TASK_ESCALATED',
      this.sanitizeNote(taskReasonDto.reason),
    );
  }
}
