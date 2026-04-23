const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL must be defined before refreshing active shift windows.',
  );
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const maxDemoOverdueMinutes = 30;
const demoPrimaryCarerName = 'Eryk Carer';
const medicationCoverRoles = new Set(['NURSE', 'MANAGER']);

const demoTimeZone = 'Europe/London';
const zonedDateFormatter = new Intl.DateTimeFormat('en-GB', {
  timeZone: demoTimeZone,
  hour12: false,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
  hour: '2-digit',
  minute: '2-digit',
  second: '2-digit',
});

function getZonedParts(date) {
  const parts = zonedDateFormatter.formatToParts(date);

  return {
    year: Number(parts.find((part) => part.type === 'year').value),
    month: Number(parts.find((part) => part.type === 'month').value),
    day: Number(parts.find((part) => part.type === 'day').value),
    hour: Number(parts.find((part) => part.type === 'hour').value),
    minute: Number(parts.find((part) => part.type === 'minute').value),
    second: Number(parts.find((part) => part.type === 'second').value),
  };
}

function addZonedDays(dateParts, dayOffset) {
  const middayReference = new Date(
    Date.UTC(
      dateParts.year,
      dateParts.month - 1,
      dateParts.day + dayOffset,
      12,
    ),
  );

  return getZonedParts(middayReference);
}

function getTimeZoneOffsetMilliseconds(date, timeZone) {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    hour12: false,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
  const parts = formatter.formatToParts(date);
  const values = {
    year: Number(parts.find((part) => part.type === 'year').value),
    month: Number(parts.find((part) => part.type === 'month').value),
    day: Number(parts.find((part) => part.type === 'day').value),
    hour: Number(parts.find((part) => part.type === 'hour').value),
    minute: Number(parts.find((part) => part.type === 'minute').value),
    second: Number(parts.find((part) => part.type === 'second').value),
  };

  return (
    Date.UTC(
      values.year,
      values.month - 1,
      values.day,
      values.hour,
      values.minute,
      values.second,
    ) - date.getTime()
  );
}

function makeZonedDate(dateParts, hour, minute) {
  const utcGuess = Date.UTC(
    dateParts.year,
    dateParts.month - 1,
    dateParts.day,
    hour,
    minute,
    0,
  );
  const offsetMilliseconds = getTimeZoneOffsetMilliseconds(
    new Date(utcGuess),
    demoTimeZone,
  );

  return new Date(utcGuess - offsetMilliseconds);
}

function buildShiftWindow(referenceTime) {
  const localNow = getZonedParts(referenceTime);
  const isDayShift = localNow.hour >= 8 && localNow.hour < 20;
  const currentLocalDate = {
    year: localNow.year,
    month: localNow.month,
    day: localNow.day,
  };
  const previousLocalDate = addZonedDays(currentLocalDate, -1);
  const nextLocalDate = addZonedDays(currentLocalDate, 1);

  if (isDayShift) {
    return {
      startsAt: makeZonedDate(currentLocalDate, 8, 0),
      endsAt: makeZonedDate(currentLocalDate, 20, 0),
    };
  }

  return {
    startsAt: makeZonedDate(previousLocalDate, 20, 0),
    endsAt: makeZonedDate(nextLocalDate, 8, 0),
  };
}

function formatInZone(date) {
  return zonedDateFormatter.format(date);
}

function addMinutes(date, minutes) {
  return new Date(date.getTime() + minutes * 60 * 1000);
}

function uniqueById(users) {
  const seen = new Set();

  return users.filter((user) => {
    if (seen.has(user.id)) {
      return false;
    }

    seen.add(user.id);
    return true;
  });
}

function sortUsers(users) {
  return [...users].sort((left, right) =>
    left.displayName.localeCompare(right.displayName),
  );
}

function pickCoveringUser(task, shiftUsers) {
  const sortedUsers = sortUsers(uniqueById(shiftUsers));
  const assignedUser = task.assignedUser ?? null;
  const sameRoleUsers = assignedUser?.role?.key
    ? sortedUsers.filter((user) => user.role?.key === assignedUser.role.key)
    : sortedUsers;
  const unassignedSameRoleUsers = sameRoleUsers.filter(
    (user) => user.id !== assignedUser?.id,
  );
  const unassignedShiftUsers = sortedUsers.filter(
    (user) => user.id !== assignedUser?.id,
  );
  const nonErykUnassignedSameRoleUsers = unassignedSameRoleUsers.filter(
    (user) => user.displayName !== demoPrimaryCarerName,
  );
  const nonErykUnassignedShiftUsers = unassignedShiftUsers.filter(
    (user) => user.displayName !== demoPrimaryCarerName,
  );

  if (task.focus === 'MEDICATION') {
    const medicationReadyUsers = sortedUsers.filter((user) =>
      medicationCoverRoles.has(user.role?.key),
    );
    const alternativeMedicationUsers = medicationReadyUsers.filter(
      (user) => user.id !== assignedUser?.id,
    );

    return (
      medicationReadyUsers.find((user) => user.id === assignedUser?.id) ??
      alternativeMedicationUsers[0] ??
      medicationReadyUsers[0] ??
      null
    );
  }

  if (assignedUser?.displayName === demoPrimaryCarerName) {
    return (
      nonErykUnassignedSameRoleUsers[0] ??
      nonErykUnassignedShiftUsers[0] ??
      unassignedSameRoleUsers[0] ??
      unassignedShiftUsers[0] ??
      sameRoleUsers[0] ??
      sortedUsers[0] ??
      null
    );
  }

  return (
    sortedUsers.find((user) => user.id === assignedUser?.id) ??
    sameRoleUsers[0] ??
    nonErykUnassignedShiftUsers[0] ??
    sortedUsers[0] ??
    null
  );
}

