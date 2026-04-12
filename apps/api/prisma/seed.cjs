const bcrypt = require('bcryptjs');
const { PrismaPg } = require('@prisma/adapter-pg');
const {
  PrismaClient,
  ResidentTimelineEntryType,
} = require('@prisma/client');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL must be defined before running the seed script.');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

const floorConfigs = [
  {
    floorNumber: 1,
    unitLabel: 'Willow Floor',
    roomStart: 1,
    names: [
      'Margaret Evans',
      'Raj Patel',
      'Edith Turner',
      'Thomas Green',
      'Amina Hussain',
      'Sheila Morgan',
      'Brian Foster',
      'Joan Clarke',
      'Peter Wallace',
      'Lily Bennett',
    ],
  },
  {
    floorNumber: 2,
    unitLabel: 'Maple Floor',
    roomStart: 11,
    names: [
      'Doris Miller',
      'George Ahmed',
      'Irene Collins',
      'Stanley Brooks',
      'Farah Ali',
      'Norma Price',
      'Colin Hughes',
      'June Carter',
      'Harold Dixon',
      'Mary Osei',
    ],
  },
  {
    floorNumber: 3,
    unitLabel: 'Cedar Floor',
    roomStart: 21,
    names: [
      'Agnes Cook',
      'David Singh',
      'Mabel Reed',
      'Arthur Lewis',
      'Nadia Rahman',
      'Jean Porter',
      'Frank Russell',
      'Olive Chapman',
      'Trevor Banks',
      'Rita Coleman',
    ],
  },
];

const recognitionImageKeys = ['resident-a', 'resident-b', 'resident-c', 'resident-d'];

const careSummaries = [
  'Hydration encouragement and morning comfort remain the main focus today.',
  'Observation follow-up and steady reassurance are the main priorities this shift.',
  'Mobility support and safe repositioning continue to need close attention.',
  'Personal care prompting should stay visible even when the morning is calm.',
  'Nutrition intake is being watched with gentle encouragement at meal times.',
  'Medication timing is stable but should remain visible in the shift context.',
  'Skin integrity checks and comfort positioning remain part of today\'s plan.',
  'Mood, reassurance, and continuity notes are especially useful today.',
  'Routine support is settled, with a reminder to keep small comfort needs visible.',
  'Current care is broadly stable, with one or two reminders to keep continuity strong.',
];

const timelineBlueprints = [
  {
    type: ResidentTimelineEntryType.CARE_GIVEN,
    title: 'Morning support completed',
    details:
      'Supported with the planned morning routine and checked comfort before breakfast.',
  },
  {
    type: ResidentTimelineEntryType.OBSERVATION,
    title: 'Observed as settled',
    details:
      'Observed as settled with no immediate concerns raised during the round.',
  },
  {
    type: ResidentTimelineEntryType.PERSONAL_CARE,
    title: 'Personal care recorded',
    details:
      'Personal care was supported with dignity and fresh clothing prepared afterwards.',
  },
  {
    type: ResidentTimelineEntryType.NUTRITION_HYDRATION,
    title: 'Hydration encouragement logged',
    details:
      'Encouraged fluids and recorded intake with the meal-time check.',
  },
  {
    type: ResidentTimelineEntryType.MOBILITY_REPOSITIONING,
    title: 'Repositioning support given',
    details:
      'Repositioning completed with comfort aids in place and a brief skin check noted.',
  },
  {
    type: ResidentTimelineEntryType.MEDICATION_NOTE,
    title: 'Medication note added',
    details:
      'Medication-related note recorded to keep timing and follow-up visible to the team.',
  },
  {
    type: ResidentTimelineEntryType.ESCALATION,
    title: 'Concern shared for monitoring',
    details:
      'Low-level concern shared with the senior carer so it stays visible through the shift.',
  },
];

function roomLabel(roomNumber) {
  return `Room ${roomNumber}`;
}

function residentSummary(index) {
  return careSummaries[index % careSummaries.length];
}

function pickTimelineBlueprint(seed) {
  return timelineBlueprints[seed % timelineBlueprints.length];
}

