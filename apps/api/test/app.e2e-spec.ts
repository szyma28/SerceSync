import { INestApplication } from '@nestjs/common';
import type { Task } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

describe('SerceSync workflow slices (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let seededTasks: Task[];

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

    const now = new Date();
    const shiftStartsAt = new Date(now.getTime() - 60 * 60 * 1000);
    const shiftEndsAt = new Date(now.getTime() + 7 * 60 * 60 * 1000);

    const shift = await prisma.shift.create({
      data: {
        name: 'Morning Care Shift',
        startsAt: shiftStartsAt,
        endsAt: shiftEndsAt,
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

    seededTasks = await Promise.all([
      prisma.task.create({
        data: {
          shiftId: shift.id,
          title: 'Hydration round for Mrs Evans',
          description: 'Confirm hydration before breakfast.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 30 * 60 * 1000),
          assignedUserId: user.id,
        },
      }),
      prisma.task.create({
        data: {
          shiftId: shift.id,
          title: 'Observation follow-up for Mr Patel',
          description: 'Repeat observations before lunch.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 90 * 60 * 1000),
          assignedUserId: user.id,
        },
      }),
      prisma.task.create({
        data: {
          shiftId: shift.id,
          title: 'Escalate mobility concern review',
          description: 'Escalate if the equipment request is still pending.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 2 * 60 * 60 * 1000),
          assignedUserId: user.id,
        },
      }),
    ]);
  });

  afterAll(async () => {
    await app.close();
  });

  it('returns the API status payload', () => {
    return request(app.getHttpServer()).get('/').expect(200).expect({
      name: 'SerceSync API',
      status: 'ok',
      phase: 'task-accountability',
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

  it('completes the task accountability flow for the active shift', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const tasksResponse = await request(app.getHttpServer())
      .get('/tasks/current')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(tasksResponse.body.tasks).toHaveLength(3);
    expect(tasksResponse.body.tasks[0].status).toBe('PENDING');

    const completeResponse = await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[0].id}/complete`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        note: 'Completed during first room round.',
      })
      .expect(201);

    expect(completeResponse.body.task.status).toBe('COMPLETED');
    expect(completeResponse.body.task.statusNote).toBe(
      'Completed during first room round.',
    );

    const deferResponse = await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[1].id}/defer`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        reason: 'Resident was asleep and observations will be repeated later.',
      })
      .expect(201);

    expect(deferResponse.body.task.status).toBe('DEFERRED');

    const escalateResponse = await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[2].id}/escalate`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        reason: 'Equipment request still missing and senior review is needed.',
      })
      .expect(201);

    expect(escalateResponse.body.task.status).toBe('ESCALATED');

    const refreshedTasksResponse = await request(app.getHttpServer())
      .get('/tasks/current')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(
      refreshedTasksResponse.body.tasks.map((task: { status: string }) => task.status),
    ).toEqual(['DEFERRED', 'ESCALATED', 'COMPLETED']);

    const auditEvents = await prisma.auditEvent.findMany({
      where: {
        kind: {
          in: ['TASK_COMPLETED', 'TASK_DEFERRED', 'TASK_ESCALATED'],
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    expect(auditEvents).toHaveLength(3);
  });

  it('rejects task access without a bearer token', () => {
    return request(app.getHttpServer()).get('/tasks/current').expect(401);
  });
});
