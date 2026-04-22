const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');
const { residentProfilePresets } = require('./resident-profile-presets.cjs');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error(
    'DATABASE_URL must be defined before refreshing resident profiles.',
  );
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

async function main() {
  const residents = await prisma.resident.findMany({
    orderBy: [{ floorNumber: 'asc' }, { roomNumber: 'asc' }],
  });

  if (residents.length < residentProfilePresets.length) {
    throw new Error(
      `Expected at least ${residentProfilePresets.length} residents but found ${residents.length}.`,
    );
  }

  await prisma.$transaction(
    residentProfilePresets.map((preset, index) =>
      prisma.resident.update({
        where: {
          id: residents[index].id,
        },
        data: {
          recognitionImageKey: preset.recognitionImageKey,
          aboutMe: preset.aboutMe,
        },
      }),
    ),
  );

  console.log(
    `Refreshed ${residentProfilePresets.length} resident profiles with headshot keys and About me copy.`,
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
