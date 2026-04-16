import { INestApplication } from '@nestjs/common';
import type { Incident, Resident, Shift, Task } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { getAuditDetailString } from './../src/audit-event-details';
import { AppModule } from './../src/app.module';
import { MANAGER_SESSION_COOKIE_NAME } from './../src/auth/auth.constants';
import { PrismaService } from './../src/prisma/prisma.service';

describe('SerceSync workflow slices (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let seededTasks: Task[];
  let seededResidents: Resident[];
  let activeShift: Shift;
  let secondaryActiveShift: Shift;
  let seededIncidents: {
    amber: Incident;
    red: Incident;
  };
  let secondaryUnitIncident: Incident;
  let outOfScopeResident: Resident;
  let sameFloorDifferentUnitResident: Resident;

  const residentNames = [
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

  type TypedResponse<T> = Omit<request.Response, 'body'> & { body: T };

  function typedResponse<T>(response: request.Response) {
    return response as TypedResponse<T>;
  }

  type AuthLoginResponse = {
    accessToken: string;
  };

  type ManagerBrowserLoginResponse = {
    accessToken?: undefined;
    user: {
      email: string;
      role: 'MANAGER';
    };
  };

  type ManagerSessionResponse = {
    user: {
      email: string;
      role: 'MANAGER';
    };
  };

  type HandoverCurrentResponse = {
    acknowledged: boolean;
    acknowledgedAt: string | null;
    currentUser: {
      email: string;
    };
    shift: {
      floorNumber: number;
      unitLabel: string;
    };
  };

  type TasksCurrentResponse = {
    tasks: Array<{
      id: string;
      status: string;
    }>;
  };

  type ResidentsListResponse = {
    residents: Array<{
      fullName: string;
      baselinePriority: string;
      effectivePriority: string;
      prioritySource: string;
      activeIncidentCount: number;
    }>;
  };

  type ResidentDetailResponse = {
    effectivePriority: string;
    prioritySource: string;
    activeIncidents: Array<{
      id: string;
      severity: string;
      status: string;
      category: string;
    }>;
    timeline: Array<{
      type: string;
      personalCareSubtype?: string;
    }>;
  };

  type ResidentTimelineWriteResponse = {
    entry: {
      id: string;
      type: string;
      personalCareSubtype?: string;
      media?: Array<{
        id: string;
        mediaType: string;
      }>;
    };
  };

  type ResidentTimelineMediaUploadResponse = {
    entry: {
      id: string;
      type: string;
      media: Array<{
        id: string;
        mediaType: string;
      }>;
    };
  };

  type IncidentCreateResponse = {
    incident: {
      id: string;
      evidence: Array<{
        mediaType: string;
      }>;
    };
    resident: {
      baselinePriority: string;
      effectivePriority: string;
      prioritySource: string;
      activeIncidentCount: number;
    };
  };

  type LogoutResponse = {
    success: true;
  };

  type ManagerShiftsResponse = {
    activeShifts: Array<{
      id: string;
    }>;
  };

  type ManagerDashboardResponse = {
    activeShift: {
      id: string;
    };
    metrics: {
      activeIncidents: number;
    };
    exceptionFeed: Array<{
      kind: string;
      id: string;
      status?: string;
      severity?: string;
      canAcknowledge?: boolean;
      canResolve?: boolean;
    }>;
    activityFeed: Array<{
      kind: string;
      title: string;
      residentName: string;
      roomLabel: string;
      description: string;
      actorName: string | null;
      badge: string;
      badgeTone?: string;
    }>;
  };

  type ManagerIncidentTransitionResponse = {
    incident: {
      status: string;
    };
    resident: {
      effectivePriority: string;
    };
  };

  type ManagerResidentWriteResponse = {
    resident: {
      id: string;
      fullName?: string;
      roomNumber?: number;
      roomLabel?: string;
      floorNumber?: number;
      unitLabel?: string;
      baselinePriority?: string;
      effectivePriority?: string;
      prioritySource?: string;
      activeIncidentCount?: number;
      isActive?: boolean;
    };
  };

  type ShiftOverviewResponse = {
    currentShift: {
      name: string;
      floorNumber: number;
      unitLabel: string;
    };
    assignments: Array<{
      name: string;
      status: string;
    }>;
  };

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    prisma = moduleFixture.get(PrismaService);
    await app.init();
  });

  async function login(email: string, password = 'Password123!') {
    const response = typedResponse<AuthLoginResponse>(
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({ email, password })
        .expect(201),
    );

    return response.body.accessToken;
  }

  async function loginManagerBrowser(email: string, password = 'Password123!') {
    return typedResponse<ManagerBrowserLoginResponse>(
      await request(app.getHttpServer())
        .post('/auth/manager/login')
        .send({ email, password })
        .expect(201),
    );
  }

  beforeEach(async () => {
    await prisma.auditEvent.deleteMany();
    await prisma.handoverAcknowledgement.deleteMany();
    await prisma.incidentMedia.deleteMany();
    await prisma.residentTimelineMedia.deleteMany();
    await prisma.incident.deleteMany();
    await prisma.residentTimelineEntry.deleteMany();
    await prisma.handover.deleteMany();
    await prisma.task.deleteMany();
    await prisma.shift.deleteMany();
    await prisma.resident.deleteMany();
    await prisma.user.deleteMany();
    await prisma.role.deleteMany();

    const carerRole = await prisma.role.create({
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

    const carer = await prisma.user.create({
      data: {
        email: 'carer@sercesync.local',
        displayName: 'Alex Carer',
        passwordHash,
        roleId: carerRole.id,
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

    seededResidents = [];

    for (const [index, fullName] of residentNames.entries()) {
      const resident = await prisma.resident.create({
        data: {
          fullName,
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
          careSummary: careSummaries[index],
          isActive: true,
          baselinePriority: fullName === 'Raj Patel' ? 'AMBER' : 'GREEN',
        },
      });

      seededResidents.push(resident);
    }

    outOfScopeResident = await prisma.resident.create({
      data: {
        fullName: 'Doris Miller',
        roomNumber: 11,
        roomLabel: 'Room 11',
        floorNumber: 2,
        unitLabel: 'Maple Floor',
        recognitionImageKey: 'resident-d',
        careSummary: 'This resident should not appear to a floor one carer.',
        isActive: true,
        baselinePriority: 'GREEN',
      },
    });

    sameFloorDifferentUnitResident = await prisma.resident.create({
      data: {
        fullName: 'Caroline Reed',
        roomNumber: 12,
        roomLabel: 'Room 12',
        floorNumber: 1,
        unitLabel: 'Cedar Floor',
        recognitionImageKey: 'resident-c',
        careSummary:
          'Should only appear in the Cedar Floor manager dashboard scope.',
        isActive: true,
        baselinePriority: 'GREEN',
      },
    });

    const now = new Date();
    const shiftStartsAt = new Date(now.getTime() - 60 * 60 * 1000);
    const shiftEndsAt = new Date(now.getTime() + 7 * 60 * 60 * 1000);

    activeShift = await prisma.shift.create({
      data: {
        name: 'Morning Care Shift',
        startsAt: shiftStartsAt,
        endsAt: shiftEndsAt,
        status: 'ACTIVE',
        floorNumber: 1,
        unitLabel: 'Willow Floor',
        assignedUsers: {
          connect: {
            id: carer.id,
          },
        },
      },
    });

    secondaryActiveShift = await prisma.shift.create({
      data: {
        name: 'Cedar Support Shift',
        startsAt: new Date(now.getTime() - 30 * 60 * 1000),
        endsAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
        status: 'ACTIVE',
        floorNumber: 1,
        unitLabel: 'Cedar Floor',
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
            id: carer.id,
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
            id: carer.id,
          },
        },
      },
    });

    await prisma.handover.create({
      data: {
        shiftId: activeShift.id,
        createdById: carer.id,
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
          createdById: carer.id,
          shiftId: activeShift.id,
          createdAt: new Date(now.getTime() - 30 * 60 * 1000),
        },
        {
          residentId: seededResidents[0].id,
          type: 'PERSONAL_CARE',
          personalCareSubtype: 'SHOWER',
          title: 'Personal care recorded',
          details:
            'Supported with personal care and fresh clothing this morning.',
          createdById: carer.id,
          shiftId: activeShift.id,
          createdAt: new Date(now.getTime() - 120 * 60 * 1000),
        },
        {
          residentId: seededResidents[3].id,
          type: 'PERSONAL_CARE',
          personalCareSubtype: 'SHOWER',
          title: 'Shower and comfort support recorded',
          details:
            'Supported with a supervised shower and fresh clothing after the morning rounds.',
          createdById: carer.id,
          shiftId: activeShift.id,
          createdAt: new Date(now.getTime() - 75 * 60 * 1000),
        },
      ],
    });

    seededTasks = [];
    seededTasks.push(
      await prisma.task.create({
        data: {
          shiftId: activeShift.id,
          residentId: seededResidents[0].id,
          title: 'Hydration round for Margaret Evans',
          description: 'Confirm hydration before breakfast.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 30 * 60 * 1000),
          assignedUserId: carer.id,
        },
      }),
    );
    seededTasks.push(
      await prisma.task.create({
        data: {
          shiftId: activeShift.id,
          residentId: seededResidents[1].id,
          title: 'Observation follow-up for Raj Patel',
          description: 'Repeat observations before lunch.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 90 * 60 * 1000),
          assignedUserId: carer.id,
        },
      }),
    );
    seededTasks.push(
      await prisma.task.create({
        data: {
          shiftId: activeShift.id,
          residentId: seededResidents[2].id,
          title: 'Repositioning check for Edith Turner',
          description: 'Review comfort positioning before the next round.',
          status: 'PENDING',
          dueAt: new Date(now.getTime() - 10 * 60 * 1000),
          assignedUserId: carer.id,
        },
      }),
    );

    seededIncidents = {
      amber: await prisma.incident.create({
        data: {
          residentId: seededResidents[2].id,
          shiftId: activeShift.id,
          createdById: carer.id,
          severity: 'AMBER',
          status: 'OPEN',
          category: 'INJURY',
          title: 'Small skin tear on left forearm',
          details:
            'Minor skin tear observed during repositioning. Area cleaned and dressed, with monitoring required.',
          occurredAt: new Date(now.getTime() - 20 * 60 * 1000),
        },
      }),
      red: await prisma.incident.create({
        data: {
          residentId: seededResidents[3].id,
          shiftId: activeShift.id,
          createdById: carer.id,
          severity: 'RED',
          status: 'OPEN',
          category: 'FALL',
          title: 'Unwitnessed fall in bedroom',
          details:
            'Resident found on the floor beside the bed. Immediate review required.',
          occurredAt: new Date(now.getTime() - 5 * 60 * 1000),
        },
      }),
    };

    secondaryUnitIncident = await prisma.incident.create({
      data: {
        residentId: sameFloorDifferentUnitResident.id,
        shiftId: secondaryActiveShift.id,
        createdById: carer.id,
        severity: 'RED',
        status: 'OPEN',
        category: 'BEHAVIOUR',
        title: 'Distress episode in Cedar corridor',
        details:
          'Should only appear when the Cedar Floor dashboard scope is selected.',
        occurredAt: new Date(now.getTime() - 12 * 60 * 1000),
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
      phase: 'task-accountability',
    });
  });

  it('completes the login to handover acknowledgement flow', async () => {
    const accessToken = await login('carer@sercesync.local');

    const handoverResponse = typedResponse<HandoverCurrentResponse>(
      await request(app.getHttpServer())
        .get('/handovers/current')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(handoverResponse.body.acknowledged).toBe(false);
    expect(handoverResponse.body.currentUser.email).toBe(
      'carer@sercesync.local',
    );
    expect(handoverResponse.body.shift.floorNumber).toBe(1);
    expect(handoverResponse.body.shift.unitLabel).toBe('Willow Floor');

    const acknowledgeResponse = typedResponse<HandoverCurrentResponse>(
      await request(app.getHttpServer())
        .post('/handovers/current/acknowledge')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(201),
    );

    expect(acknowledgeResponse.body.acknowledged).toBe(true);
    expect(acknowledgeResponse.body.acknowledgedAt).toEqual(expect.any(String));
  });

  it('creates and restores a manager browser session with an HttpOnly cookie', async () => {
    const loginResponse = await loginManagerBrowser('manager@sercesync.local');
    const sessionCookie = loginResponse.headers['set-cookie'];

    expect(loginResponse.body.accessToken).toBeUndefined();
    expect(loginResponse.body.user.email).toBe('manager@sercesync.local');
    expect(sessionCookie).toEqual(
      expect.arrayContaining([
        expect.stringContaining(`${MANAGER_SESSION_COOKIE_NAME}=`),
      ]),
    );
    expect(sessionCookie).toEqual(
      expect.arrayContaining([expect.stringContaining('HttpOnly')]),
    );
    expect(sessionCookie).toEqual(
      expect.arrayContaining([expect.stringContaining('SameSite=Lax')]),
    );

    const sessionResponse = typedResponse<ManagerSessionResponse>(
      await request(app.getHttpServer())
        .get('/auth/manager/session')
        .set('Cookie', sessionCookie)
        .expect(200),
    );

    expect(sessionResponse.body.user).toMatchObject({
      email: 'manager@sercesync.local',
      role: 'MANAGER',
    });

    const shiftsResponse = typedResponse<ManagerShiftsResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard/shifts')
        .set('Cookie', sessionCookie)
        .expect(200),
    );

    expect(shiftsResponse.body.activeShifts).toHaveLength(2);

    const logoutResponse = typedResponse<LogoutResponse>(
      await request(app.getHttpServer())
        .post('/auth/manager/logout')
        .set('Cookie', sessionCookie)
        .expect(200),
    );

    expect(logoutResponse.body).toEqual({ success: true });
    expect(logoutResponse.headers['set-cookie']).toEqual(
      expect.arrayContaining([
        expect.stringContaining(`${MANAGER_SESSION_COOKIE_NAME}=;`),
      ]),
    );
  });

  it('completes the task accountability flow for the active shift', async () => {
    const accessToken = await login('carer@sercesync.local');

    const tasksResponse = typedResponse<TasksCurrentResponse>(
      await request(app.getHttpServer())
        .get('/tasks/current')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(tasksResponse.body.tasks).toHaveLength(3);

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[0].id}/complete`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        note: 'Completed during first room round.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[1].id}/defer`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        reason: 'Resident was asleep and observations will be repeated later.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[2].id}/escalate`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        reason: 'Equipment request still missing and senior review is needed.',
      })
      .expect(201);

    const refreshedTasksResponse = typedResponse<TasksCurrentResponse>(
      await request(app.getHttpServer())
        .get('/tasks/current')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(refreshedTasksResponse.body.tasks).toHaveLength(1);
    expect(refreshedTasksResponse.body.tasks[0].status).toBe('ESCALATED');

    const auditEvents = await prisma.auditEvent.findMany({
      where: {
        kind: {
          in: ['TASK_COMPLETED', 'TASK_DEFERRED', 'TASK_ESCALATED'],
        },
      },
    });

    expect(auditEvents).toHaveLength(3);
  });

  it('returns residents with derived priority state and active incidents on detail', async () => {
    const accessToken = await login('carer@sercesync.local');

    const residentsResponse = typedResponse<ResidentsListResponse>(
      await request(app.getHttpServer())
        .get('/residents')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    const raj = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Raj Patel',
    );
    const edith = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Edith Turner',
    );
    const thomas = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Thomas Green',
    );
    const margaret = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Margaret Evans',
    );

    expect(margaret).toMatchObject({
      baselinePriority: 'GREEN',
      effectivePriority: 'GREEN',
      prioritySource: 'BASELINE',
      activeIncidentCount: 0,
    });
    expect(raj).toMatchObject({
      baselinePriority: 'AMBER',
      effectivePriority: 'AMBER',
      prioritySource: 'BASELINE',
      activeIncidentCount: 0,
    });
    expect(edith).toMatchObject({
      baselinePriority: 'GREEN',
      effectivePriority: 'AMBER',
      prioritySource: 'INCIDENT_OVERRIDE',
      activeIncidentCount: 1,
    });
    expect(thomas).toMatchObject({
      baselinePriority: 'GREEN',
      effectivePriority: 'RED',
      prioritySource: 'INCIDENT_OVERRIDE',
      activeIncidentCount: 1,
    });

    const residentDetailResponse = typedResponse<ResidentDetailResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[3].id}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(residentDetailResponse.body.effectivePriority).toBe('RED');
    expect(residentDetailResponse.body.activeIncidents).toHaveLength(1);
    expect(residentDetailResponse.body.activeIncidents[0]).toMatchObject({
      id: seededIncidents.red.id,
      severity: 'RED',
      status: 'OPEN',
      category: 'FALL',
    });
    expect(
      residentDetailResponse.body.timeline.some(
        (entry: { personalCareSubtype?: string; type: string }) =>
          entry.type === 'PERSONAL_CARE' &&
          entry.personalCareSubtype === 'SHOWER',
      ),
    ).toBe(true);
  });

  it('creates a personal-care note with subtype and rejects invalid subtype combinations', async () => {
    const accessToken = await login('carer@sercesync.local');

    const successResponse = typedResponse<ResidentTimelineWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[1].id}/timeline`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          type: 'PERSONAL_CARE',
          personalCareSubtype: 'CONTINENCE',
          details: 'Continence support provided and fresh pads applied.',
        })
        .expect(201),
    );

    expect(successResponse.body.entry.type).toBe('PERSONAL_CARE');
    expect(successResponse.body.entry.personalCareSubtype).toBe('CONTINENCE');

    const createdEntry = await prisma.residentTimelineEntry.findFirstOrThrow({
      where: {
        residentId: seededResidents[1].id,
        personalCareSubtype: 'CONTINENCE',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    expect(createdEntry.personalCareSubtype).toBe('CONTINENCE');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'PERSONAL_CARE',
        details: 'Personal care logged without structured subtype.',
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'OBSERVATION',
        personalCareSubtype: 'SKIN_CARE',
        details: 'Observation note should not accept a personal-care subtype.',
      })
      .expect(400);
  });

  it('creates incidents with and without evidence and blocks out-of-scope incident creation', async () => {
    const accessToken = await login('carer@sercesync.local');

    const withoutEvidence = typedResponse<IncidentCreateResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[4].id}/incidents`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          severity: 'AMBER',
          category: 'BEHAVIOUR',
          title: 'Resident became distressed before lunch',
          details: 'De-escalation used and monitoring remains in place.',
        })
        .expect(201),
    );

    expect(withoutEvidence.body.incident.evidence).toHaveLength(0);
    expect(withoutEvidence.body.resident).toMatchObject({
      baselinePriority: 'GREEN',
      effectivePriority: 'AMBER',
      prioritySource: 'INCIDENT_OVERRIDE',
      activeIncidentCount: 1,
    });

    const withEvidence = typedResponse<IncidentCreateResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[5].id}/incidents`)
        .set('Authorization', `Bearer ${accessToken}`)
        .field('severity', 'RED')
        .field('category', 'INJURY')
        .field('title', 'Deep bruise noted during transfer')
        .field(
          'details',
          'Photo evidence captured and urgent manager review requested.',
        )
        .attach('evidence', Buffer.from('fake-image-data'), {
          filename: 'bruise-check.jpg',
          contentType: 'image/jpeg',
        })
        .expect(201),
    );

    expect(withEvidence.body.incident.evidence).toHaveLength(1);
    expect(withEvidence.body.incident.evidence[0].mediaType).toBe('image/jpeg');
    expect(withEvidence.body.resident.effectivePriority).toBe('RED');

    await request(app.getHttpServer())
      .post(`/residents/${outOfScopeResident.id}/incidents`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        severity: 'AMBER',
        category: 'OTHER',
        title: 'Out-of-scope incident attempt',
        details: 'This resident is not on the assigned floor.',
      })
      .expect(404);
  });

  it('requires an explicit active shift when loading the manager dashboard', async () => {
    const accessToken = await login('manager@sercesync.local');

    await request(app.getHttpServer())
      .get('/manager/dashboard')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(400);
  });

  it('lists active shifts and scopes dashboard incidents to the selected unit', async () => {
    const accessToken = await login('manager@sercesync.local');

    const activeShiftsResponse = typedResponse<ManagerShiftsResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard/shifts')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(activeShiftsResponse.body.activeShifts).toHaveLength(2);
    expect(
      activeShiftsResponse.body.activeShifts.map(
        (shift: { id: string }) => shift.id,
      ),
    ).toEqual([secondaryActiveShift.id, activeShift.id]);

    const dashboardResponse = typedResponse<ManagerDashboardResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .query({ shiftId: activeShift.id })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(dashboardResponse.body.activeShift.id).toBe(activeShift.id);
    expect(dashboardResponse.body.metrics.activeIncidents).toBe(2);
    expect(dashboardResponse.body.exceptionFeed).toHaveLength(5);
    expect(dashboardResponse.body.exceptionFeed[0]).toMatchObject({
      kind: 'INCIDENT',
      id: seededIncidents.red.id,
      status: 'OPEN',
      severity: 'RED',
      canAcknowledge: true,
      canResolve: false,
    });
    expect(dashboardResponse.body.exceptionFeed[1]).toMatchObject({
      kind: 'INCIDENT',
      id: seededIncidents.amber.id,
      status: 'OPEN',
      severity: 'AMBER',
      canAcknowledge: true,
      canResolve: false,
    });
    expect(
      dashboardResponse.body.exceptionFeed.findIndex(
        (item: { kind: string; id: string }) => item.kind === 'TASK',
      ),
    ).toBeGreaterThan(1);
    expect(
      dashboardResponse.body.exceptionFeed.some(
        (item: { id: string }) => item.id === secondaryUnitIncident.id,
      ),
    ).toBe(false);

    const secondaryDashboardResponse = typedResponse<ManagerDashboardResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .query({ shiftId: secondaryActiveShift.id })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(secondaryDashboardResponse.body.activeShift.id).toBe(
      secondaryActiveShift.id,
    );
    expect(secondaryDashboardResponse.body.metrics.activeIncidents).toBe(1);
    expect(secondaryDashboardResponse.body.exceptionFeed[0]).toMatchObject({
      kind: 'INCIDENT',
      id: secondaryUnitIncident.id,
      severity: 'RED',
    });
  });

  it('shows recent notes and task completions in the manager activity feed', async () => {
    const carerToken = await login('carer@sercesync.local');
    const managerToken = await login('manager@sercesync.local');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/timeline`)
      .set('Authorization', `Bearer ${carerToken}`)
      .send({
        type: 'PERSONAL_CARE',
        personalCareSubtype: 'CONTINENCE',
        details: 'Continence support provided and fresh pads applied.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[0].id}/complete`)
      .set('Authorization', `Bearer ${carerToken}`)
      .send({
        note: 'Hydration round completed and fluids encouraged.',
      })
      .expect(201);

    const dashboardResponse = typedResponse<ManagerDashboardResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .query({ shiftId: activeShift.id })
        .set('Authorization', `Bearer ${managerToken}`)
        .expect(200),
    );

    expect(dashboardResponse.body.activityFeed).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          kind: 'NOTE',
          title: 'Personal Care · Continence',
          residentName: seededResidents[1].fullName,
          roomLabel: seededResidents[1].roomLabel,
          description: 'Continence support provided and fresh pads applied.',
          actorName: 'Alex Carer',
          badge: 'PERSONAL CARE',
        }),
        expect.objectContaining({
          kind: 'TASK',
          title: seededTasks[0].title,
          residentName: seededResidents[0].fullName,
          roomLabel: seededResidents[0].roomLabel,
          description: 'Hydration round completed and fluids encouraged.',
          actorName: 'Alex Carer',
          badge: 'COMPLETED',
          badgeTone: 'success',
        }),
      ]),
    );
  });

  it('acknowledges and resolves incidents while recalculating resident priority and audit trail', async () => {
    const carerToken = await login('carer@sercesync.local');
    const managerToken = await login('manager@sercesync.local');

    const createdIncidentResponse = typedResponse<IncidentCreateResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[0].id}/incidents`)
        .set('Authorization', `Bearer ${carerToken}`)
        .field('severity', 'RED')
        .field('category', 'FALL')
        .field('title', 'Slip beside bedside table')
        .field(
          'details',
          'Resident found beside the bedside table and urgent follow-up started.',
        )
        .attach('evidence', Buffer.from('fake-image-data'), {
          filename: 'fall-scene.jpg',
          contentType: 'image/jpeg',
        })
        .expect(201),
    );

    const createdIncidentId = createdIncidentResponse.body.incident.id;

    let residentDetailResponse = typedResponse<ResidentDetailResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[0].id}`)
        .set('Authorization', `Bearer ${carerToken}`)
        .expect(200),
    );

    expect(residentDetailResponse.body.effectivePriority).toBe('RED');
    expect(residentDetailResponse.body.prioritySource).toBe(
      'INCIDENT_OVERRIDE',
    );

    const acknowledgeResponse =
      typedResponse<ManagerIncidentTransitionResponse>(
        await request(app.getHttpServer())
          .post(`/manager/incidents/${createdIncidentId}/acknowledge`)
          .set('Authorization', `Bearer ${managerToken}`)
          .send({ shiftId: activeShift.id })
          .expect(201),
      );

    expect(acknowledgeResponse.body.incident.status).toBe('ACKNOWLEDGED');
    expect(acknowledgeResponse.body.resident.effectivePriority).toBe('RED');

    residentDetailResponse = typedResponse<ResidentDetailResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[0].id}`)
        .set('Authorization', `Bearer ${carerToken}`)
        .expect(200),
    );

    expect(residentDetailResponse.body.effectivePriority).toBe('RED');
    expect(residentDetailResponse.body.activeIncidents[0].status).toBe(
      'ACKNOWLEDGED',
    );

    const resolveResponse = typedResponse<ManagerIncidentTransitionResponse>(
      await request(app.getHttpServer())
        .post(`/manager/incidents/${createdIncidentId}/resolve`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ shiftId: activeShift.id })
        .expect(201),
    );

    expect(resolveResponse.body.incident.status).toBe('RESOLVED');
    expect(resolveResponse.body.resident).toMatchObject({
      baselinePriority: 'GREEN',
      effectivePriority: 'GREEN',
      prioritySource: 'BASELINE',
      activeIncidentCount: 0,
    });

    residentDetailResponse = typedResponse<ResidentDetailResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[0].id}`)
        .set('Authorization', `Bearer ${carerToken}`)
        .expect(200),
    );

    expect(residentDetailResponse.body.effectivePriority).toBe('GREEN');
    expect(residentDetailResponse.body.activeIncidents).toHaveLength(0);

    const auditTrail = await prisma.auditEvent.findMany({
      where: {
        kind: {
          in: [
            'INCIDENT_CREATED',
            'INCIDENT_MEDIA_ATTACHED',
            'INCIDENT_ACKNOWLEDGED',
            'INCIDENT_RESOLVED',
          ],
        },
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    expect(auditTrail.map((event) => event.kind)).toEqual(
      expect.arrayContaining([
        'INCIDENT_CREATED',
        'INCIDENT_MEDIA_ATTACHED',
        'INCIDENT_ACKNOWLEDGED',
        'INCIDENT_RESOLVED',
      ]),
    );
  });

  it('allows only one concurrent manager transition per incident status change', async () => {
    const carerToken = await login('carer@sercesync.local');
    const managerToken = await login('manager@sercesync.local');

    const createdIncidentResponse = typedResponse<IncidentCreateResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[0].id}/incidents`)
        .set('Authorization', `Bearer ${carerToken}`)
        .field('severity', 'RED')
        .field('category', 'FALL')
        .field('title', 'Concurrent transition test')
        .field(
          'details',
          'Used to verify that manager incident transitions remain atomic.',
        )
        .expect(201),
    );

    const createdIncidentId = createdIncidentResponse.body.incident.id;

    const [acknowledgeResponse1, acknowledgeResponse2] = await Promise.all([
      request(app.getHttpServer())
        .post(`/manager/incidents/${createdIncidentId}/acknowledge`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ shiftId: activeShift.id }),
      request(app.getHttpServer())
        .post(`/manager/incidents/${createdIncidentId}/acknowledge`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ shiftId: activeShift.id }),
    ]);
    const acknowledgeResponses = [
      typedResponse<ManagerIncidentTransitionResponse>(acknowledgeResponse1),
      typedResponse<ManagerIncidentTransitionResponse>(acknowledgeResponse2),
    ];

    const acknowledgeStatuses = acknowledgeResponses.map(
      (response) => response.status,
    );
    expect(acknowledgeStatuses.filter((status) => status === 201)).toHaveLength(
      1,
    );
    expect(acknowledgeStatuses.filter((status) => status === 400)).toHaveLength(
      1,
    );
    expect(
      acknowledgeResponses.find((response) => response.status === 201)?.body
        .incident.status,
    ).toBe('ACKNOWLEDGED');

    const [resolveResponse1, resolveResponse2] = await Promise.all([
      request(app.getHttpServer())
        .post(`/manager/incidents/${createdIncidentId}/resolve`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ shiftId: activeShift.id }),
      request(app.getHttpServer())
        .post(`/manager/incidents/${createdIncidentId}/resolve`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({ shiftId: activeShift.id }),
    ]);
    const resolveResponses = [
      typedResponse<ManagerIncidentTransitionResponse>(resolveResponse1),
      typedResponse<ManagerIncidentTransitionResponse>(resolveResponse2),
    ];

    const resolveStatuses = resolveResponses.map((response) => response.status);
    expect(resolveStatuses.filter((status) => status === 201)).toHaveLength(1);
    expect(resolveStatuses.filter((status) => status === 400)).toHaveLength(1);
    expect(
      resolveResponses.find((response) => response.status === 201)?.body
        .incident.status,
    ).toBe('RESOLVED');

    const incidentAuditTrail = (
      await prisma.auditEvent.findMany({
        where: {
          kind: {
            in: ['INCIDENT_ACKNOWLEDGED', 'INCIDENT_RESOLVED'],
          },
        },
      })
    ).filter(
      (event) =>
        getAuditDetailString(event.details, 'incidentId') === createdIncidentId,
    );

    expect(
      incidentAuditTrail.filter(
        (event) => event.kind === 'INCIDENT_ACKNOWLEDGED',
      ),
    ).toHaveLength(1);
    expect(
      incidentAuditTrail.filter((event) => event.kind === 'INCIDENT_RESOLVED'),
    ).toHaveLength(1);
  });

  it('rejects manager incident actions outside the selected unit scope', async () => {
    const accessToken = await login('manager@sercesync.local');

    await request(app.getHttpServer())
      .post(`/manager/incidents/${seededIncidents.red.id}/acknowledge`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({ shiftId: secondaryActiveShift.id })
      .expect(404);
  });

  it('allows a manager to create and edit residents with baseline priority', async () => {
    const accessToken = await login('manager@sercesync.local');

    const createResponse = typedResponse<ManagerResidentWriteResponse>(
      await request(app.getHttpServer())
        .post('/manager/residents')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          fullName: 'Eleanor Marsh',
          roomNumber: 31,
          floorNumber: 3,
          unitLabel: 'Cedar Floor',
          recognitionImageKey: 'resident-b',
          careSummary:
            'New resident with mobility prompts and hydration checks.',
          baselinePriority: 'AMBER',
          isActive: true,
        })
        .expect(201),
    );

    expect(createResponse.body.resident).toMatchObject({
      fullName: 'Eleanor Marsh',
      roomLabel: 'Room 31',
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
      baselinePriority: 'AMBER',
      effectivePriority: 'AMBER',
      prioritySource: 'BASELINE',
      activeIncidentCount: 0,
    });

    const residentId = createResponse.body.resident.id;

    const editResponse = typedResponse<ManagerResidentWriteResponse>(
      await request(app.getHttpServer())
        .patch(`/manager/residents/${residentId}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          roomNumber: 32,
          careSummary: 'Updated resident summary with clearer care priorities.',
          baselinePriority: 'GREEN',
          isActive: false,
        })
        .expect(200),
    );

    expect(editResponse.body.resident).toMatchObject({
      roomNumber: 32,
      roomLabel: 'Room 32',
      baselinePriority: 'GREEN',
      effectivePriority: 'GREEN',
      isActive: false,
    });
  });

  it('rejects whitespace-only manager resident fields after trimming', async () => {
    const accessToken = await login('manager@sercesync.local');

    await request(app.getHttpServer())
      .post('/manager/residents')
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        fullName: '   ',
        roomNumber: 45,
        floorNumber: 4,
        unitLabel: 'Cedar Floor',
        recognitionImageKey: 'resident-a',
        careSummary: 'Valid summary',
        baselinePriority: 'GREEN',
        isActive: true,
      })
      .expect(400);

    const createResponse = typedResponse<ManagerResidentWriteResponse>(
      await request(app.getHttpServer())
        .post('/manager/residents')
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          fullName: 'Helen Morris',
          roomNumber: 46,
          floorNumber: 4,
          unitLabel: 'Cedar Floor',
          recognitionImageKey: 'resident-b',
          careSummary: 'Valid summary for update validation coverage.',
          baselinePriority: 'GREEN',
          isActive: true,
        })
        .expect(201),
    );

    const residentId = createResponse.body.resident.id;

    await request(app.getHttpServer())
      .patch(`/manager/residents/${residentId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        careSummary: '   ',
      })
      .expect(400);

    const resident = await prisma.resident.findUniqueOrThrow({
      where: {
        id: residentId,
      },
    });

    expect(resident.careSummary).toBe(
      'Valid summary for update validation coverage.',
    );
  });

  it('supports resident timeline media evidence upload and retrieval', async () => {
    const accessToken = await login('carer@sercesync.local');

    const createResponse = typedResponse<ResidentTimelineMediaUploadResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[0].id}/timeline`)
        .set('Authorization', `Bearer ${accessToken}`)
        .field('type', 'OBSERVATION')
        .field('details', 'Photo evidence captured for skin integrity review.')
        .attach('evidence', Buffer.from('fake-image-data'), {
          filename: 'skin-check.jpg',
          contentType: 'image/jpeg',
        })
        .expect(201),
    );

    expect(createResponse.body.entry.media).toHaveLength(1);
    const mediaId = createResponse.body.entry.media[0].id;

    await request(app.getHttpServer())
      .get(`/resident-media/${mediaId}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(200)
      .expect('Content-Type', /image\/jpeg/);
  });

  it('does not allow access to a resident outside the assigned floor scope', async () => {
    const accessToken = await login('carer@sercesync.local');

    await request(app.getHttpServer())
      .get(`/residents/${outOfScopeResident.id}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);
  });

  it('returns a live shift overview with current and upcoming assignments', async () => {
    const accessToken = await login('carer@sercesync.local');

    const overviewResponse = typedResponse<ShiftOverviewResponse>(
      await request(app.getHttpServer())
        .get('/shifts/my')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

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

  it('rejects protected task access without a bearer token', () => {
    return request(app.getHttpServer()).get('/tasks/current').expect(401);
  });
});
