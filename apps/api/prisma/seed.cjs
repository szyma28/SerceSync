const bcrypt = require('bcryptjs');
const { PrismaPg } = require('@prisma/adapter-pg');
const { residentProfilePresets } = require('./resident-profile-presets.cjs');
const {
  MealIntakeAmount,
  MealType,
  PrismaClient,
  IncidentCategory,
  IncidentSeverity,
  PersonalCareSubtype,
  ResidentPriorityLevel,
  ResidentTimelineEntryType,
  TaskClinicalPriority,
  TaskFocus,
} = require('@prisma/client');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL must be defined before running the seed script.',
  );
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});
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

const floorConfigs = [
  {
    floorNumber: 1,
    unitLabel: 'Willow Floor',
    roomStart: 1,
    names: [
      'Margaret Evans',
      'Emma Parker',
      'Elliot Turner',
      'Thea Green',
      'Amir Hussain',
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
      'Daniel Miller',
      'Alice Morton',
      'Isaac Collins',
      'Sophie Brooks',
      'Thomas Walker',
      'Simone Price',
      'Chloe Hughes',
      'James Carter',
      'Hannah Dixon',
      'Mark Osei',
    ],
  },
  {
    floorNumber: 3,
    unitLabel: 'Cedar Floor',
    roomStart: 21,
    names: [
      'Agnes Cook',
      'Zara Khan',
      'Mabel Reed',
      'Amelia Lewis',
      'Simon Fletcher',
      'Jean Porter',
      'Frank Russell',
      'Olive Chapman',
      'Tara Banks',
      'Ryan Coleman',
    ],
  },
];

const careSummaries = [
  'Hydration encouragement and morning comfort remain the main focus today.',
  'Observation follow-up and steady reassurance are the main priorities this shift.',
  'Mobility support and safe repositioning continue to need close attention.',
  'Personal care prompting should stay visible even when the morning is calm.',
  'Nutrition intake is being watched with gentle encouragement at meal times.',
  'Medication timing is stable but should remain visible in the shift context.',
  "Skin integrity checks and comfort positioning remain part of today's plan.",
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
    personalCareSubtype: PersonalCareSubtype.SHOWER,
    title: 'Personal care recorded',
    details:
      'Personal care was supported with dignity and fresh clothing prepared afterwards.',
  },
  {
    type: ResidentTimelineEntryType.NUTRITION_HYDRATION,
    title: 'Breakfast intake logged',
    details:
      'Breakfast intake recorded with no immediate concerns, and fluids were encouraged alongside the meal.',
    mealType: MealType.BREAKFAST,
    mealIntakeAmount: MealIntakeAmount.MOST,
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
      'Low-level concern shared with the nurse so it stays visible through the shift.',
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
    Date.UTC(dateParts.year, dateParts.month - 1, dateParts.day + dayOffset, 12),
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
      active: {
        label: 'Day Shift',
        startsAt: makeZonedDate(currentLocalDate, 8, 0),
        endsAt: makeZonedDate(currentLocalDate, 20, 0),
      },
      previous: {
        label: 'Night Shift',
        startsAt: makeZonedDate(previousLocalDate, 20, 0),
        endsAt: makeZonedDate(currentLocalDate, 8, 0),
      },
    };
  }

  if (localNow.hour < 8) {
    return {
      active: {
        label: 'Night Shift',
        startsAt: makeZonedDate(previousLocalDate, 20, 0),
        endsAt: makeZonedDate(currentLocalDate, 8, 0),
      },
      previous: {
        label: 'Day Shift',
        startsAt: makeZonedDate(previousLocalDate, 8, 0),
        endsAt: makeZonedDate(previousLocalDate, 20, 0),
      },
    };
  }

  return {
    active: {
      label: 'Night Shift',
      startsAt: makeZonedDate(currentLocalDate, 20, 0),
      endsAt: makeZonedDate(nextLocalDate, 8, 0),
    },
    previous: {
      label: 'Day Shift',
      startsAt: makeZonedDate(currentLocalDate, 8, 0),
      endsAt: makeZonedDate(currentLocalDate, 20, 0),
    },
  };
}

async function upsertDemoUser(prisma, { email, displayName, passwordHash, roleId }) {
  return prisma.user.upsert({
    where: { email },
    update: {
      displayName,
      passwordHash,
      roleId,
      isActive: true,
    },
    create: {
      email,
      displayName,
      passwordHash,
      roleId,
      isActive: true,
    },
  });
}

function buildShiftRelativeTimestamp(
  shift,
  referenceTime,
  preferredMinutesAgo,
  minimumMinutesIntoShift = 8,
) {
  const preferredTimestamp =
    referenceTime.getTime() - preferredMinutesAgo * 60 * 1000;
  const earliestTimestamp =
    shift.startsAt.getTime() + minimumMinutesIntoShift * 60 * 1000;
  const latestTimestamp = referenceTime.getTime() - 60 * 1000;

  return new Date(
    Math.min(latestTimestamp, Math.max(earliestTimestamp, preferredTimestamp)),
  );
}

