const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL must be defined before reporting medication assignment gaps.',
  );
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  const tasks = await prisma.task.findMany({
    where: {
      focus: 'MEDICATION',
      status: {
        notIn: ['COMPLETED', 'DEFERRED'],
      },
      OR: [
        {
          assignedUserId: null,
        },
        {
          assignedUser: {
            role: {
              key: {
                not: 'NURSE',
              },
            },
          },
        },
      ],
    },
    include: {
      resident: {
        select: {
          fullName: true,
          roomLabel: true,
        },
      },
      shift: {
        select: {
          name: true,
          floorNumber: true,
          unitLabel: true,
          startsAt: true,
        },
      },
      assignedUser: {
        select: {
          displayName: true,
          email: true,
          role: {
            select: {
              key: true,
            },
          },
        },
      },
    },
    orderBy: [{ dueAt: 'asc' }, { createdAt: 'asc' }],
  });

  if (tasks.length === 0) {
    console.log(
      'No open medication tasks are assigned to non-nurses or left unassigned.',
    );
    return;
  }

  console.log(
    `Found ${tasks.length} open medication task(s) that need nurse reassignment:`,
  );
  console.table(
    tasks.map((task) => ({
      taskId: task.id,
      status: task.status,
      title: task.title,
      resident: task.resident?.fullName ?? 'Unknown resident',
      room: task.resident?.roomLabel ?? 'Unknown room',
      shift: task.shift.name,
      unit: `${task.shift.unitLabel} · Floor ${task.shift.floorNumber}`,
      shiftStartsAt: task.shift.startsAt.toISOString(),
      dueAt: task.dueAt?.toISOString() ?? 'No due time',
      assignedTo: task.assignedUser?.displayName ?? 'Unassigned',
      assignedEmail: task.assignedUser?.email ?? 'Unassigned',
      assignedRole: task.assignedUser?.role.key ?? 'UNASSIGNED',
    })),
  );
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
