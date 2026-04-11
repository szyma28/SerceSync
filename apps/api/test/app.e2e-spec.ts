import { INestApplication } from '@nestjs/common';
import type { Resident, Task } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { AppModule } from './../src/app.module';
import { PrismaService } from './../src/prisma/prisma.service';

describe('SerceSync workflow slices (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let seededTasks: Task[];
  let seededResidents: Resident[];

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
    await prisma.residentTimelineEntry.deleteMany();
    await prisma.handover.deleteMany();
    await prisma.task.deleteMany();
    await prisma.shift.deleteMany();
    await prisma.resident.deleteMany();
    await prisma.user.deleteMany();
    await prisma.role.deleteMany();

    const role = await prisma.role.create({
      data: {
        key: 'CARER',
        label: 'Carer',
      },
    });

    const managerRole = await prisma.role.create({
      data: {
        key: 'MANAGER',
        label: 'Manager',
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

    await prisma.user.create({
      data: {
        email: 'manager@sercesync.local',
        displayName: 'Morgan Manager',
        passwordHash,
        roleId: managerRole.id,
      },
    });

    seededResidents = await Promise.all(
      Array.from({ length: 10 }).map((_, index) =>
        prisma.resident.create({
          data: {
            fullName: [
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
            ][index],
            roomNumber: index + 1,
            roomLabel: `Room ${index + 1}`,
            floorNumber: 1,
            unitLabel: 'Willow Floor',
            recognitionImageKey: [
              'resident-a',
              'resident-b',
              'resident-c',
              'resident-d',
            ][index % 4],
            careSummary: [
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
            ][
              index
            ],
            isActive: true,
          },
        }),
      ),
    );

    await prisma.resident.create({
      data: {
        fullName: 'Doris Miller',
        roomNumber: 11,
        roomLabel: 'Room 11',
        floorNumber: 2,
        unitLabel: 'Maple Floor',
        recognitionImageKey: 'resident-d',
        careSummary: 'This resident should not appear to a floor one carer.',
        isActive: true,
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
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        assignedUsers: {
          connect: {
            id: user.id,
          },
        },
      },
    });

    const tomorrowShift = await prisma.shift.create({
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
        shiftId: shift.id,
        createdById: user.id,
        summary:
          'Margaret Evans needs an early hydration check and Raj Patel has an observation follow-up before lunch.',
      },
    });

    await prisma.residentTimelineEntry.createMany({
      data: [
        {
          residentId: seededResidents[0].id,
          type: 'NUTRITION_HYDRATION',
          title: 'Hydration encouragement logged',
          details:
            'Encouraged fluids and recorded intake with the breakfast check.',
          createdById: user.id,
          shiftId: shift.id,
          createdAt: new Date(now.getTime() - 30 * 60 * 1000),
        },
        {
          residentId: seededResidents[0].id,
          type: 'PERSONAL_CARE',
          title: 'Personal care recorded',
          details:
            'Supported with personal care and fresh clothing this morning.',
          createdById: user.id,
          shiftId: shift.id,
          createdAt: new Date(now.getTime() - 120 * 60 * 1000),
        },
      ],
    });

    seededTasks = await Promise.all([
      prisma.task.create({
        data: {
          shiftId: shift.id,
          residentId: seededResidents[0].id,
          title: 'Hydration round for Margaret Evans',
          description: 'Confirm hydration before breakfast.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 30 * 60 * 1000),
          assignedUserId: user.id,
        },
      }),
      prisma.task.create({
        data: {
          shiftId: shift.id,
          residentId: seededResidents[1].id,
          title: 'Observation follow-up for Raj Patel',
          description: 'Repeat observations before lunch.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 90 * 60 * 1000),
          assignedUserId: user.id,
        },
      }),
      prisma.task.create({
        data: {
          shiftId: shift.id,
          residentId: seededResidents[2].id,
          title: 'Repositioning check for Edith Turner',
          description: 'Review comfort positioning before the next round.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() - 10 * 60 * 1000),
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
    expect(handoverResponse.body.shift.floorNumber).toBe(1);
    expect(handoverResponse.body.shift.unitLabel).toBe('Willow Floor');

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
    const margaretTask = tasksResponse.body.tasks.find(
      (task: { residentId: string }) => task.residentId === seededResidents[0].id,
    );

    expect(margaretTask).toMatchObject({
      residentId: seededResidents[0].id,
      residentName: 'Margaret Evans',
      room: 'Room 1',
      status: 'PENDING',
    });

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
      refreshedTasksResponse.body.tasks.map(
        (task: { status: string }) => task.status,
      ),
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

  it('returns only residents from the active shift floor and exposes resident detail', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const residentsResponse = await request(app.getHttpServer())
      .get('/residents')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(residentsResponse.body.floorNumber).toBe(1);
    expect(residentsResponse.body.unitLabel).toBe('Willow Floor');
    expect(residentsResponse.body.residents).toHaveLength(10);
    expect(
      residentsResponse.body.residents.every(
        (resident: { floorNumber: number }) => resident.floorNumber === 1,
      ),
    ).toBe(true);

    const residentDetailResponse = await request(app.getHttpServer())
      .get(`/residents/${seededResidents[0].id}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(residentDetailResponse.body.fullName).toBe('Margaret Evans');
    expect(residentDetailResponse.body.currentTasks).toHaveLength(1);
    expect(residentDetailResponse.body.currentTasks[0].residentId).toBe(
      seededResidents[0].id,
    );
    expect(residentDetailResponse.body.timeline.length).toBeGreaterThanOrEqual(
      1,
    );
  });

  it('creates a resident timeline entry and writes the matching audit event', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const createResponse = await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'OBSERVATION',
        title: 'Observed as settled after breakfast',
        details:
          'Resident appeared comfortable and more settled after reassurance.',
      })
      .expect(201);

    expect(createResponse.body.entry.type).toBe('OBSERVATION');
    expect(createResponse.body.entry.authorName).toBe('Alex Carer');

    const createdEntry = await prisma.residentTimelineEntry.findFirstOrThrow({
      where: {
        residentId: seededResidents[1].id,
        title: 'Observed as settled after breakfast',
      },
    });

    expect(createdEntry.shiftId).toEqual(expect.any(String));

    const auditEvent = await prisma.auditEvent.findFirst({
      where: {
        kind: 'RESIDENT_TIMELINE_ENTRY_CREATED',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    expect(auditEvent).not.toBeNull();
    expect(auditEvent?.details).toMatchObject({
      residentId: seededResidents[1].id,
      residentName: 'Raj Patel',
      entryType: 'OBSERVATION',
    });
  });

  it('does not allow access to a resident outside the assigned floor scope', async () => {
    const externalResident = await prisma.resident.findFirstOrThrow({
      where: {
        floorNumber: 2,
      },
    });

    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    await request(app.getHttpServer())
      .get(`/residents/${externalResident.id}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);
  });

  it('returns a live shift overview with current and upcoming assignments', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const overviewResponse = await request(app.getHttpServer())
      .get('/shifts/my')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(overviewResponse.body.currentShift).toMatchObject({
      name: 'Morning Care Shift',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
    });
    expect(overviewResponse.body.assignments).toHaveLength(3);
    expect(overviewResponse.body.assignments[1]).toMatchObject({
      name: 'Tomorrow Care Shift',
      status: 'PLANNED',
    });
  });

  it('allows a manager to create and edit residents', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'manager@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const createResponse = await request(app.getHttpServer())
      .post('/manager/residents')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        fullName: 'Eleanor Marsh',
        roomNumber: 31,
        floorNumber: 3,
        unitLabel: 'Cedar Floor',
        recognitionImageKey: 'resident-b',
        careSummary: 'New resident with mobility prompts and hydration checks.',
        isActive: true,
      })
      .expect(201);

    expect(createResponse.body.resident).toMatchObject({
      fullName: 'Eleanor Marsh',
      roomLabel: 'Room 31',
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
    });

    const residentId = createResponse.body.resident.id as string;

    const editResponse = await request(app.getHttpServer())
      .patch(`/manager/residents/${residentId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        roomNumber: 32,
        careSummary: 'Updated resident summary with clearer care priorities.',
        isActive: false,
      })
      .expect(200);

    expect(editResponse.body.resident).toMatchObject({
      roomNumber: 32,
      roomLabel: 'Room 32',
      isActive: false,
    });
  });

  it('supports resident timeline media evidence upload and retrieval', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    const accessToken = loginResponse.body.accessToken as string;

    const createResponse = await request(app.getHttpServer())
      .post(`/residents/${seededResidents[0].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .field('type', 'OBSERVATION')
      .field('details', 'Photo evidence captured for skin integrity review.')
      .attach('evidence', Buffer.from('fake-image-data'), {
        filename: 'skin-check.jpg',
        contentType: 'image/jpeg',
      })
      .expect(201);

    expect(createResponse.body.entry.media).toHaveLength(1);
    const mediaId = createResponse.body.entry.media[0].id as string;

    const residentDetailResponse = await request(app.getHttpServer())
      .get(`/residents/${seededResidents[0].id}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200);

    expect(residentDetailResponse.body.timeline[0].media).toHaveLength(1);

    await request(app.getHttpServer())
      .get(`/resident-media/${mediaId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect('Content-Type', /image\/jpeg/);
  });

  it('rejects task access without a bearer token', () => {
    return request(app.getHttpServer()).get('/tasks/current').expect(401);
  });
});
