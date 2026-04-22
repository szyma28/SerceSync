import type {
  TaskClinicalPriority,
  TaskFocus,
  TaskStatus,
} from '@prisma/client';

type MedicationAwareTask = {
  focus: TaskFocus;
  status: TaskStatus;
  dueAt: Date | null;
  clinicalPriority: TaskClinicalPriority;
};

type MedicationTaskSummary = {
  total: number;
  overdue: number;
  dueWithinHour: number;
  highPriority: number;
  headline: string | null;
  warnings: string[];
};

const hiddenTaskStatuses = new Set<TaskStatus>(['COMPLETED', 'DEFERRED']);

function formatMedicationCount(
  count: number,
  singularLabel: string,
  pluralLabel: string = `${singularLabel}s`,
) {
  return `${count} ${count === 1 ? singularLabel : pluralLabel}`;
}

function isOpenMedicationTask(task: MedicationAwareTask) {
  return task.focus === 'MEDICATION' && !hiddenTaskStatuses.has(task.status);
}

function isMedicationTaskOverdue(
  task: Pick<MedicationAwareTask, 'status' | 'dueAt'>,
  referenceTime = new Date(),
) {
  if (task.status === 'OVERDUE') {
    return true;
  }

  if (task.status !== 'PENDING' || task.dueAt == null) {
    return false;
  }

  return task.dueAt.getTime() < referenceTime.getTime();
}

function isMedicationTaskDueWithinHour(
  task: Pick<MedicationAwareTask, 'status' | 'dueAt'>,
  referenceTime = new Date(),
) {
  if (task.status !== 'PENDING' || task.dueAt == null) {
    return false;
  }

  const diffMs = task.dueAt.getTime() - referenceTime.getTime();
  return diffMs >= 0 && diffMs <= 60 * 60 * 1000;
}

export function buildMedicationTaskSummary(
  tasks: MedicationAwareTask[],
  referenceTime = new Date(),
): MedicationTaskSummary {
  const medicationTasks = tasks.filter((task) => isOpenMedicationTask(task));
  const overdue = medicationTasks.filter((task) =>
    isMedicationTaskOverdue(task, referenceTime),
  ).length;
  const dueWithinHour = medicationTasks.filter((task) =>
    isMedicationTaskDueWithinHour(task, referenceTime),
  ).length;
  const highPriority = medicationTasks.filter(
    (task) => task.clinicalPriority !== 'ROUTINE',
  ).length;

  const warnings: string[] = [];
  if (overdue > 0) {
    warnings.push(`${formatMedicationCount(overdue, 'medication')} overdue`);
  }
  if (dueWithinHour > 0) {
    warnings.push(
      `${formatMedicationCount(
        dueWithinHour,
        'medication',
      )} due within the next hour`,
    );
  }
  if (highPriority > 0) {
    warnings.push(
      `${formatMedicationCount(
        highPriority,
        'high-priority medication',
      )} active this shift`,
    );
  }

  let headline: string | null = null;
  if (overdue > 0) {
    headline = `${formatMedicationCount(overdue, 'medication')} overdue`;
  } else if (dueWithinHour > 0) {
    headline = `${formatMedicationCount(dueWithinHour, 'medication')} due soon`;
  } else if (highPriority > 0) {
    headline = `${formatMedicationCount(
      highPriority,
      'high-priority medication',
    )} pending`;
  } else if (medicationTasks.length > 0) {
    headline = `${formatMedicationCount(
      medicationTasks.length,
      'medication task',
    )} active`;
  }

  return {
    total: medicationTasks.length,
    overdue,
    dueWithinHour,
    highPriority,
    headline,
    warnings,
  };
}
