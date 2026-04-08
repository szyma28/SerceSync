const bcrypt = require('bcryptjs');
const { PrismaPg } = require('@prisma/adapter-pg');
const { PrismaClient } = require('@prisma/client');

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error('DATABASE_URL must be defined before running the seed script.');
}

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString }),
});

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

  await prisma.shift.updateMany({
    where: {
      status: 'ACTIVE',
      assignedUsers: {
        some: {
          id: user.id,
        },
      },
    },
    data: {
      status: 'COMPLETED',
    },
  });

  const now = new Date();
  const startsAt = new Date(now.getTime() - 60 * 60 * 1000);
  const endsAt = new Date(now.getTime() + 7 * 60 * 60 * 1000);

  const shift = await prisma.shift.create({
    data: {
      name: 'Morning Care Shift',
      startsAt,
      endsAt,
      status: 'ACTIVE',
      assignedUsers: {
        connect: {
          id: user.id,
        },
      },
    },
  });

  await prisma.handover.create({
    data: {
      shiftId: shift.id,
      createdById: user.id,
      summary:
        'Mrs Evans had a restless night and needs an early hydration check. Mr Patel has a pending observation follow-up before lunch. Please confirm the handover before starting task work.',
    },
  });

  console.log('Seed complete.');
  console.log('Demo login: carer@sercesync.local / Password123!');
}

main()
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
