import { INestApplication } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

describe('SerceSync handover flow (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    prisma = moduleFixture.get(PrismaService);
    await app.init();
  });

  beforeEach(async () => {
    await prisma.auditEvent.deleteMany();
    await prisma.handoverAcknowledgement.deleteMany();
    await prisma.handover.deleteMany();
    await prisma.task.deleteMany();
    await prisma.shift.deleteMany();
    await prisma.user.deleteMany();
    await prisma.role.deleteMany();

    const role = await prisma.role.create({
      data: {
        key: 'CARER',
        label: 'Carer',
      },
    });

    const passwordHash = await bcrypt.hash('Password123!', 10);

    const user = await prisma.user.create({
      data: {
        email: 'carer@sercesync.local',
        displayName: 'Alex Carer',
        passwordHash,
        roleId: role.id,
      },
    });

    const shift = await prisma.shift.create({
      data: {
        name: 'Morning Care Shift',
        startsAt: new Date('2026-04-08T07:00:00.000Z'),
        endsAt: new Date('2026-04-08T15:00:00.000Z'),
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
          'Mrs Evans needs an early hydration check and Mr Patel has an observation follow-up before lunch.',
      },
    });
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns the API status payload', () => {
    return request(app.getHttpServer()).get('/').expect(200).expect({
      name: 'SerceSync API',
      status: 'ok',
      phase: 'handover-acknowledgement',
    });
  });

  it('completes the login to handover acknowledgement flow', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    expect(loginResponse.body.user.email).toBe('carer@sercesync.local');
    expect(loginResponse.body.accessToken).toEqual(expect.any(String));

    const accessToken = loginResponse.body.accessToken as string;

    const handoverResponse = await request(app.getHttpServer())
      .get('/handovers/current')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(handoverResponse.body.acknowledged).toBe(false);
    expect(handoverResponse.body.currentUser.email).toBe(
      'carer@sercesync.local',
    );

    const acknowledgeResponse = await request(app.getHttpServer())
      .post('/handovers/current/acknowledge')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(201);

    expect(acknowledgeResponse.body.acknowledged).toBe(true);
    expect(acknowledgeResponse.body.acknowledgedAt).toEqual(expect.any(String));

    const refreshedResponse = await request(app.getHttpServer())
      .get('/handovers/current')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(refreshedResponse.body.acknowledged).toBe(true);
  });

  it('rejects protected handover access without a bearer token', () => {
    return request(app.getHttpServer()).get('/handovers/current').expect(401);
  });
});