async function main() {
  const roles = [
    ['CARER', 'Carer'],
    ['NURSE', 'Nurse'],
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
  const nurseRole = await prisma.role.findUniqueOrThrow({
    where: { key: 'NURSE' },
  });
  const managerRole = await prisma.role.findUniqueOrThrow({
    where: { key: 'MANAGER' },
  });

  const passwordHash = await bcrypt.hash('Password123!', 10);

  const demoUserSpecs = [
    {
      key: 'willowLeadCarer',
      email: 'carer@sercesync.local',
      displayName: 'Eryk Carer',
      roleId: carerRole.id,
    },
    {
      key: 'willowCarerTwo',
      email: 'willow-carer-2@sercesync.local',
      displayName: 'Hannah Cole',
      roleId: carerRole.id,
    },
    {
      key: 'willowCarerThree',
      email: 'willow-carer-3@sercesync.local',
      displayName: 'Ben Walsh',
      roleId: carerRole.id,
    },
    {
      key: 'willowCarerFour',
      email: 'willow-carer-4@sercesync.local',
      displayName: 'Aisha Malik',
      roleId: carerRole.id,
    },
    {
      key: 'willowNurse',
      email: 'nurse@sercesync.local',
      displayName: 'Nina Nurse',
      roleId: nurseRole.id,
    },
    {
      key: 'mapleLeadCarer',
      email: 'maple@sercesync.local',
      displayName: 'Mia Maple',
      roleId: carerRole.id,
    },
    {
      key: 'mapleCarerTwo',
      email: 'maple-carer-2@sercesync.local',
      displayName: 'Oliver Grant',
      roleId: carerRole.id,
    },
    {
      key: 'mapleCarerThree',
      email: 'maple-carer-3@sercesync.local',
      displayName: 'Grace Patel',
      roleId: carerRole.id,
    },
    {
      key: 'mapleCarerFour',
      email: 'maple-carer-4@sercesync.local',
      displayName: 'Noah Reed',
      roleId: carerRole.id,
    },
    {
      key: 'mapleNurse',
      email: 'maple-nurse@sercesync.local',
      displayName: 'Priya Shah',
      roleId: nurseRole.id,
    },
    {
      key: 'cedarLeadCarer',
      email: 'cedar@sercesync.local',
      displayName: 'Casey Cedar',
      roleId: carerRole.id,
    },
    {
      key: 'cedarCarerTwo',
      email: 'cedar-carer-2@sercesync.local',
      displayName: 'Ruby Shaw',
      roleId: carerRole.id,
    },
    {
      key: 'cedarCarerThree',
      email: 'cedar-carer-3@sercesync.local',
      displayName: 'Jacob Moore',
      roleId: carerRole.id,
    },
    {
      key: 'cedarCarerFour',
      email: 'cedar-carer-4@sercesync.local',
      displayName: 'Ella Stone',
      roleId: carerRole.id,
    },
    {
      key: 'cedarNurse',
      email: 'cedar-nurse@sercesync.local',
      displayName: 'Sana Ali',
      roleId: nurseRole.id,
    },
    {
      key: 'manager',
      email: 'manager@sercesync.local',
      displayName: 'Morgan Manager',
      roleId: managerRole.id,
    },
  ];
  const demoUsers = {};

  for (const demoUserSpec of demoUserSpecs) {
    demoUsers[demoUserSpec.key] = await upsertDemoUser(prisma, {
      ...demoUserSpec,
      passwordHash,
    });
  }

  const user = demoUsers.willowLeadCarer;
  const nurse = demoUsers.willowNurse;
  const mapleCarer = demoUsers.mapleLeadCarer;
  const cedarCarer = demoUsers.cedarLeadCarer;
  const manager = demoUsers.manager;
  const carersByFloorNumber = new Map([
    [
      1,
      [
        demoUsers.willowLeadCarer,
        demoUsers.willowCarerTwo,
        demoUsers.willowCarerThree,
        demoUsers.willowCarerFour,
      ],
    ],
    [
      2,
      [
        demoUsers.mapleLeadCarer,
        demoUsers.mapleCarerTwo,
        demoUsers.mapleCarerThree,
        demoUsers.mapleCarerFour,
      ],
    ],
    [
      3,
      [
        demoUsers.cedarLeadCarer,
        demoUsers.cedarCarerTwo,
        demoUsers.cedarCarerThree,
        demoUsers.cedarCarerFour,
      ],
    ],
  ]);
  const nursesByFloorNumber = new Map([
    [1, demoUsers.willowNurse],
    [2, demoUsers.mapleNurse],
    [3, demoUsers.cedarNurse],
  ]);
  const shiftStaffByFloorNumber = new Map(
    Array.from(carersByFloorNumber.entries()).map(([floorNumber, carers]) => [
      floorNumber,
      [...carers, nursesByFloorNumber.get(floorNumber)],
    ]),
  );

  await prisma.auditEvent.deleteMany();
  await prisma.medicationReconciliation.deleteMany();
  await prisma.medicationStockTransaction.deleteMany();
  await prisma.medicationAdministrationEvent.deleteMany();
  await prisma.medicationDoseInstance.deleteMany();
  await prisma.medicationSchedule.deleteMany();
  await prisma.pRNProtocol.deleteMany();
  await prisma.medicationStockRecord.deleteMany();
  await prisma.medicationAllergyIntolerance.deleteMany();
  await prisma.medicationChangeLog.deleteMany();
  await prisma.medicationOrder.deleteMany();
  await prisma.residentMedicationChart.deleteMany();
  await prisma.handoverAcknowledgement.deleteMany();
  await prisma.incidentMedia.deleteMany();
  await prisma.residentTimelineMedia.deleteMany();
  await prisma.incident.deleteMany();
  await prisma.residentTimelineEntry.deleteMany();
  await prisma.handover.deleteMany();
  await prisma.task.deleteMany();
  await prisma.shift.deleteMany();
  await prisma.resident.deleteMany();

  const now = new Date();
  const shiftWindow = buildShiftWindow(now);

  const residents = [];

  for (const floorConfig of floorConfigs) {
    for (const [index, fullName] of floorConfig.names.entries()) {
      const roomNumber = floorConfig.roomStart + index;
      const residentProfilePreset = residentProfilePresets[roomNumber - 1];
      const resident = await prisma.resident.create({
        data: {
          fullName,
          roomNumber,
          roomLabel: roomLabel(roomNumber),
          floorNumber: floorConfig.floorNumber,
          unitLabel: floorConfig.unitLabel,
          recognitionImageKey: residentProfilePreset.recognitionImageKey,
          careSummary: residentSummary(roomNumber - 1),
          aboutMe: residentProfilePreset.aboutMe,
          baselinePriority:
            floorConfig.floorNumber === 1 && fullName === 'Emma Parker'
              ? ResidentPriorityLevel.AMBER
              : ResidentPriorityLevel.GREEN,
          isActive: true,
        },
      });

      residents.push(resident);
    }
  }

  const activeShift = await prisma.shift.create({
    data: {
      name: `Willow ${shiftWindow.active.label}`,
      startsAt: shiftWindow.active.startsAt,
      endsAt: shiftWindow.active.endsAt,
      status: 'ACTIVE',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      assignedUsers: {
        connect: shiftStaffByFloorNumber
          .get(1)
          .map((staffMember) => ({ id: staffMember.id })),
      },
    },
  });

  const mapleActiveShift = await prisma.shift.create({
    data: {
      name: `Maple ${shiftWindow.active.label}`,
      startsAt: shiftWindow.active.startsAt,
      endsAt: shiftWindow.active.endsAt,
      status: 'ACTIVE',
      floorNumber: 2,
      unitLabel: 'Maple Floor',
      assignedUsers: {
        connect: shiftStaffByFloorNumber
          .get(2)
          .map((staffMember) => ({ id: staffMember.id })),
      },
    },
  });

  const cedarActiveShift = await prisma.shift.create({
    data: {
      name: `Cedar ${shiftWindow.active.label}`,
      startsAt: shiftWindow.active.startsAt,
      endsAt: shiftWindow.active.endsAt,
      status: 'ACTIVE',
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
      assignedUsers: {
        connect: shiftStaffByFloorNumber
          .get(3)
          .map((staffMember) => ({ id: staffMember.id })),
      },
    },
  });

  await prisma.shift.create({
    data: {
      name: `Willow ${shiftWindow.previous.label}`,
      startsAt: shiftWindow.previous.startsAt,
      endsAt: shiftWindow.previous.endsAt,
      status: 'COMPLETED',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      assignedUsers: {
        connect: [{ id: user.id }, { id: nurse.id }],
      },
    },
  });

  const willowHandover = await prisma.handover.create({
    data: {
      shiftId: activeShift.id,
      createdById: user.id,
      summary:
        'Willow Floor handover: the wider team has already covered most of the early personal care and breakfast routine. Eryk is picking up the remaining hydration, observation, and repositioning follow-ups while Nina continues the live medication round.',
    },
  });

  const mapleHandover = await prisma.handover.create({
    data: {
      shiftId: mapleActiveShift.id,
      createdById: mapleCarer.id,
      summary:
        'Maple Floor handover: the floor has had steady cover all morning, with reassurance checks, hydration prompts, and documentation already flowing across the team. Keep Daniel Miller and Simone Price visible through the next review window.',
    },
  });

  const cedarHandover = await prisma.handover.create({
    data: {
      shiftId: cedarActiveShift.id,
      createdById: cedarCarer.id,
      summary:
        'Cedar Floor handover: the team has completed the first comfort round and transfer support is already documented. Agnes Cook still needs pain monitoring after transfer support and Frank Russell remains on a comfort-positioning plan.',
    },
  });

  const residentsByName = new Map(
    residents.map((resident) => [resident.fullName, resident]),
  );
  const activeShiftByFloorNumber = new Map([
    [1, activeShift],
    [2, mapleActiveShift],
    [3, cedarActiveShift],
  ]);
  const handoverByFloorNumber = new Map([
    [1, willowHandover],
    [2, mapleHandover],
    [3, cedarHandover],
  ]);
  const handoverAcknowledgements = [];
  const handoverAuditEvents = [];

  for (const [floorNumber, shiftStaff] of shiftStaffByFloorNumber.entries()) {
    const shift =
      floorNumber === 1
        ? activeShift
        : floorNumber === 2
          ? mapleActiveShift
          : cedarActiveShift;
    const handover = handoverByFloorNumber.get(floorNumber);
    const userIdsToLeaveUnread =
      floorNumber === 1 ? new Set([user.id]) : new Set();

    shiftStaff
      .filter((staffMember) => !userIdsToLeaveUnread.has(staffMember.id))
      .forEach((staffMember, index) => {
        const acknowledgedAt = new Date(
          shift.startsAt.getTime() + (12 + index * 7) * 60 * 1000,
        );

        handoverAcknowledgements.push({
          handoverId: handover.id,
          acknowledgedById: staffMember.id,
          acknowledgedAt,
        });
        handoverAuditEvents.push({
          kind: 'HANDOVER_ACKNOWLEDGED',
          userId: staffMember.id,
          shiftId: shift.id,
          details: {
            handoverId: handover.id,
          },
          createdAt: acknowledgedAt,
        });
      });
  }

  await prisma.handoverAcknowledgement.createMany({
    data: handoverAcknowledgements,
  });
  await prisma.auditEvent.createMany({
    data: handoverAuditEvents,
  });
  const timelineAuthorsByFloorNumber = new Map([
    [1, shiftStaffByFloorNumber.get(1)],
    [2, shiftStaffByFloorNumber.get(2)],
    [3, shiftStaffByFloorNumber.get(3)],
  ]);
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);
  const medicationResidents = [
    residentsByName.get('Emma Parker'),
    residentsByName.get('Amir Hussain'),
    residentsByName.get('Lily Bennett'),
    residentsByName.get('Margaret Evans'),
    residentsByName.get('Joan Clarke'),
    residentsByName.get('Brian Foster'),
  ].filter(Boolean);

  const chartsByResidentId = new Map();
  for (const resident of medicationResidents) {
    const chart = await prisma.residentMedicationChart.create({
      data: {
        residentId: resident.id,
        status: 'ACTIVE',
        createdByUserId: manager.id,
        reviewedByUserId: manager.id,
      },
    });
    chartsByResidentId.set(resident.id, chart);
  }

  const emmaResident = residentsByName.get('Emma Parker');
  const emmaMorningOrder = await prisma.medicationOrder.create({
    data: {
      residentId: emmaResident.id,
      chartId: chartsByResidentId.get(emmaResident.id).id,
      medicationName: 'Donepezil',
      formulation: 'tablet',
      strength: '5mg tablet',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'oral',
      instructions:
        'Give once each morning after handover acknowledgement, following the current MAR directions.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: false,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  const emmaMorningSchedule = await prisma.medicationSchedule.create({
    data: {
      medicationOrderId: emmaMorningOrder.id,
      roundLabel: 'MORNING',
      anchorType: 'HANDOVER_ACKNOWLEDGED',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
      active: true,
    },
  });

  const amirResident = residentsByName.get('Amir Hussain');
  const amirMiddayOrder = await prisma.medicationOrder.create({
    data: {
      residentId: amirResident.id,
      chartId: chartsByResidentId.get(amirResident.id).id,
      medicationName: 'Ramipril',
      formulation: 'capsule',
      strength: '2.5mg capsule',
      doseAmount: '1',
      doseUnit: 'capsule',
      route: 'oral',
      instructions:
        'Give at the midday round in line with the current MAR and fluids plan.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: false,
      sourceType: 'PHARMACY_SUPPLIED',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  const amirMiddaySchedule = await prisma.medicationSchedule.create({
    data: {
      medicationOrderId: amirMiddayOrder.id,
      roundLabel: 'MIDDAY',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 150,
      windowEndOffsetMinutes: 210,
      active: true,
    },
  });

  const lilyResident = residentsByName.get('Lily Bennett');
  const lilyBedtimeOrder = await prisma.medicationOrder.create({
    data: {
      residentId: lilyResident.id,
      chartId: chartsByResidentId.get(lilyResident.id).id,
      medicationName: 'Melatonin',
      formulation: 'tablet',
      strength: '2mg tablet',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'oral',
      instructions:
        'Offer at bedtime if the resident is ready for sleep, following the current MAR.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: false,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  await prisma.medicationSchedule.create({
    data: {
      medicationOrderId: lilyBedtimeOrder.id,
      roundLabel: 'BEDTIME',
      anchorType: 'FIXED_TIME',
      fixedTimeLocal: '20:00',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
      active: true,
    },
  });

  const margaretResident = residentsByName.get('Margaret Evans');
  const margaretPrnOrder = await prisma.medicationOrder.create({
    data: {
      residentId: margaretResident.id,
      chartId: chartsByResidentId.get(margaretResident.id).id,
      medicationName: 'Paracetamol',
      formulation: 'oral suspension',
      strength: '250mg/5ml',
      doseAmount: '10',
      doseUnit: 'ml',
      route: 'oral',
      instructions:
        'Offer when pain is reported or clearly observed, following the current PRN instructions.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: true,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  await prisma.pRNProtocol.create({
    data: {
      residentId: margaretResident.id,
      medicationOrderId: margaretPrnOrder.id,
      indication: 'Pain or visible discomfort',
      whenToOffer:
        'Offer when the resident reports pain or shows clear discomfort after movement.',
      doseInstructions:
        'Give 10ml by mouth as required, using the prescribed PRN directions on the MAR.',
      minimumIntervalMinutes: 240,
      maxDosePer24Hours: 4,
      expectedEffect: 'Pain should ease within 30 to 45 minutes.',
      monitoringRequired: 'Re-check comfort and mobility after 30 minutes.',
      whenToEscalate:
        'Escalate if pain continues, increases, or the resident becomes distressed.',
      active: true,
      createdByUserId: manager.id,
    },
  });

  const joanResident = residentsByName.get('Joan Clarke');
  const joanMorningOrder = await prisma.medicationOrder.create({
    data: {
      residentId: joanResident.id,
      chartId: chartsByResidentId.get(joanResident.id).id,
      medicationName: 'Aspirin',
      formulation: 'tablet',
      strength: '75mg tablet',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'oral',
      instructions:
        'Give with the morning round, following the current MAR instructions.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: false,
      requiresWitness: false,
      isPRN: false,
      sourceType: 'PHARMACY_SUPPLIED',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  const joanMorningSchedule = await prisma.medicationSchedule.create({
    data: {
      medicationOrderId: joanMorningOrder.id,
      roundLabel: 'MORNING',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
      active: true,
    },
  });

  const brianResident = residentsByName.get('Brian Foster');
  const brianControlledDrugOrder = await prisma.medicationOrder.create({
    data: {
      residentId: brianResident.id,
      chartId: chartsByResidentId.get(brianResident.id).id,
      medicationName: 'Morphine Sulfate',
      formulation: 'oral solution',
      strength: '10mg/5ml',
      doseAmount: '2.5',
      doseUnit: 'ml',
      route: 'oral',
      instructions:
        'Witnessed administration required. Follow the controlled-drug entry and current MAR instructions.',
      startDate: startOfToday,
      isActive: true,
      isControlledDrug: true,
      requiresWitness: true,
      isPRN: false,
      sourceType: 'MANUAL_ENTRY',
      createdByUserId: manager.id,
      updatedByUserId: manager.id,
    },
  });
  await prisma.medicationSchedule.create({
    data: {
      medicationOrderId: brianControlledDrugOrder.id,
      roundLabel: 'EVENING',
      anchorType: 'FIXED_TIME',
      fixedTimeLocal: '18:00',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
      active: true,
    },
  });

  const emarOrders = [
    emmaMorningOrder,
    amirMiddayOrder,
    lilyBedtimeOrder,
    margaretPrnOrder,
    joanMorningOrder,
    brianControlledDrugOrder,
  ];

  for (const order of emarOrders) {
    await prisma.medicationChangeLog.create({
      data: {
        medicationOrderId: order.id,
        residentId: order.residentId,
        changedByUserId: manager.id,
        changeType: 'CREATED',
        previousValueJson: null,
        newValueJson: {
          medicationName: order.medicationName,
          doseAmount: order.doseAmount,
          doseUnit: order.doseUnit,
          route: order.route,
          instructions: order.instructions,
          isPRN: order.isPRN,
        },
        reason: 'Initial medication order recorded during chart setup.',
      },
    });
    await prisma.auditEvent.create({
      data: {
        kind: 'MEDICATION_ORDER_CREATED',
        userId: manager.id,
        residentId: order.residentId,
        medicationOrderId: order.id,
        details: {
          medicationName: order.medicationName,
          source: 'seed',
        },
      },
    });
  }

  await prisma.medicationAllergyIntolerance.create({
    data: {
      residentId: emmaResident.id,
      substance: 'Penicillin',
      reaction: 'Rash',
      severity: 'Moderate',
      recordedByUserId: manager.id,
    },
  });

  const joanRefusedDoseInstance = await prisma.medicationDoseInstance.create({
    data: {
      residentId: joanResident.id,
      medicationOrderId: joanMorningOrder.id,
      scheduleId: joanMorningSchedule.id,
      shiftId: activeShift.id,
      dueWindowStart: new Date(activeShift.startsAt.getTime()),
      dueWindowEnd: new Date(activeShift.startsAt.getTime() + 60 * 60 * 1000),
      status: 'REFUSED',
      generatedAt: new Date(activeShift.startsAt.getTime() + 5 * 60 * 1000),
      recordedByUserId: nurse.id,
      recordedAt: new Date(now.getTime() - 26 * 60 * 1000),
      reason: 'Resident declined after explanation.',
      notes: 'Re-offer planned later if the resident agrees.',
      requiresWitness: false,
    },
  });
  await prisma.medicationAdministrationEvent.create({
    data: {
      doseInstanceId: joanRefusedDoseInstance.id,
      residentId: joanResident.id,
      medicationOrderId: joanMorningOrder.id,
      shiftId: activeShift.id,
      eventType: 'REFUSED',
      doseUnit: joanMorningOrder.doseUnit,
      reason: 'Resident declined after explanation.',
      notes: 'Re-offer planned later if the resident agrees.',
      recordedByUserId: nurse.id,
      recordedAt: new Date(now.getTime() - 26 * 60 * 1000),
    },
  });

  const amirWindowStart = buildShiftRelativeTimestamp(activeShift, now, 42, 14);
  const amirGeneratedAt = new Date(amirWindowStart.getTime() + 4 * 60 * 1000);
  const amirRecordedAt = buildShiftRelativeTimestamp(activeShift, now, 18, 28);
  const amirWindowEnd = new Date(
    Math.min(
      activeShift.endsAt.getTime(),
      Math.max(
        amirRecordedAt.getTime() + 8 * 60 * 1000,
        amirWindowStart.getTime() + 42 * 60 * 1000,
      ),
    ),
  );

  const amirAdministeredDoseInstance = await prisma.medicationDoseInstance.create({
    data: {
      residentId: amirResident.id,
      medicationOrderId: amirMiddayOrder.id,
      scheduleId: amirMiddaySchedule.id,
      shiftId: activeShift.id,
      dueWindowStart: amirWindowStart,
      dueWindowEnd: amirWindowEnd,
      status: 'ADMINISTERED',
      generatedAt: amirGeneratedAt,
      recordedByUserId: nurse.id,
      recordedAt: amirRecordedAt,
      reason: 'Administered with the resident lunch tray.',
      notes: 'Resident took the dose with lunch and remained settled afterwards.',
      requiresWitness: false,
    },
  });
  await prisma.medicationAdministrationEvent.create({
    data: {
      doseInstanceId: amirAdministeredDoseInstance.id,
      residentId: amirResident.id,
      medicationOrderId: amirMiddayOrder.id,
      shiftId: activeShift.id,
      eventType: 'ADMINISTERED',
      doseGiven: '1',
      doseUnit: amirMiddayOrder.doseUnit,
      reason: 'Administered with the resident lunch tray.',
      notes: 'Resident took the dose with lunch and remained settled afterwards.',
      recordedByUserId: nurse.id,
      recordedAt: amirRecordedAt,
    },
  });

  const margaretPrnAdministeredAt = new Date(now.getTime() - 40 * 60 * 1000);
  await prisma.medicationAdministrationEvent.create({
    data: {
      residentId: margaretResident.id,
      medicationOrderId: margaretPrnOrder.id,
      shiftId: activeShift.id,
      eventType: 'PRN_ADMINISTERED',
      doseGiven: '10',
      doseUnit: 'ml',
      reason: 'Pain in right hip after mobilising.',
      notes: 'Comfort improved after the dose.',
      recordedByUserId: nurse.id,
      recordedAt: margaretPrnAdministeredAt,
    },
  });

  await prisma.medicationStockRecord.createMany({
    data: [
      {
        residentId: emmaResident.id,
        medicationOrderId: emmaMorningOrder.id,
        currentQuantity: '28',
        quantityUnit: 'tablet',
        lastCheckedByUserId: nurse.id,
        lastCheckedAt: new Date(now.getTime() - 55 * 60 * 1000),
        notes: 'Morning blister pack checked at shift start.',
      },
      {
        residentId: margaretResident.id,
        medicationOrderId: margaretPrnOrder.id,
        currentQuantity: '180',
        quantityUnit: 'ml',
        lastCheckedByUserId: nurse.id,
        lastCheckedAt: new Date(now.getTime() - 50 * 60 * 1000),
        notes: 'Bottle opened this week and quantity estimated.',
      },
      {
        residentId: brianResident.id,
        medicationOrderId: brianControlledDrugOrder.id,
        currentQuantity: '45',
        quantityUnit: 'ml',
        lastCheckedByUserId: nurse.id,
        lastCheckedAt: new Date(now.getTime() - 45 * 60 * 1000),
        notes: 'Controlled drug balance checked with witness.',
      },
    ],
  });

  const brianStockRecord = await prisma.medicationStockRecord.findUnique({
    where: {
      medicationOrderId: brianControlledDrugOrder.id,
    },
  });
  if (brianStockRecord) {
    await prisma.medicationStockTransaction.create({
      data: {
        stockRecordId: brianStockRecord.id,
        residentId: brianResident.id,
        medicationOrderId: brianControlledDrugOrder.id,
        transactionType: 'RECEIVED',
        quantity: '50',
        quantityUnit: 'ml',
        recordedByUserId: nurse.id,
        witnessUserId: manager.id,
        reason: 'Controlled-drug balance confirmed during opening stock check.',
      },
    });
  }

  await prisma.residentTimelineEntry.createMany({
    data: [
      {
        residentId: joanResident.id,
        type: ResidentTimelineEntryType.MEDICATION_NOTE,
        title: 'Morning medication refused',
        details:
          '08:52 — Morning medication refused. Reason: resident declined.',
        createdById: nurse.id,
        shiftId: activeShift.id,
        createdAt: new Date(now.getTime() - 25 * 60 * 1000),
      },
      {
        residentId: amirResident.id,
        type: ResidentTimelineEntryType.MEDICATION_NOTE,
        title: 'Midday medication administered',
        details:
          '12:22 — Midday medication administered with lunch and recorded without any delay.',
        createdById: nurse.id,
        shiftId: activeShift.id,
        createdAt: new Date(now.getTime() - 17 * 60 * 1000),
      },
      {
        residentId: margaretResident.id,
        type: ResidentTimelineEntryType.MEDICATION_NOTE,
        title: 'PRN paracetamol administered',
        details:
          '14:15 — PRN Paracetamol administered for pain after mobilising.',
        createdById: nurse.id,
        shiftId: activeShift.id,
        createdAt: margaretPrnAdministeredAt,
      },
    ],
  });

  await prisma.auditEvent.createMany({
    data: [
      {
        kind: 'MEDICATION_ALLERGY_RECORDED',
        userId: manager.id,
        residentId: emmaResident.id,
        details: {
          substance: 'Penicillin',
          source: 'seed',
        },
      },
      {
        kind: 'MEDICATION_DOSE_REFUSED',
        userId: nurse.id,
        shiftId: activeShift.id,
        residentId: joanResident.id,
        medicationOrderId: joanMorningOrder.id,
        medicationDoseInstanceId: joanRefusedDoseInstance.id,
        details: {
          medicationName: joanMorningOrder.medicationName,
          reason: 'Resident declined after explanation.',
          source: 'seed',
        },
      },
      {
        kind: 'MEDICATION_DOSE_ADMINISTERED',
        userId: nurse.id,
        shiftId: activeShift.id,
        residentId: amirResident.id,
        medicationOrderId: amirMiddayOrder.id,
        medicationDoseInstanceId: amirAdministeredDoseInstance.id,
        details: {
          medicationName: amirMiddayOrder.medicationName,
          roundLabel: amirMiddaySchedule.roundLabel,
          reason: 'Administered with the resident lunch tray.',
          source: 'seed',
        },
      },
      {
        kind: 'MEDICATION_PRN_EVENT_RECORDED',
        userId: nurse.id,
        shiftId: activeShift.id,
        residentId: margaretResident.id,
        medicationOrderId: margaretPrnOrder.id,
        details: {
          medicationName: margaretPrnOrder.medicationName,
          eventType: 'PRN_ADMINISTERED',
          source: 'seed',
        },
      },
      {
        kind: 'MEDICATION_STOCK_TRANSACTION_RECORDED',
        userId: nurse.id,
        residentId: brianResident.id,
        medicationOrderId: brianControlledDrugOrder.id,
        details: {
          medicationName: brianControlledDrugOrder.medicationName,
          transactionType: 'RECEIVED',
          source: 'seed',
        },
      },
    ],
  });

  const willowCompletedTaskTimes = {
    sheila: buildShiftRelativeTimestamp(activeShift, now, 210, 12),
    peter: buildShiftRelativeTimestamp(activeShift, now, 180, 18),
    brian: buildShiftRelativeTimestamp(activeShift, now, 150, 24),
    margaret: buildShiftRelativeTimestamp(activeShift, now, 120, 31),
  };
  const mapleCompletedTaskTimes = {
    daniel: buildShiftRelativeTimestamp(mapleActiveShift, now, 95, 14),
    alice: buildShiftRelativeTimestamp(mapleActiveShift, now, 78, 20),
    mark: buildShiftRelativeTimestamp(mapleActiveShift, now, 64, 27),
    thomas: buildShiftRelativeTimestamp(mapleActiveShift, now, 52, 34),
  };
  const cedarCompletedTaskTimes = {
    zara: buildShiftRelativeTimestamp(cedarActiveShift, now, 70, 16),
    frank: buildShiftRelativeTimestamp(cedarActiveShift, now, 58, 22),
    olive: buildShiftRelativeTimestamp(cedarActiveShift, now, 46, 29),
    agnes: buildShiftRelativeTimestamp(cedarActiveShift, now, 34, 36),
  };

  const seededTasks = [
    {
      fullName: 'Margaret Evans',
      title: 'Hydration round for Margaret Evans',
      description:
        'Confirm fluid intake before lunch and record whether encouragement was required.',
      dueAt: new Date(now.getTime() + 35 * 60 * 1000),
      focus: TaskFocus.HYDRATION,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: activeShift.id,
      assignedUser: user,
      status: 'PENDING',
    },
    {
      fullName: 'Emma Parker',
      title: 'Observation follow-up for Emma Parker',
      description:
        'Repeat observations before lunch and note any changes from the earlier reassurance round.',
      dueAt: new Date(now.getTime() + 95 * 60 * 1000),
      focus: TaskFocus.OBSERVATION,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: activeShift.id,
      assignedUser: user,
      status: 'PENDING',
    },
    {
      fullName: 'Elliot Turner',
      title: 'Repositioning check for Elliot Turner',
      description:
        'Review comfort positioning and record whether support surfaces remain in place.',
      dueAt: new Date(now.getTime() - 12 * 60 * 1000),
      focus: TaskFocus.MOBILITY,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: activeShift.id,
      assignedUser: user,
      status: 'PENDING',
    },
    {
      fullName: 'Thea Green',
      title: 'Personal care reminder for Thea Green',
      description:
        'Review whether personal care prompting is still needed later in the shift.',
      dueAt: new Date(now.getTime() + 3 * 60 * 60 * 1000),
      focus: TaskFocus.PERSONAL_CARE,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: activeShift.id,
      assignedUser: user,
      status: 'PENDING',
    },
    {
      fullName: 'Emma Parker',
      title: 'Medication round for Emma Parker',
      description:
        'Time-critical morning medications are due before the next observation round.',
      dueAt: new Date(now.getTime() + 25 * 60 * 1000),
      focus: TaskFocus.MEDICATION,
      clinicalPriority: TaskClinicalPriority.TIME_CRITICAL,
      shiftId: activeShift.id,
      assignedUser: nurse,
      status: 'PENDING',
    },
    {
      fullName: 'Simone Price',
      title: 'Hydration follow-up for Simone Price',
      description:
        'Complete a lunchtime hydration prompt and record how much fluid was accepted.',
      dueAt: new Date(now.getTime() + 65 * 60 * 1000),
      focus: TaskFocus.HYDRATION,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: mapleActiveShift.id,
      assignedUser: demoUsers.mapleCarerFour,
      status: 'PENDING',
    },
    {
      fullName: 'Agnes Cook',
      title: 'Comfort repositioning for Agnes Cook',
      description:
        'Re-check pressure relief, cushions, and comfort after the last transfer review.',
      dueAt: new Date(now.getTime() + 55 * 60 * 1000),
      focus: TaskFocus.MOBILITY,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: cedarActiveShift.id,
      assignedUser: cedarCarer,
      status: 'PENDING',
    },
    {
      fullName: 'Sheila Morgan',
      title: 'Morning personal care for Sheila Morgan',
      description:
        'Supported wash, oral care, and fresh clothing were completed before breakfast.',
      dueAt: new Date(activeShift.startsAt.getTime() + 55 * 60 * 1000),
      focus: TaskFocus.PERSONAL_CARE,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: activeShift.id,
      assignedUser: demoUsers.willowCarerTwo,
      status: 'COMPLETED',
      statusNote: 'Completed calmly with reassurance and no concerns.',
      statusUpdatedAt: willowCompletedTaskTimes.sheila,
    },
    {
      fullName: 'Peter Wallace',
      title: 'Breakfast support for Peter Wallace',
      description:
        'Breakfast encouragement and fluid support were completed in the dining area.',
      dueAt: new Date(activeShift.startsAt.getTime() + 85 * 60 * 1000),
      focus: TaskFocus.HYDRATION,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: activeShift.id,
      assignedUser: demoUsers.willowCarerThree,
      status: 'COMPLETED',
      statusNote: 'Completed with most breakfast taken and fluids encouraged.',
      statusUpdatedAt: willowCompletedTaskTimes.peter,
    },
    {
      fullName: 'Brian Foster',
      title: 'Comfort review for Brian Foster',
      description:
        'Early comfort review completed with pillows adjusted before the next round.',
      dueAt: new Date(activeShift.startsAt.getTime() + 120 * 60 * 1000),
      focus: TaskFocus.GENERAL,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: activeShift.id,
      assignedUser: demoUsers.willowCarerFour,
      status: 'COMPLETED',
      statusNote: 'Completed and handed over with no immediate concerns.',
      statusUpdatedAt: willowCompletedTaskTimes.brian,
    },
    {
      fullName: 'Margaret Evans',
      title: 'PRN comfort follow-up for Margaret Evans',
      description:
        'Follow-up completed after the earlier PRN dose and comfort improved.',
      dueAt: new Date(now.getTime() - 80 * 60 * 1000),
      focus: TaskFocus.MEDICATION,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: activeShift.id,
      assignedUser: nurse,
      status: 'COMPLETED',
      statusNote: 'Completed after PRN review with pain reduced.',
      statusUpdatedAt: willowCompletedTaskTimes.margaret,
    },
    {
      fullName: 'Daniel Miller',
      title: 'Reassurance round for Daniel Miller',
      description:
        'Reassurance and orientation prompts were completed after the earlier confusion episode.',
      dueAt: new Date(mapleActiveShift.startsAt.getTime() + 95 * 60 * 1000),
      focus: TaskFocus.OBSERVATION,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: mapleActiveShift.id,
      assignedUser: mapleCarer,
      status: 'COMPLETED',
      statusNote: 'Completed with Daniel settled in the lounge afterwards.',
      statusUpdatedAt: mapleCompletedTaskTimes.daniel,
    },
    {
      fullName: 'Alice Morton',
      title: 'Comfort check for Alice Morton',
      description:
        'Morning comfort check completed and she remained settled after the room round.',
      dueAt: new Date(mapleActiveShift.startsAt.getTime() + 125 * 60 * 1000),
      focus: TaskFocus.GENERAL,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: mapleActiveShift.id,
      assignedUser: demoUsers.mapleCarerTwo,
      status: 'COMPLETED',
      statusNote: 'Completed with no follow-up concerns.',
      statusUpdatedAt: mapleCompletedTaskTimes.alice,
    },
    {
      fullName: 'Mark Osei',
      title: 'Post-breakfast wellbeing review for Mark Osei',
      description:
        'Morning wellbeing review completed with fluids encouraged and routine maintained.',
      dueAt: new Date(mapleActiveShift.startsAt.getTime() + 150 * 60 * 1000),
      focus: TaskFocus.OBSERVATION,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: mapleActiveShift.id,
      assignedUser: demoUsers.mapleCarerThree,
      status: 'COMPLETED',
      statusNote: 'Completed and documented for continuity.',
      statusUpdatedAt: mapleCompletedTaskTimes.mark,
    },
    {
      fullName: 'Thomas Walker',
      title: 'Lunch preparation review for Thomas Walker',
      description:
        'Pre-lunch routine reviewed early so intake support stays organised for the team.',
      dueAt: new Date(mapleActiveShift.startsAt.getTime() + 175 * 60 * 1000),
      focus: TaskFocus.GENERAL,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: mapleActiveShift.id,
      assignedUser: demoUsers.mapleNurse,
      status: 'COMPLETED',
      statusNote: 'Completed and handed over to the lunch support round.',
      statusUpdatedAt: mapleCompletedTaskTimes.thomas,
    },
    {
      fullName: 'Zara Khan',
      title: 'Personal care follow-up for Zara Khan',
      description:
        'Personal care follow-up completed with skin care and clothing refreshed.',
      dueAt: new Date(cedarActiveShift.startsAt.getTime() + 105 * 60 * 1000),
      focus: TaskFocus.PERSONAL_CARE,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: cedarActiveShift.id,
      assignedUser: demoUsers.cedarCarerTwo,
      status: 'COMPLETED',
      statusNote: 'Completed with the resident comfortable afterwards.',
      statusUpdatedAt: cedarCompletedTaskTimes.zara,
    },
    {
      fullName: 'Frank Russell',
      title: 'Pressure-area review for Frank Russell',
      description:
        'Pressure-area comfort review completed and support surfaces checked.',
      dueAt: new Date(cedarActiveShift.startsAt.getTime() + 135 * 60 * 1000),
      focus: TaskFocus.MOBILITY,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: cedarActiveShift.id,
      assignedUser: demoUsers.cedarCarerThree,
      status: 'COMPLETED',
      statusNote: 'Completed with comfort aids still in place.',
      statusUpdatedAt: cedarCompletedTaskTimes.frank,
    },
    {
      fullName: 'Olive Chapman',
      title: 'Nutrition support for Olive Chapman',
      description:
        'Mid-morning snack and fluids were supported and documented for continuity.',
      dueAt: new Date(cedarActiveShift.startsAt.getTime() + 165 * 60 * 1000),
      focus: TaskFocus.HYDRATION,
      clinicalPriority: TaskClinicalPriority.ROUTINE,
      shiftId: cedarActiveShift.id,
      assignedUser: demoUsers.cedarCarerFour,
      status: 'COMPLETED',
      statusNote: 'Completed with most fluids accepted.',
      statusUpdatedAt: cedarCompletedTaskTimes.olive,
    },
    {
      fullName: 'Agnes Cook',
      title: 'Post-transfer review for Agnes Cook',
      description:
        'Pain review and reassurance completed straight after the earlier transfer support.',
      dueAt: new Date(cedarActiveShift.startsAt.getTime() + 180 * 60 * 1000),
      focus: TaskFocus.OBSERVATION,
      clinicalPriority: TaskClinicalPriority.PRIORITY,
      shiftId: cedarActiveShift.id,
      assignedUser: demoUsers.cedarNurse,
      status: 'COMPLETED',
      statusNote: 'Completed with pain still under close observation.',
      statusUpdatedAt: cedarCompletedTaskTimes.agnes,
    },
  ];

  for (const seededTask of seededTasks) {
    const resident = residentsByName.get(seededTask.fullName);
    if (!resident) continue;

    const task = await prisma.task.create({
      data: {
        shiftId: seededTask.shiftId,
        residentId: resident.id,
        title: seededTask.title,
        description: seededTask.description,
        focus: seededTask.focus,
        clinicalPriority: seededTask.clinicalPriority,
        status: seededTask.status,
        dueAt: seededTask.dueAt,
        statusNote: seededTask.statusNote ?? null,
        statusUpdatedAt: seededTask.statusUpdatedAt ?? null,
        assignedUserId: seededTask.assignedUser.id,
      },
    });

    if (seededTask.status === 'COMPLETED') {
      await prisma.auditEvent.create({
        data: {
          kind: 'TASK_COMPLETED',
          userId: seededTask.assignedUser.id,
          shiftId: seededTask.shiftId,
          taskId: task.id,
          details: {
            fromStatus: 'PENDING',
            toStatus: 'COMPLETED',
            note: seededTask.statusNote ?? null,
          },
          createdAt: seededTask.statusUpdatedAt ?? new Date(),
        },
      });
    }
  }

  for (const [index, resident] of residents.entries()) {
    const timelineEntries = Array.from({ length: 3 }).map((_, entryIndex) => {
      const blueprint = pickTimelineBlueprint(index + entryIndex);
      const minutesAgo = index * 11 + entryIndex * 95 + 25;
      const createdAt = new Date(now.getTime() - minutesAgo * 60 * 1000);
      const floorActiveShift =
        activeShiftByFloorNumber.get(resident.floorNumber) ?? null;
      const floorTimelineAuthors =
        timelineAuthorsByFloorNumber.get(resident.floorNumber) ?? [user];
      const rotatedAuthor =
        floorTimelineAuthors[
          (index + entryIndex) % floorTimelineAuthors.length
        ] ?? user;
      const useActiveShift =
        floorActiveShift != null &&
        createdAt >= floorActiveShift.startsAt &&
        createdAt <= floorActiveShift.endsAt;

      return {
        residentId: resident.id,
        type: blueprint.type,
        personalCareSubtype: blueprint.personalCareSubtype ?? null,
        mealType: blueprint.mealType ?? null,
        mealIntakeAmount: blueprint.mealIntakeAmount ?? null,
        title: blueprint.title,
        details:
          entryIndex === 2
            ? `${blueprint.details} This was carried forward from the previous care window to keep continuity visible.`
            : blueprint.details,
        createdById:
          blueprint.type === ResidentTimelineEntryType.MEDICATION_NOTE
            ? (nursesByFloorNumber.get(resident.floorNumber)?.id ??
              rotatedAuthor.id)
            : rotatedAuthor.id,
        shiftId: useActiveShift ? floorActiveShift.id : null,
        createdAt,
      };
    });

    await prisma.residentTimelineEntry.createMany({
      data: timelineEntries,
    });
  }

  await prisma.residentTimelineEntry.createMany({
    data: [
      {
        residentId: residentsByName.get('Emma Parker').id,
        type: ResidentTimelineEntryType.OBSERVATION,
        title: 'Follow-up prepared for Eryk',
        details:
          'Morning room support is complete and the next reassurance review has been left ready for Eryk to pick up.',
        createdById: demoUsers.willowCarerTwo.id,
        shiftId: activeShift.id,
        createdAt: new Date(now.getTime() - 29 * 60 * 1000),
      },
      {
        residentId: residentsByName.get('Daniel Miller').id,
        type: ResidentTimelineEntryType.OBSERVATION,
        title: 'Reassurance check recorded',
        details:
          'Settled after a short reassurance check and remains comfortable in the lounge.',
        createdById: demoUsers.mapleNurse.id,
        shiftId: mapleActiveShift.id,
        createdAt: new Date(now.getTime() - 16 * 60 * 1000),
      },
      {
        residentId: residentsByName.get('Agnes Cook').id,
        type: ResidentTimelineEntryType.MOBILITY_REPOSITIONING,
        title: 'Transfer comfort reviewed',
        details:
          'Transfer support completed and a comfort review has been documented for follow-up.',
        createdById: demoUsers.cedarNurse.id,
        shiftId: cedarActiveShift.id,
        createdAt: new Date(now.getTime() - 11 * 60 * 1000),
      },
    ],
  });

  await prisma.incident.createMany({
    data: [
      {
        residentId: residentsByName.get('Elliot Turner').id,
        shiftId: activeShift.id,
        createdById: user.id,
        severity: IncidentSeverity.AMBER,
        status: 'OPEN',
        category: IncidentCategory.INJURY,
        title: 'Small skin tear noted on lower arm',
        details:
          'Minor skin tear observed during repositioning. Area cleaned and dressed, with ongoing monitoring required.',
        occurredAt: new Date(now.getTime() - 22 * 60 * 1000),
      },
      {
        residentId: residentsByName.get('Thea Green').id,
        shiftId: activeShift.id,
        createdById: user.id,
        severity: IncidentSeverity.RED,
        status: 'OPEN',
        category: IncidentCategory.FALL,
        title: 'Unwitnessed fall in bedroom',
        details:
          'Resident found on the floor beside the bed. Emergency checks completed and manager review is required immediately.',
        occurredAt: new Date(now.getTime() - 8 * 60 * 1000),
      },
      {
        residentId: residentsByName.get('Daniel Miller').id,
        shiftId: mapleActiveShift.id,
        createdById: mapleCarer.id,
        severity: IncidentSeverity.AMBER,
        status: 'OPEN',
        category: IncidentCategory.OTHER,
        title: 'Unexpected confusion episode after breakfast',
        details:
          'Short period of confusion noted after breakfast. Reassurance is helping, but the manager should review the pattern.',
        occurredAt: new Date(now.getTime() - 14 * 60 * 1000),
      },
      {
        residentId: residentsByName.get('Agnes Cook').id,
        shiftId: cedarActiveShift.id,
        createdById: cedarCarer.id,
        severity: IncidentSeverity.RED,
        status: 'OPEN',
        category: IncidentCategory.INJURY,
        title: 'Pain concern raised after transfer support',
        details:
          'Pain increased after transfer support and urgent follow-up is needed to review comfort and next steps.',
        occurredAt: new Date(now.getTime() - 10 * 60 * 1000),
      },
    ],
  });

  console.log('Local baseline reset complete.');
  console.log(
    'This command removes resident, shift, handover, task, and audit activity and recreates the standard local baseline.',
  );
  console.log('Local login: carer@sercesync.local / Password123!');
  console.log('Local login: nurse@sercesync.local / Password123!');
  console.log('Local login: manager@sercesync.local / Password123!');
  console.log(
    `Seeded ${residents.length} fictional residents across 3 floors.`,
  );
  console.log(
    'Restored 6 live follow-up tasks, 10 completed tasks, and 4 open incidents across the three active floors.',
  );
  console.log(
    'Active staffing now includes 4 carers and 1 nurse on each floor, with Eryk Carer left unacknowledged on Willow for live demo actions.',
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