async function main() {
  const roles = [
    ['CARER', 'Carer'],
    ['SENIOR_CARER', 'Senior Carer'],
    ['MANAGER', 'Manager'],
  ];

  for (const [key, label] of roles) {
    await prisma.role.upsert({
      where: { key },
      update: { label },
      create: { key, label },
    });
  }

  const carerRole = await prisma.role.findUniqueOrThrow({
    where: { key: 'CARER' },
  });
  const managerRole = await prisma.role.findUniqueOrThrow({
    where: { key: 'MANAGER' },
  });

  const passwordHash = await bcrypt.hash('Password123!', 10);

  const user = await prisma.user.upsert({
    where: { email: 'carer@sercesync.local' },
    update: {
      displayName: 'Alex Carer',
      passwordHash,
      roleId: carerRole.id,
      isActive: true,
    },
    create: {
      email: 'carer@sercesync.local',
      displayName: 'Alex Carer',
      passwordHash,
      roleId: carerRole.id,
      isActive: true,
    },
  });

  await prisma.user.upsert({
    where: { email: 'manager@sercesync.local' },
    update: {
      displayName: 'Morgan Manager',
      passwordHash,
      roleId: managerRole.id,
      isActive: true,
    },
    create: {
      email: 'manager@sercesync.local',
      displayName: 'Morgan Manager',
      passwordHash,
      roleId: managerRole.id,
      isActive: true,
    },
  });

  await prisma.auditEvent.deleteMany();
  await prisma.handoverAcknowledgement.deleteMany();
  await prisma.residentTimelineMedia.deleteMany();
  await prisma.residentTimelineEntry.deleteMany();
  await prisma.handover.deleteMany();
  await prisma.task.deleteMany();
  await prisma.shift.deleteMany();
  await prisma.resident.deleteMany();

  const now = new Date();
  const startsAt = new Date(now.getTime() - 60 * 60 * 1000);
  const endsAt = new Date(now.getTime() + 7 * 60 * 60 * 1000);

  const residents = [];

  for (const floorConfig of floorConfigs) {
    for (const [index, fullName] of floorConfig.names.entries()) {
      const roomNumber = floorConfig.roomStart + index;
      const resident = await prisma.resident.create({
        data: {
          fullName,
          roomNumber,
          roomLabel: roomLabel(roomNumber),
          floorNumber: floorConfig.floorNumber,
          unitLabel: floorConfig.unitLabel,
          recognitionImageKey:
            recognitionImageKeys[(roomNumber - 1) % recognitionImageKeys.length],
          careSummary: residentSummary(roomNumber - 1),
          isActive: true,
        },
      });

      residents.push(resident);
    }
  }

  const activeShift = await prisma.shift.create({
    data: {
      name: 'Morning Care Shift',
      startsAt,
      endsAt,
      status: 'ACTIVE',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      assignedUsers: {
        connect: {
          id: user.id,
        },
      },
    },
  });

  await prisma.shift.create({
    data: {
      name: 'Tomorrow Care Shift',
      startsAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
      endsAt: new Date(now.getTime() + 32 * 60 * 60 * 1000),
      status: 'PLANNED',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      assignedUsers: {
        connect: {
          id: user.id,
        },
      },
    },
  });

  await prisma.shift.create({
    data: {
      name: 'Evening Relief Shift',
      startsAt: new Date(now.getTime() + 48 * 60 * 60 * 1000),
      endsAt: new Date(now.getTime() + 56 * 60 * 60 * 1000),
      status: 'PLANNED',
      floorNumber: 2,
      unitLabel: 'Maple Floor',
      assignedUsers: {
        connect: {
          id: user.id,
        },
      },
    },
  });

  await prisma.handover.create({
    data: {
      shiftId: activeShift.id,
      createdById: user.id,
      summary:
        'Willow Floor handover: Margaret Evans needs an early hydration check, Raj Patel has an observation follow-up before lunch, and Edith Turner remains on a repositioning timer. Please acknowledge the handover before beginning shift priorities.',
    },
  });

  const residentsByName = new Map(residents.map((resident) => [resident.fullName, resident]));

  const seededTasks = [
    {
      fullName: 'Margaret Evans',
      title: 'Hydration round for Margaret Evans',
      description:
        'Confirm fluid intake before breakfast and record whether encouragement was required.',
      dueAt: new Date(now.getTime() + 35 * 60 * 1000),
    },
    {
      fullName: 'Raj Patel',
      title: 'Observation follow-up for Raj Patel',
      description:
        'Repeat observations before lunch and note any changes from the overnight handover.',
      dueAt: new Date(now.getTime() + 95 * 60 * 1000),
    },
    {
      fullName: 'Edith Turner',
      title: 'Repositioning check for Edith Turner',
      description:
        'Review comfort positioning and record whether support surfaces remain in place.',
      dueAt: new Date(now.getTime() - 12 * 60 * 1000),
    },
    {
      fullName: 'Thomas Green',
      title: 'Personal care reminder for Thomas Green',
      description:
        'Review whether personal care prompting is still needed later in the shift.',
      dueAt: new Date(now.getTime() + 3 * 60 * 60 * 1000),
    },
  ];

  for (const seededTask of seededTasks) {
    const resident = residentsByName.get(seededTask.fullName);
    if (!resident) continue;

    await prisma.task.create({
      data: {
        shiftId: activeShift.id,
        residentId: resident.id,
        title: seededTask.title,
        description: seededTask.description,
        status: 'PENDING',
        dueAt: seededTask.dueAt,
        assignedUserId: user.id,
      },
    });
  }

  for (const [index, resident] of residents.entries()) {
    const timelineEntries = Array.from({ length: 3 }).map((_, entryIndex) => {
      const blueprint = pickTimelineBlueprint(index + entryIndex);
      const minutesAgo = index * 11 + entryIndex * 95 + 25;
      const createdAt = new Date(now.getTime() - minutesAgo * 60 * 1000);
      const useActiveShift = resident.floorNumber === 1 && createdAt >= startsAt;

      return {
        residentId: resident.id,
        type: blueprint.type,
        title: blueprint.title,
        details:
          entryIndex === 2
            ? `${blueprint.details} This was carried forward from the previous care window to keep continuity visible.`
            : blueprint.details,
        createdById: user.id,
        shiftId: useActiveShift ? activeShift.id : null,
        createdAt,
      };
    });

    await prisma.residentTimelineEntry.createMany({
      data: timelineEntries,
    });
  }

  console.log('Demo baseline reset complete.');
  console.log('This command removes resident, shift, handover, task, and audit demo data and recreates the standard local baseline.');
  console.log('Demo login: carer@sercesync.local / Password123!');
  console.log('Demo login: manager@sercesync.local / Password123!');
  console.log(`Seeded ${residents.length} fictional residents across 3 floors.`);
  console.log('Restored 4 live priority tasks for the active Willow Floor shift.');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