function buildCompletionTimestamp(dueAt, referenceTime) {
  if (!dueAt) {
    return new Date(referenceTime);
  }

  const preferredCompletionTime = addMinutes(dueAt, 24);
  const latestReasonableCompletionTime = addMinutes(referenceTime, -2);

  if (preferredCompletionTime <= dueAt) {
    return new Date(referenceTime);
  }

  if (latestReasonableCompletionTime <= dueAt) {
    return new Date(referenceTime);
  }

  return preferredCompletionTime < latestReasonableCompletionTime
    ? preferredCompletionTime
    : latestReasonableCompletionTime;
}

function buildCompletionNote(task, coveringUser) {
  if (
    task.assignedUser?.id &&
    task.assignedUser.id !== coveringUser.id &&
    task.assignedUser.displayName === demoPrimaryCarerName
  ) {
    return `Completed by ${coveringUser.displayName} after the task was picked up by another team member on the shift.`;
  }

  if (task.assignedUser?.id && task.assignedUser.id !== coveringUser.id) {
    return `Completed by ${coveringUser.displayName} after the task was covered on the shift.`;
  }

  return `Completed by ${coveringUser.displayName} during the next routine round.`;
}

async function main() {
  const now = new Date();
  const activeWindow = buildShiftWindow(now);
  const activeShifts = await prisma.shift.findMany({
    where: {
      status: 'ACTIVE',
    },
    orderBy: [{ floorNumber: 'asc' }, { startsAt: 'asc' }],
    select: {
      id: true,
      name: true,
      floorNumber: true,
      startsAt: true,
      endsAt: true,
    },
  });

  if (activeShifts.length === 0) {
    console.log('No active shifts found to refresh.');
    return;
  }

  const refreshedShifts = await prisma.$transaction(
    activeShifts.map((shift) =>
      prisma.shift.update({
        where: {
          id: shift.id,
        },
        data: {
          startsAt: new Date(activeWindow.startsAt),
          endsAt: new Date(activeWindow.endsAt),
        },
        select: {
          id: true,
          name: true,
          floorNumber: true,
          startsAt: true,
          endsAt: true,
        },
      }),
    ),
  );

  console.log(
    `Refreshed ${refreshedShifts.length} active shift windows to ${formatInZone(
      activeWindow.startsAt,
    )} -> ${formatInZone(activeWindow.endsAt)} (${demoTimeZone}).`,
  );

  for (const shift of refreshedShifts) {
    console.log(
      `- Floor ${shift.floorNumber}: ${shift.name} => ${formatInZone(
        shift.startsAt,
      )} -> ${formatInZone(shift.endsAt)}`,
    );
  }

  const overdueCutoff = addMinutes(now, -maxDemoOverdueMinutes);
  const refreshedShiftSnapshots = await prisma.shift.findMany({
    where: {
      id: {
        in: refreshedShifts.map((shift) => shift.id),
      },
    },
    orderBy: [{ floorNumber: 'asc' }, { startsAt: 'asc' }],
    select: {
      id: true,
      name: true,
      floorNumber: true,
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
      },
      tasks: {
        where: {
          status: {
            in: ['PENDING', 'OVERDUE'],
          },
          dueAt: {
            lt: overdueCutoff,
          },
        },
        orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
        select: {
          id: true,
          residentId: true,
          title: true,
          focus: true,
          status: true,
          dueAt: true,
          assignedUser: {
            select: {
              id: true,
              displayName: true,
              role: {
                select: {
                  key: true,
                },
              },
            },
          },
        },
      },
    },
  });

  const normalizedTasks = [];

  for (const shift of refreshedShiftSnapshots) {
    for (const task of shift.tasks) {
      const coveringUser = pickCoveringUser(task, shift.assignedUsers);

      if (!coveringUser) {
        continue;
      }

      const completionTime = buildCompletionTimestamp(task.dueAt, now);
      const completionNote = buildCompletionNote(task, coveringUser);

      await prisma.$transaction([
        prisma.task.update({
          where: {
            id: task.id,
          },
          data: {
            status: 'COMPLETED',
            statusNote: completionNote,
            statusUpdatedAt: completionTime,
          },
        }),
        prisma.auditEvent.create({
          data: {
            kind: 'TASK_COMPLETED',
            userId: coveringUser.id,
            shiftId: shift.id,
            taskId: task.id,
            residentId: task.residentId ?? null,
            details: {
              fromStatus: task.status,
              toStatus: 'COMPLETED',
              note: completionNote,
              source: 'demo-refresh',
              originalAssignedUserName: task.assignedUser?.displayName ?? null,
              completedByName: coveringUser.displayName,
            },
            createdAt: completionTime,
          },
        }),
      ]);

      normalizedTasks.push({
        floorNumber: shift.floorNumber,
        shiftName: shift.name,
        title: task.title,
        dueAt: task.dueAt,
        originalAssignedUserName: task.assignedUser?.displayName ?? 'Unassigned',
        completedByName: coveringUser.displayName,
      });
    }
  }

  if (normalizedTasks.length === 0) {
    console.log(
      `No active demo tasks were more than ${maxDemoOverdueMinutes} minutes overdue.`,
    );
    return;
  }

  console.log(
    `Marked ${normalizedTasks.length} active demo task${
      normalizedTasks.length === 1 ? '' : 's'
    } as completed so nothing stays overdue for more than ${maxDemoOverdueMinutes} minutes.`,
  );

  for (const task of normalizedTasks) {
    console.log(
      `- Floor ${task.floorNumber} ${task.shiftName}: "${task.title}" due ${formatInZone(
        task.dueAt,
      )} was covered by ${task.completedByName} (original assignee: ${task.originalAssignedUserName}).`,
    );
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
