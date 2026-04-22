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

async function main() {
  const activeWindow = buildShiftWindow(new Date());
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
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
