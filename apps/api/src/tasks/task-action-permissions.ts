import type { RoleKey, TaskFocus, TaskStatus } from '@prisma/client';

export const medicationRestrictionReason =
  'Only nurses can administer medication.';

type TaskActionPermissionInput = {
  focus: TaskFocus;
  status: TaskStatus;
  assignedUserId: string | null;
};

type TaskActionPermissionContext = {
  currentUserId: string;
  currentUserRole: RoleKey;
};

type TaskActionPermissions = {
  canComplete: boolean;
  canDefer: boolean;
  canEscalate: boolean;
  actionRestrictionReason: string | null;
};

const actionableStatuses = new Set<TaskStatus>(['PENDING', 'OVERDUE']);

export const buildTaskActionPermissions = (
  task: TaskActionPermissionInput,
  context: TaskActionPermissionContext,
): TaskActionPermissions => {
  const isActionableStatus = actionableStatuses.has(task.status);
  const isAssignedToCurrentUser = task.assignedUserId === context.currentUserId;
  const isMedicationTask = task.focus === 'MEDICATION';

  if (!isActionableStatus) {
    return {
      canComplete: false,
      canDefer: false,
      canEscalate: false,
      actionRestrictionReason: null,
    };
  }

  if (isMedicationTask && context.currentUserRole !== 'NURSE') {
    return {
      canComplete: false,
      canDefer: false,
      canEscalate: false,
      actionRestrictionReason: medicationRestrictionReason,
    };
  }

  if (!isAssignedToCurrentUser) {
    return {
      canComplete: false,
      canDefer: false,
      canEscalate: false,
      actionRestrictionReason: 'Assigned to another team member.',
    };
  }

  return {
    canComplete: true,
    canDefer: true,
    canEscalate: true,
    actionRestrictionReason: null,
  };
};
