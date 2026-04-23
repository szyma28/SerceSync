import { INestApplication } from '@nestjs/common';
import type { Incident, Resident, Shift, Task } from '@prisma/client';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { getAuditDetailString } from './../src/audit-event-details';
import { AppModule } from './../src/app.module';
import { MANAGER_SESSION_COOKIE_NAME } from './../src/auth/auth.constants';
import { configureHttpApp } from './../src/http-security';
import { MedicationsService } from './../src/medications/medications.service';
import { ManagerDashboardStreamService } from './../src/manager-dashboard-stream/manager-dashboard-stream.service';
import { PrismaService } from './../src/prisma/prisma.service';

describe('SerceSync workflow slices (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  let seededTasks: Task[];
  let seededResidents: Resident[];
  let activeShift: Shift;
  let mapleActiveShift: Shift;
  let cedarActiveShift: Shift;
  let seededIncidents: {
    amber: Incident;
    red: Incident;
  };
  let mapleFloorIncident: Incident;
  let cedarFloorIncident: Incident;
  let outOfScopeResident: Resident;
  let cedarFloorResident: Resident;
  let nurseUserId: string;
  const allowedManagerOrigin = 'http://localhost:8080';
  const disallowedWebOrigin = 'https://evil.example';

  const residentNames = [
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
  ];

  const mapleResidentNames = [
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
  ];

  const cedarResidentNames = [
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
      focus: string;
      clinicalPriority: string;
      canComplete: boolean;
      canDefer: boolean;
      canEscalate: boolean;
      actionRestrictionReason: string | null;
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
    aboutMe?: string;
    effectivePriority: string;
    prioritySource: string;
    medicationSummary: {
      total: number;
      overdue: number;
      dueWithinHour: number;
      highPriority: number;
      headline: string | null;
      warnings: string[];
    };
    activeIncidents: Array<{
      id: string;
      severity: string;
      status: string;
      category: string;
    }>;
    currentTasks: Array<{
      id: string;
      focus: string;
      title: string;
    }>;
    timeline: Array<{
      type: string;
      personalCareSubtype?: string;
      mealType?: string;
      mealIntakeAmount?: string;
    }>;
  };

  type ResidentTimelineWriteResponse = {
    entry: {
      id: string;
      type: string;
      personalCareSubtype?: string;
      mealType?: string;
      mealIntakeAmount?: string;
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
      name: string;
      floorNumber: number;
      unitLabel: string;
    }>;
  };

  type ManagerDashboardResponse = {
    activeShift: {
      id: string;
    };
    metrics: {
      activeIncidents: number;
      overdueTasks?: number;
      escalatedItems?: number;
      unreadHandovers?: number;
      shiftCompletionPercent?: number;
    };
    exceptionFeed: Array<{
      kind: string;
      id: string;
      shiftId: string;
      floorNumber: number;
      unitLabel: string;
      roomLabel: string;
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
      floorNumber: number;
      unitLabel: string;
      shiftId: string;
      description: string;
      actorName: string | null;
      badge: string;
      badgeTone?: string;
    }>;
    medicationOverview?: Awaited<
      ReturnType<MedicationsService['buildManagerMedicationOverview']>
    >;
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
      aboutMe?: string;
      baselinePriority?: string;
      effectivePriority?: string;
      prioritySource?: string;
      activeIncidentCount?: number;
      isActive?: boolean;
    };
  };

  type ManagerResidentsResponse = {
    residents: Array<{
      id: string;
      fullName: string;
      roomNumber: number;
      roomLabel: string;
      floorNumber: number;
      unitLabel: string;
    }>;
  };

  type ShiftOverviewResponse = {
    currentShift: {
      name: string;
      floorNumber: number;
      unitLabel: string;
    };
    medicationSummary: {
      total: number;
      overdue: number;
      dueWithinHour: number;
      highPriority: number;
      headline: string | null;
      warnings: string[];
    };
  };

  type ResidentEmarResponse = {
    workflowNote: string;
    resident: {
      id: string;
      fullName: string;
      roomLabel: string;
    };
    chart: {
      id: string;
      status: string;
    };
    allergies: Array<{
      id: string;
      substance: string;
      reaction: string | null;
      severity: string | null;
    }>;
    scheduledMedications: Array<{
      id: string;
      medicationName: string;
      isPRN: boolean;
      schedules: Array<{
        id: string;
        roundLabel: string;
        anchorType: string;
      }>;
    }>;
    prnMedications: Array<{
      id: string;
      medicationName: string;
      isPRN: boolean;
      schedules: Array<{
        id: string;
      }>;
      prnProtocol: {
        id: string;
        minimumIntervalMinutes: number | null;
      } | null;
    }>;
    recentEvents: Array<{
      id: string;
      eventType: string;
      medicationOrderId: string;
      medicationName: string;
      reason: string | null;
    }>;
    changeHistory: Array<{
      id: string;
      changeType: string;
    }>;
  };

  type MedicationOrderWriteResponse = {
    workflowNote: string;
    medicationOrder: {
      id: string;
      medicationName: string;
      isPRN: boolean;
      schedules: Array<{
        id: string;
      }>;
      prnProtocol: {
        id: string;
      } | null;
    };
  };

  type MedicationScheduleWriteResponse = {
    workflowNote: string;
    schedule: {
      id: string;
      roundLabel: string;
      anchorType: string;
      windowStartOffsetMinutes: number | null;
      windowEndOffsetMinutes: number | null;
      fixedTimeLocal: string | null;
      active: boolean;
    };
  };

  type MedicationRoundGenerateResponse = {
    generatedCount: number;
    generatedDoseInstanceIds: string[];
    shift: {
      id: string;
      handoverAcknowledged: boolean;
      handoverAcknowledgedAt: string | null;
    };
  };

  type MedicationRoundResponse = {
    workflowNote: string;
    safetyBanner: string;
    shift: {
      id: string;
      handoverAcknowledged: boolean;
      handoverAcknowledgedAt: string | null;
    };
    witnessCandidates: Array<{
      id: string;
      displayName: string;
      role: string;
    }>;
    groupedRounds: Array<{
      roundLabel: string;
      items: Array<{
        id: string;
        residentId: string;
        residentName: string;
        roomLabel: string;
        medicationOrderId: string;
        medicationName: string;
        status: string;
        dueWindowStart: string;
        dueWindowEnd: string;
        reason: string | null;
      }>;
    }>;
  };

  type MedicationOutcomeResponse = {
    workflowNote: string;
    doseInstance: {
      id: string;
      status: string;
      reason: string | null;
    };
    administrationEvent: {
      id: string;
      eventType: string;
      reason: string | null;
    };
  };

  type ManagerMedicationExceptionsResponse = {
    workflowNote: string;
    exceptions: Array<{
      doseInstanceId: string;
      residentId: string;
      residentName: string;
      medicationName: string;
      status: string;
      reason: string | null;
      residentEmarPath: string;
    }>;
    recentPrnEvents: Array<{
      id: string;
      eventType: string;
      medicationName: string;
    }>;
    recentChanges: Array<{
      id: string;
      changeType: string;
      medicationName: string;
    }>;
  };

  type ManagerOverdueMedicationResponse = {
    workflowNote: string;
    overdueMedication: Array<{
      doseInstanceId: string;
      residentName: string;
      medicationName: string;
      status: string;
    }>;
  };

  beforeAll(async () => {
    process.env.WEB_APP_URL ??= allowedManagerOrigin;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    configureHttpApp(app);
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

  async function acknowledgeCurrentHandover(accessToken: string) {
    return typedResponse<HandoverCurrentResponse>(
      await request(app.getHttpServer())
        .post('/handovers/current/acknowledge')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(201),
    );
  }

  function startOfToday() {
    const value = new Date();
    value.setHours(0, 0, 0, 0);
    return value;
  }

  async function ensureMedicationChart(residentId: string) {
    const existing = await prisma.residentMedicationChart.findFirst({
      where: {
        residentId,
        status: 'ACTIVE',
      },
    });
    if (existing) {
      return existing;
    }

    return prisma.residentMedicationChart.create({
      data: {
        residentId,
        status: 'ACTIVE',
        createdByUserId: nurseUserId,
      },
    });
  }

  async function seedMedicationOrder(args: {
    residentId: string;
    medicationName: string;
    formulation?: string;
    strength?: string;
    doseAmount?: string;
    doseUnit?: string;
    route?: string;
    instructions?: string;
    isPRN?: boolean;
    isControlledDrug?: boolean;
    requiresWitness?: boolean;
    startDate?: Date;
    endDate?: Date | null;
    sourceType?: 'MANUAL_ENTRY' | 'PHARMACY_SUPPLIED' | 'IMPORTED';
  }) {
    const chart = await ensureMedicationChart(args.residentId);

    return prisma.medicationOrder.create({
      data: {
        residentId: args.residentId,
        chartId: chart.id,
        medicationName: args.medicationName,
        formulation: args.formulation ?? 'tablet',
        strength: args.strength ?? '500mg tablet',
        doseAmount: args.doseAmount ?? '1',
        doseUnit: args.doseUnit ?? 'tablet',
        route: args.route ?? 'oral',
        instructions:
          args.instructions ?? 'Follow the resident MAR and medicines policy.',
        startDate: args.startDate ?? startOfToday(),
        endDate: args.endDate ?? null,
        isActive: true,
        isControlledDrug: args.isControlledDrug ?? false,
        requiresWitness: args.requiresWitness ?? false,
        isPRN: args.isPRN ?? false,
        sourceType: args.sourceType ?? 'MANUAL_ENTRY',
        createdByUserId: nurseUserId,
        updatedByUserId: nurseUserId,
      },
    });
  }

  async function seedMedicationSchedule(args: {
    medicationOrderId: string;
    roundLabel?: 'MORNING' | 'MIDDAY' | 'EVENING' | 'BEDTIME' | 'CUSTOM';
    anchorType?: 'SHIFT_START' | 'HANDOVER_ACKNOWLEDGED' | 'FIXED_TIME';
    windowStartOffsetMinutes?: number | null;
    windowEndOffsetMinutes?: number | null;
    fixedTimeLocal?: string | null;
    daysOfWeek?: string[];
  }) {
    return prisma.medicationSchedule.create({
      data: {
        medicationOrderId: args.medicationOrderId,
        roundLabel: args.roundLabel ?? 'MORNING',
        anchorType: args.anchorType ?? 'SHIFT_START',
        windowStartOffsetMinutes: args.windowStartOffsetMinutes ?? 0,
        windowEndOffsetMinutes: args.windowEndOffsetMinutes ?? 60,
        fixedTimeLocal: args.fixedTimeLocal ?? null,
        daysOfWeek: args.daysOfWeek ?? [],
        active: true,
      },
    });
  }

  beforeEach(async () => {
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
    await prisma.user.deleteMany();
    await prisma.role.deleteMany();

    const carerRole = await prisma.role.create({
      data: {
        key: 'CARER',
        label: 'Carer',
      },
    });

    const nurseRole = await prisma.role.create({
      data: {
        key: 'NURSE',
        label: 'Nurse',
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

    const nurse = await prisma.user.create({
      data: {
        email: 'nurse@sercesync.local',
        displayName: 'Nina Nurse',
        passwordHash,
        roleId: nurseRole.id,
      },
    });
    nurseUserId = nurse.id;

    await prisma.user.create({
      data: {
        email: 'manager@sercesync.local',
        displayName: 'Morgan Manager',
        passwordHash,
        roleId: managerRole.id,
      },
    });

    const mapleCarer = await prisma.user.create({
      data: {
        email: 'maple@sercesync.local',
        displayName: 'Mia Maple',
        passwordHash,
        roleId: carerRole.id,
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
          baselinePriority: fullName === 'Emma Parker' ? 'AMBER' : 'GREEN',
        },
      });

      seededResidents.push(resident);
    }

    const mapleResidents: Resident[] = [];
    for (const [index, fullName] of mapleResidentNames.entries()) {
      mapleResidents.push(
        await prisma.resident.create({
          data: {
            fullName,
            roomNumber: index + 11,
            roomLabel: `Room ${index + 11}`,
            floorNumber: 2,
            unitLabel: 'Maple Floor',
            recognitionImageKey: [
              'resident-a',
              'resident-b',
              'resident-c',
              'resident-d',
            ][index % 4],
            careSummary: careSummaries[index % careSummaries.length],
            isActive: true,
            baselinePriority: 'GREEN',
          },
        }),
      );
    }

    const cedarResidents: Resident[] = [];
    for (const [index, fullName] of cedarResidentNames.entries()) {
      cedarResidents.push(
        await prisma.resident.create({
          data: {
            fullName,
            roomNumber: index + 21,
            roomLabel: `Room ${index + 21}`,
            floorNumber: 3,
            unitLabel: 'Cedar Floor',
            recognitionImageKey: [
              'resident-a',
              'resident-b',
              'resident-c',
              'resident-d',
            ][index % 4],
            careSummary: careSummaries[index % careSummaries.length],
            isActive: true,
            baselinePriority: 'GREEN',
          },
        }),
      );
    }

    outOfScopeResident = mapleResidents[0];
    cedarFloorResident = cedarResidents[0];

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
          connect: [{ id: carer.id }, { id: nurse.id }],
        },
      },
    });

    mapleActiveShift = await prisma.shift.create({
      data: {
        name: 'Maple Day Shift',
        startsAt: new Date(now.getTime() - 30 * 60 * 1000),
        endsAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
        status: 'ACTIVE',
        floorNumber: 2,
        unitLabel: 'Maple Floor',
        assignedUsers: {
          connect: [{ id: mapleCarer.id }],
        },
      },
    });

    cedarActiveShift = await prisma.shift.create({
      data: {
        name: 'Cedar Support Shift',
        startsAt: new Date(now.getTime() - 15 * 60 * 1000),
        endsAt: new Date(now.getTime() + 5 * 60 * 60 * 1000),
        status: 'ACTIVE',
        floorNumber: 3,
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
          'Margaret Evans needs an early hydration check and Emma Parker has an observation follow-up before lunch.',
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
          mealType: 'BREAKFAST',
          mealIntakeAmount: 'MOST',
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
        {
          residentId: outOfScopeResident.id,
          type: 'OBSERVATION',
          title: 'Maple reassurance round logged',
          details:
            'Settled after reassurance and stayed comfortable in the lounge.',
          createdById: mapleCarer.id,
          shiftId: mapleActiveShift.id,
          createdAt: new Date(now.getTime() - 18 * 60 * 1000),
        },
        {
          residentId: cedarFloorResident.id,
          type: 'MOBILITY_REPOSITIONING',
          title: 'Transfer comfort reviewed',
          details:
            'Comfort check completed after transfer support with pain monitoring to continue.',
          createdById: carer.id,
          shiftId: cedarActiveShift.id,
          createdAt: new Date(now.getTime() - 14 * 60 * 1000),
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
          focus: 'HYDRATION',
          clinicalPriority: 'ROUTINE',
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
          title: 'Observation follow-up for Emma Parker',
          description: 'Repeat observations before lunch.',
          focus: 'OBSERVATION',
          clinicalPriority: 'ROUTINE',
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
          title: 'Repositioning check for Elliot Turner',
          description: 'Review comfort positioning before the next round.',
          focus: 'MOBILITY',
          clinicalPriority: 'ROUTINE',
          status: 'PENDING',
          dueAt: new Date(now.getTime() - 10 * 60 * 1000),
          assignedUserId: carer.id,
        },
      }),
    );
    seededTasks.push(
      await prisma.task.create({
        data: {
          shiftId: activeShift.id,
          residentId: seededResidents[1].id,
          title: 'Medication round for Emma Parker',
          description: 'Time-critical morning medications are due soon.',
          focus: 'MEDICATION',
          clinicalPriority: 'TIME_CRITICAL',
          status: 'PENDING',
          dueAt: new Date(now.getTime() + 25 * 60 * 1000),
          assignedUserId: nurse.id,
        },
      }),
    );
    seededTasks.push(
      await prisma.task.create({
        data: {
          shiftId: activeShift.id,
          residentId: seededResidents[4].id,
          title: 'Medication follow-up for Amir Hussain',
          description: 'Overdue analgesia review still needs documenting.',
          focus: 'MEDICATION',
          clinicalPriority: 'PRIORITY',
          status: 'PENDING',
          dueAt: new Date(now.getTime() - 18 * 60 * 1000),
          assignedUserId: nurse.id,
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

    mapleFloorIncident = await prisma.incident.create({
      data: {
        residentId: outOfScopeResident.id,
        shiftId: mapleActiveShift.id,
        createdById: mapleCarer.id,
        severity: 'AMBER',
        status: 'OPEN',
        category: 'OTHER',
        title: 'Maple Floor reassurance call',
        details:
          'Should only surface in the global dashboard because the floor is active.',
        occurredAt: new Date(now.getTime() - 9 * 60 * 1000),
      },
    });

    cedarFloorIncident = await prisma.incident.create({
      data: {
        residentId: cedarFloorResident.id,
        shiftId: cedarActiveShift.id,
        createdById: carer.id,
        severity: 'RED',
        status: 'OPEN',
        category: 'BEHAVIOUR',
        title: 'Cedar distress episode',
        details:
          'Should only surface in the global dashboard because the floor is active.',
        occurredAt: new Date(now.getTime() - 7 * 60 * 1000),
      },
    });
  });

  afterAll(async () => {
    if (app) {
      await app.close();
    }
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

  it('applies security headers and only grants credentialed CORS access to allowlisted web origins', async () => {
    const allowedResponse = await request(app.getHttpServer())
      .get('/')
      .set('Origin', allowedManagerOrigin)
      .expect(200);

    expect(allowedResponse.headers['access-control-allow-origin']).toBe(
      allowedManagerOrigin,
    );
    expect(allowedResponse.headers['access-control-allow-credentials']).toBe(
      'true',
    );
    expect(allowedResponse.headers['x-content-type-options']).toBe('nosniff');
    expect(allowedResponse.headers['x-frame-options']).toBe('DENY');

    const blockedResponse = await request(app.getHttpServer())
      .get('/')
      .set('Origin', disallowedWebOrigin)
      .expect(200);

    expect(blockedResponse.headers['access-control-allow-origin']).toBeFalsy();
    expect(
      blockedResponse.headers['access-control-allow-credentials'],
    ).toBeFalsy();
  });

  it('rate limits repeated login attempts for the same email identity', async () => {
    for (let attempt = 0; attempt < 20; attempt += 1) {
      await request(app.getHttpServer())
        .post('/auth/login')
        .send({
          email: 'blocked.user@sercesync.local',
          password: 'WrongPassword123!',
        })
        .expect(401);
    }

    await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'blocked.user@sercesync.local',
        password: 'WrongPassword123!',
      })
      .expect(429);
  });

  it('creates and restores a manager browser session with an HttpOnly cookie', async () => {
    const loginResponse = await loginManagerBrowser('manager@sercesync.local');
    const sessionCookie = loginResponse.headers['set-cookie'];

    expect(
      (loginResponse.body as Record<string, unknown>).accessToken,
    ).toBeUndefined();
    expect(loginResponse.body.user.email).toBe('manager@sercesync.local');
    expect(loginResponse.headers['cache-control']).toContain('no-store');
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
    expect(
      (sessionResponse.body as Record<string, unknown>).accessToken,
    ).toBeUndefined();
    expect(sessionResponse.headers['cache-control']).toContain('no-store');

    const shiftsResponse = typedResponse<ManagerShiftsResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard/shifts')
        .set('Cookie', sessionCookie)
        .expect(200),
    );

    expect(shiftsResponse.body.activeShifts).toHaveLength(3);

    const logoutResponse = typedResponse<LogoutResponse>(
      await request(app.getHttpServer())
        .post('/auth/manager/logout')
        .set('Cookie', sessionCookie)
        .set('Origin', allowedManagerOrigin)
        .expect(200),
    );

    expect(logoutResponse.body).toEqual({ success: true });
    expect(logoutResponse.headers['cache-control']).toContain('no-store');
    expect(logoutResponse.headers['set-cookie']).toEqual(
      expect.arrayContaining([
        expect.stringContaining(`${MANAGER_SESSION_COOKIE_NAME}=;`),
      ]),
    );
  });

  it('blocks cookie-authenticated manager write requests from missing or disallowed browser origins', async () => {
    const loginResponse = await loginManagerBrowser('manager@sercesync.local');
    const sessionCookie = loginResponse.headers['set-cookie'];

    await request(app.getHttpServer())
      .post('/auth/manager/logout')
      .set('Cookie', sessionCookie)
      .expect(403);

    await request(app.getHttpServer())
      .post('/manager/residents')
      .set('Cookie', sessionCookie)
      .set('Origin', disallowedWebOrigin)
      .send({})
      .expect(403);

    await request(app.getHttpServer())
      .post('/manager/residents')
      .set('Cookie', sessionCookie)
      .set('Origin', allowedManagerOrigin)
      .send({})
      .expect(400);
  });

  it('marks token-bearing auth responses as non-cacheable', async () => {
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: 'carer@sercesync.local',
        password: 'Password123!',
      })
      .expect(201);

    expect(loginResponse.headers['cache-control']).toContain('no-store');
    expect(loginResponse.headers['pragma']).toBe('no-cache');

    const refreshResponse = await request(app.getHttpServer())
      .post('/auth/refresh')
      .send({
        refreshToken: loginResponse.body.refreshToken,
      })
      .expect(200);

    expect(refreshResponse.headers['cache-control']).toContain('no-store');
  });

  it('returns all thirty seeded residents to the manager in floor and room order', async () => {
    const accessToken = await login('manager@sercesync.local');

    const residentsResponse = typedResponse<ManagerResidentsResponse>(
      await request(app.getHttpServer())
        .get('/manager/residents')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(residentsResponse.body.residents).toHaveLength(30);
    expect(residentsResponse.body.residents[0]).toMatchObject({
      fullName: 'Margaret Evans',
      roomNumber: 1,
      roomLabel: 'Room 1',
      floorNumber: 1,
      unitLabel: 'Willow Floor',
    });
    expect(residentsResponse.body.residents[9]).toMatchObject({
      fullName: 'Lily Bennett',
      roomNumber: 10,
      floorNumber: 1,
      unitLabel: 'Willow Floor',
    });
    expect(residentsResponse.body.residents[10]).toMatchObject({
      fullName: 'Daniel Miller',
      roomNumber: 11,
      floorNumber: 2,
      unitLabel: 'Maple Floor',
    });
    expect(residentsResponse.body.residents[20]).toMatchObject({
      fullName: 'Agnes Cook',
      roomNumber: 21,
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
    });
    expect(residentsResponse.body.residents[29]).toMatchObject({
      fullName: 'Ryan Coleman',
      roomNumber: 30,
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
    });
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
    expect(
      tasksResponse.body.tasks.filter((task) => task.focus === 'MEDICATION'),
    ).toHaveLength(0);

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
    expect(
      refreshedTasksResponse.body.tasks.filter(
        (task) => task.status === 'ESCALATED',
      ),
    ).toHaveLength(1);
    expect(
      refreshedTasksResponse.body.tasks.filter(
        (task) => task.focus === 'MEDICATION',
      ),
    ).toHaveLength(0);

    const auditEvents = await prisma.auditEvent.findMany({
      where: {
        kind: {
          in: ['TASK_COMPLETED', 'TASK_DEFERRED', 'TASK_ESCALATED'],
        },
      },
    });

    expect(auditEvents).toHaveLength(3);
  });

  it('allows only nurses to update medication tasks', async () => {
    const carerAccessToken = await login('carer@sercesync.local');

    const currentTasksResponse = typedResponse<TasksCurrentResponse>(
      await request(app.getHttpServer())
        .get('/tasks/current')
        .set('Authorization', `Bearer ${carerAccessToken}`)
        .expect(200),
    );

    expect(
      currentTasksResponse.body.tasks.filter(
        (task) => task.focus === 'MEDICATION',
      ),
    ).toHaveLength(0);

    const forbiddenResponse = typedResponse<{
      message: string;
      code: string;
    }>(
      await request(app.getHttpServer())
        .post(`/tasks/${seededTasks[3].id}/complete`)
        .set('Authorization', `Bearer ${carerAccessToken}`)
        .send({
          note: 'Attempted by carer without nurse access.',
        })
        .expect(403),
    );

    expect(forbiddenResponse.body).toMatchObject({
      message: 'Only nurses can administer medication.',
      code: 'MEDICATION_NURSE_REQUIRED',
    });

    const medicationTaskToEscalate = await prisma.task.create({
      data: {
        shiftId: activeShift.id,
        residentId: seededResidents[5].id,
        title: 'Medication review for Sheila Morgan',
        description: 'Escalate the medication concern to the clinician.',
        focus: 'MEDICATION',
        clinicalPriority: 'PRIORITY',
        status: 'PENDING',
        dueAt: new Date(Date.now() + 45 * 60 * 1000),
        assignedUserId: nurseUserId,
      },
    });

    const nurseAccessToken = await login('nurse@sercesync.local');
    const nurseCurrentTasksResponse = typedResponse<TasksCurrentResponse>(
      await request(app.getHttpServer())
        .get('/tasks/current')
        .set('Authorization', `Bearer ${nurseAccessToken}`)
        .expect(200),
    );

    expect(
      nurseCurrentTasksResponse.body.tasks.filter(
        (task) => task.focus === 'MEDICATION',
      ),
    ).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: seededTasks[3].id,
          canComplete: true,
          canDefer: true,
          canEscalate: true,
          actionRestrictionReason: null,
        }),
        expect.objectContaining({
          id: seededTasks[4].id,
          canComplete: true,
          canDefer: true,
          canEscalate: true,
          actionRestrictionReason: null,
        }),
      ]),
    );

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[3].id}/complete`)
      .set('Authorization', `Bearer ${nurseAccessToken}`)
      .send({
        note: 'Medication given and documented by the nurse.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tasks/${seededTasks[4].id}/defer`)
      .set('Authorization', `Bearer ${nurseAccessToken}`)
      .send({
        reason: 'Resident requested a short delay before taking medication.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/tasks/${medicationTaskToEscalate.id}/escalate`)
      .set('Authorization', `Bearer ${nurseAccessToken}`)
      .send({
        reason: 'Clinical review is required before the next medication round.',
      })
      .expect(201);
  });

  it('returns residents with derived priority state and active incidents on detail', async () => {
    const accessToken = await login('carer@sercesync.local');
    const residentViewAuditCountBefore = await prisma.auditEvent.count({
      where: {
        kind: 'RESIDENT_RECORD_VIEWED',
      },
    });

    const residentsResponse = typedResponse<ResidentsListResponse>(
      await request(app.getHttpServer())
        .get('/residents')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    const raj = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Emma Parker',
    );
    const edith = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Elliot Turner',
    );
    const thomas = residentsResponse.body.residents.find(
      (resident) => resident.fullName === 'Thea Green',
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

    const rajResidentDetailResponse = typedResponse<ResidentDetailResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[1].id}`)
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(rajResidentDetailResponse.body.medicationSummary).toMatchObject({
      total: 0,
      overdue: 0,
      dueWithinHour: 0,
      highPriority: 0,
    });
    expect(
      rajResidentDetailResponse.body.currentTasks.filter(
        (task) => task.focus === 'MEDICATION',
      ),
    ).toHaveLength(0);

    const nurseAccessToken = await login('nurse@sercesync.local');
    const rajResidentDetailForNurseResponse =
      typedResponse<ResidentDetailResponse>(
        await request(app.getHttpServer())
          .get(`/residents/${seededResidents[1].id}`)
          .set('Authorization', `Bearer ${nurseAccessToken}`)
          .expect(200),
      );

    expect(
      rajResidentDetailForNurseResponse.body.medicationSummary,
    ).toMatchObject({
      total: 1,
      overdue: 0,
      dueWithinHour: 1,
      highPriority: 1,
    });
    expect(rajResidentDetailForNurseResponse.body.currentTasks).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          focus: 'MEDICATION',
        }),
      ]),
    );

    const residentViewAudit = await prisma.auditEvent.findFirstOrThrow({
      where: {
        kind: 'RESIDENT_RECORD_VIEWED',
        residentId: seededResidents[1].id,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    expect(await prisma.auditEvent.count({
      where: {
        kind: 'RESIDENT_RECORD_VIEWED',
      },
    })).toBeGreaterThan(residentViewAuditCountBefore);
    expect(residentViewAudit.details).toMatchObject({
      residentId: seededResidents[1].id,
      residentName: seededResidents[1].fullName,
      viewerRole: 'NURSE',
      medicationContentVisible: true,
      accessScope: 'active-shift-floor-scope',
    });
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

  it('allows only nurses to create medication notes for residents', async () => {
    const carerAccessToken = await login('carer@sercesync.local');

    const forbiddenResponse = typedResponse<{
      message: string;
      code: string;
    }>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[1].id}/timeline`)
        .set('Authorization', `Bearer ${carerAccessToken}`)
        .send({
          type: 'MEDICATION_NOTE',
          details: 'Medication withheld pending swallow review.',
        })
        .expect(403),
    );

    expect(forbiddenResponse.body).toMatchObject({
      message: 'Only nurses can add medication notes.',
      code: 'MEDICATION_NOTE_NURSE_REQUIRED',
    });

    const nurseAccessToken = await login('nurse@sercesync.local');
    const successResponse = typedResponse<ResidentTimelineWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[1].id}/timeline`)
        .set('Authorization', `Bearer ${nurseAccessToken}`)
        .send({
          type: 'MEDICATION_NOTE',
          details: 'Medication administered and tolerance recorded.',
        })
        .expect(201),
    );

    expect(successResponse.body.entry.type).toBe('MEDICATION_NOTE');
  });

  it('creates structured meal intake notes and rejects invalid meal payloads', async () => {
    const accessToken = await login('carer@sercesync.local');

    const successResponse = typedResponse<ResidentTimelineWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[4].id}/timeline`)
        .set('Authorization', `Bearer ${accessToken}`)
        .send({
          type: 'NUTRITION_HYDRATION',
          mealType: 'LUNCH',
          mealIntakeAmount: 'HALF',
        })
        .expect(201),
    );

    expect(successResponse.body.entry.type).toBe('NUTRITION_HYDRATION');
    expect(successResponse.body.entry.mealType).toBe('LUNCH');
    expect(successResponse.body.entry.mealIntakeAmount).toBe('HALF');

    const createdEntry = await prisma.residentTimelineEntry.findFirstOrThrow({
      where: {
        residentId: seededResidents[4].id,
        mealType: 'LUNCH',
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    expect(createdEntry.mealIntakeAmount).toBe('HALF');
    expect(createdEntry.details).toBe('No additional concerns noted.');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[4].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'OBSERVATION',
        mealType: 'DINNER',
        mealIntakeAmount: 'MOST',
        details: 'Meal data should not be allowed on an observation.',
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[4].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'NUTRITION_HYDRATION',
        mealType: 'DINNER',
        details: 'Partial meal payload should be rejected.',
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
      .post(`/residents/${seededResidents[5].id}/incidents`)
      .set('Authorization', `Bearer ${accessToken}`)
      .field('severity', 'RED')
      .field('category', 'INJURY')
      .field('title', 'Unsafe upload rejected')
      .field('details', 'SVG evidence should be rejected for demo safety.')
      .attach('evidence', Buffer.from('<svg></svg>'), {
        filename: 'unsafe.svg',
        contentType: 'image/svg+xml',
      })
      .expect(400);

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

  it('loads a global manager dashboard across all active shifts by default', async () => {
    const accessToken = await login('manager@sercesync.local');

    const dashboardResponse = typedResponse<ManagerDashboardResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(dashboardResponse.body.activeShift.id).toBe(cedarActiveShift.id);
    expect(dashboardResponse.body.metrics.activeIncidents).toBe(4);
    expect(
      dashboardResponse.body.exceptionFeed.map(
        (item: { id: string }) => item.id,
      ),
    ).toEqual(
      expect.arrayContaining([
        seededIncidents.red.id,
        seededIncidents.amber.id,
        cedarFloorIncident.id,
      ]),
    );
    expect(
      dashboardResponse.body.exceptionFeed.some(
        (item: { kind: string }) => item.kind === 'TASK',
      ),
    ).toBe(true);
    expect(
      dashboardResponse.body.medicationOverview?.exceptions.every(
        (item: { id: string; doseInstanceId: string }) =>
          item.id === item.doseInstanceId,
      ) ?? false,
    ).toBe(true);
    expect(
      dashboardResponse.body.exceptionFeed.map(
        (item: { shiftId: string }) => item.shiftId,
      ),
    ).toEqual(expect.arrayContaining([activeShift.id, cedarActiveShift.id]));
  });

  it('lists active shifts and returns a focused dashboard for the selected shift', async () => {
    const accessToken = await login('manager@sercesync.local');

    const activeShiftsResponse = typedResponse<ManagerShiftsResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard/shifts')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(activeShiftsResponse.body.activeShifts).toHaveLength(3);
    expect(
      activeShiftsResponse.body.activeShifts.map(
        (shift: { id: string }) => shift.id,
      ),
    ).toEqual([cedarActiveShift.id, mapleActiveShift.id, activeShift.id]);

    const selectedShiftDashboardResponse =
      typedResponse<ManagerDashboardResponse>(
        await request(app.getHttpServer())
          .get('/manager/dashboard')
          .query({ shiftId: activeShift.id })
          .set('Authorization', `Bearer ${accessToken}`)
          .expect(200),
      );

    expect(selectedShiftDashboardResponse.body.activeShift.id).toBe(
      activeShift.id,
    );
    expect(selectedShiftDashboardResponse.body.metrics.activeIncidents).toBe(2);
    expect(selectedShiftDashboardResponse.body.exceptionFeed).toHaveLength(5);
    expect(selectedShiftDashboardResponse.body.exceptionFeed[0]).toMatchObject({
      kind: 'INCIDENT',
      id: seededIncidents.red.id,
      shiftId: activeShift.id,
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      roomLabel: seededResidents[3].roomLabel,
      status: 'OPEN',
      severity: 'RED',
      canAcknowledge: true,
      canResolve: false,
    });
    expect(selectedShiftDashboardResponse.body.exceptionFeed[1]).toMatchObject({
      kind: 'INCIDENT',
      id: seededIncidents.amber.id,
      shiftId: activeShift.id,
      floorNumber: 1,
      unitLabel: 'Willow Floor',
      roomLabel: seededResidents[2].roomLabel,
      status: 'OPEN',
      severity: 'AMBER',
      canAcknowledge: true,
      canResolve: false,
    });
    expect(
      selectedShiftDashboardResponse.body.exceptionFeed.findIndex(
        (item: { kind: string; id: string }) => item.kind === 'TASK',
      ),
    ).toBeGreaterThan(1);
    expect(
      selectedShiftDashboardResponse.body.exceptionFeed.some(
        (item: { id: string }) => item.id === cedarFloorIncident.id,
      ),
    ).toBe(false);

    const secondaryDashboardResponse = typedResponse<ManagerDashboardResponse>(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .query({ shiftId: cedarActiveShift.id })
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(200),
    );

    expect(secondaryDashboardResponse.body.activeShift.id).toBe(
      cedarActiveShift.id,
    );
    expect(secondaryDashboardResponse.body.metrics.activeIncidents).toBe(1);
    expect(secondaryDashboardResponse.body.exceptionFeed[0]).toMatchObject({
      kind: 'INCIDENT',
      id: cedarFloorIncident.id,
      shiftId: cedarActiveShift.id,
      floorNumber: 3,
      unitLabel: 'Cedar Floor',
      roomLabel: cedarFloorResident.roomLabel,
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
          floorNumber: 1,
          unitLabel: 'Willow Floor',
          shiftId: activeShift.id,
          description: 'Continence support provided and fresh pads applied.',
          actorName: 'Alex Carer',
          badge: 'PERSONAL CARE',
        }),
        expect.objectContaining({
          kind: 'TASK',
          title: seededTasks[0].title,
          residentName: seededResidents[0].fullName,
          roomLabel: seededResidents[0].roomLabel,
          floorNumber: 1,
          unitLabel: 'Willow Floor',
          shiftId: activeShift.id,
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

  it('broadcasts shift dashboard updates when that active shift changes', async () => {
    const streamService = app.get(ManagerDashboardStreamService);

    const payloadPromise = new Promise<{
      connected: {
        type: string;
        shiftId: string;
        reason: string;
      };
      updated: {
        type: string;
        shiftId: string;
        reason: string;
      };
    }>((resolve, reject) => {
      const events: Array<{
        type: string;
        shiftId: string;
        reason: string;
      }> = [];

      streamService.streamForShift(mapleActiveShift.id).subscribe({
        next: (event) => {
          events.push(
            event.data as {
              type: string;
              shiftId: string;
              reason: string;
            },
          );

          if (events.length === 2) {
            resolve({
              connected: {
                type: events[0].type,
                shiftId: events[0].shiftId,
                reason: events[0].reason,
              },
              updated: {
                type: events[1].type,
                shiftId: events[1].shiftId,
                reason: events[1].reason,
              },
            });
          }
        },
        error: reject,
      });
    });

    streamService.publishShiftUpdate(mapleActiveShift.id, 'incident-created');

    const payloads = await payloadPromise;

    expect(payloads.connected).toMatchObject({
      type: 'stream.connected',
      shiftId: mapleActiveShift.id,
      reason: 'connected',
    });
    expect(payloads.updated).toMatchObject({
      type: 'dashboard.updated',
      shiftId: mapleActiveShift.id,
      reason: 'incident-created',
    });
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
      .send({ shiftId: cedarActiveShift.id })
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
          aboutMe:
            'Needs mobility prompts, prefers calm pacing, and responds well to hydration reminders.',
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
      aboutMe:
        'Needs mobility prompts, prefers calm pacing, and responds well to hydration reminders.',
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
          aboutMe:
            'Prefers clear introductions, calm pacing, and a little extra reassurance before mobility support.',
          baselinePriority: 'GREEN',
          isActive: false,
        })
        .expect(200),
    );

    expect(editResponse.body.resident).toMatchObject({
      roomNumber: 32,
      roomLabel: 'Room 32',
      aboutMe:
        'Prefers clear introductions, calm pacing, and a little extra reassurance before mobility support.',
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
        roomNumber: 33,
        floorNumber: 3,
        unitLabel: 'Cedar Floor',
        recognitionImageKey: 'resident-a',
        aboutMe: 'Prefers simple routines and gentle prompts.',
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
          roomNumber: 34,
          floorNumber: 3,
          unitLabel: 'Cedar Floor',
          recognitionImageKey: 'resident-b',
          aboutMe:
            'Likes clear explanations, warm drinks, and a steady routine.',
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
        aboutMe: '   ',
      })
      .expect(400);

    const resident = await prisma.resident.findUniqueOrThrow({
      where: {
        id: residentId,
      },
    });

    expect(resident.careSummary).toBe(
      'Likes clear explanations, warm drinks, and a steady routine.',
    );
    expect(resident.aboutMe).toBe(
      'Likes clear explanations, warm drinks, and a steady routine.',
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
      .expect('Content-Type', /image\/jpeg/)
      .expect('Content-Disposition', /attachment;/)
      .expect('X-Content-Type-Options', 'nosniff');
  });

  it('rejects care notes with unrealistic future or stale recorded times', async () => {
    const accessToken = await login('carer@sercesync.local');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[0].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'OBSERVATION',
        details: 'Attempted future-dated note.',
        recordedAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[0].id}/timeline`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        type: 'OBSERVATION',
        details: 'Attempted stale note.',
        recordedAt: new Date(Date.now() - 96 * 60 * 60 * 1000).toISOString(),
      })
      .expect(400);
  });

  it('rejects incidents with unrealistic future or stale occurred times', async () => {
    const accessToken = await login('carer@sercesync.local');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/incidents`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        severity: 'AMBER',
        category: 'OTHER',
        title: 'Future-dated incident',
        details: 'This should fail timestamp validation.',
        occurredAt: new Date(Date.now() + 10 * 60 * 1000).toISOString(),
      })
      .expect(400);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[1].id}/incidents`)
      .set('Authorization', `Bearer ${accessToken}`)
      .send({
        severity: 'AMBER',
        category: 'OTHER',
        title: 'Stale incident',
        details: 'This should also fail timestamp validation.',
        occurredAt: new Date(Date.now() - 96 * 60 * 60 * 1000).toISOString(),
      })
      .expect(400);
  });

  it('does not allow access to a resident outside the assigned floor scope', async () => {
    const accessToken = await login('carer@sercesync.local');

    await request(app.getHttpServer())
      .get(`/residents/${outOfScopeResident.id}`)
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);
  });

  it('returns a live shift overview for the current shift only', async () => {
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
    expect(overviewResponse.body).not.toHaveProperty('assignments');
    expect(overviewResponse.body.medicationSummary).toMatchObject({
      total: 0,
      overdue: 0,
      dueWithinHour: 0,
      highPriority: 0,
    });

    const nurseAccessToken = await login('nurse@sercesync.local');
    const nurseOverviewResponse = typedResponse<ShiftOverviewResponse>(
      await request(app.getHttpServer())
        .get('/shifts/my')
        .set('Authorization', `Bearer ${nurseAccessToken}`)
        .expect(200),
    );

    expect(nurseOverviewResponse.body.medicationSummary).toMatchObject({
      total: 2,
      overdue: 1,
      dueWithinHour: 1,
      highPriority: 2,
    });
  });

  it('creates a medication chart, scheduled order, schedule, allergy, and change history on the resident eMAR', async () => {
    const managerToken = await login('manager@sercesync.local');
    const nurseToken = await login('nurse@sercesync.local');

    const createOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[0].id}/medications`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          medicationName: 'Paracetamol',
          formulation: 'tablet',
          strength: '500mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          route: 'oral',
          instructions: 'Give with water following the current MAR.',
          startDate: startOfToday().toISOString(),
          sourceType: 'MANUAL_ENTRY',
          changeReason: 'Initial medication chart order.',
        })
        .expect(201),
    );

    const medicationOrderId = createOrderResponse.body.medicationOrder.id;
    expect(createOrderResponse.body.medicationOrder).toMatchObject({
      medicationName: 'Paracetamol',
      isPRN: false,
    });

    const chartCount = await prisma.residentMedicationChart.count({
      where: {
        residentId: seededResidents[0].id,
        status: 'ACTIVE',
      },
    });
    expect(chartCount).toBe(1);

    const updateOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .patch(`/medications/${medicationOrderId}`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          instructions:
            'Give with water after breakfast following the current MAR.',
          reason: 'Clarified administration timing for the morning round.',
        })
        .expect(200),
    );
    expect(updateOrderResponse.body.medicationOrder.medicationName).toBe(
      'Paracetamol',
    );

    const createScheduleResponse =
      typedResponse<MedicationScheduleWriteResponse>(
        await request(app.getHttpServer())
          .post(`/medications/${medicationOrderId}/schedules`)
          .set('Authorization', `Bearer ${managerToken}`)
          .send({
            roundLabel: 'MORNING',
            anchorType: 'HANDOVER_ACKNOWLEDGED',
            windowStartOffsetMinutes: 0,
            windowEndOffsetMinutes: 60,
          })
          .expect(201),
      );
    expect(createScheduleResponse.body.schedule).toMatchObject({
      roundLabel: 'MORNING',
      anchorType: 'HANDOVER_ACKNOWLEDGED',
    });

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[0].id}/medication-allergies`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        substance: 'Penicillin',
        reaction: 'Rash',
        severity: 'Moderate',
      })
      .expect(201);

    const emarResponse = typedResponse<ResidentEmarResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[0].id}/emar`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(200),
    );

    expect(emarResponse.body.chart.status).toBe('ACTIVE');
    expect(emarResponse.body.allergies).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          substance: 'Penicillin',
          reaction: 'Rash',
          severity: 'Moderate',
        }),
      ]),
    );
    expect(emarResponse.body.scheduledMedications).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: medicationOrderId,
          medicationName: 'Paracetamol',
          isPRN: false,
          schedules: [
            expect.objectContaining({
              id: createScheduleResponse.body.schedule.id,
              roundLabel: 'MORNING',
              anchorType: 'HANDOVER_ACKNOWLEDGED',
            }),
          ],
        }),
      ]),
    );
    expect(
      emarResponse.body.changeHistory.map((entry) => entry.changeType),
    ).toEqual(
      expect.arrayContaining(['CREATED', 'UPDATED', 'SCHEDULE_CHANGED']),
    );
  });

  it('creates a PRN medication order and protocol, shows it on profile, and excludes it from timed medication rounds', async () => {
    const managerToken = await login('manager@sercesync.local');
    const nurseToken = await login('nurse@sercesync.local');

    const createPrnOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[1].id}/medications`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          medicationName: 'Paracetamol',
          formulation: 'oral suspension',
          strength: '250mg/5ml',
          doseAmount: '10',
          doseUnit: 'ml',
          route: 'oral',
          instructions: 'Offer when pain is reported or observed.',
          startDate: startOfToday().toISOString(),
          isPRN: true,
          sourceType: 'MANUAL_ENTRY',
          changeReason: 'PRN support order for the medication workflow.',
        })
        .expect(201),
    );

    const prnOrderId = createPrnOrderResponse.body.medicationOrder.id;
    expect(createPrnOrderResponse.body.medicationOrder.isPRN).toBe(true);

    await request(app.getHttpServer())
      .post(`/medications/${prnOrderId}/prn-protocol`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        indication: 'Pain or visible discomfort',
        whenToOffer: 'Offer when the resident reports pain after movement.',
        doseInstructions:
          'Give 10ml by mouth as required, following the current MAR.',
        minimumIntervalMinutes: 240,
        maxDosePer24Hours: 4,
        expectedEffect: 'Pain should ease within 45 minutes.',
        monitoringRequired: 'Re-check comfort after 30 minutes.',
        whenToEscalate: 'Escalate if pain does not improve.',
      })
      .expect(201);

    const emarResponse = typedResponse<ResidentEmarResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[1].id}/emar`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(200),
    );

    expect(emarResponse.body.prnMedications).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: prnOrderId,
          medicationName: 'Paracetamol',
          isPRN: true,
          schedules: [],
          prnProtocol: expect.objectContaining({
            minimumIntervalMinutes: 240,
          }),
        }),
      ]),
    );

    await acknowledgeCurrentHandover(nurseToken);
    await request(app.getHttpServer())
      .post(`/shifts/${activeShift.id}/generate-medication-round`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .expect(201);

    const roundResponse = typedResponse<MedicationRoundResponse>(
      await request(app.getHttpServer())
        .get(`/shifts/${activeShift.id}/medication-round`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(200),
    );

    const roundMedicationOrderIds = roundResponse.body.groupedRounds.flatMap(
      (group) => group.items.map((item) => item.medicationOrderId),
    );
    expect(roundMedicationOrderIds).not.toContain(prnOrderId);

    const doseInstanceCount = await prisma.medicationDoseInstance.count({
      where: {
        medicationOrderId: prnOrderId,
      },
    });
    expect(doseInstanceCount).toBe(0);
  });

  it('generates medication dose instances from shift-start and handover anchors with deterministic due windows and no duplicates', async () => {
    const nurseToken = await login('nurse@sercesync.local');
    const fixedShiftStart = new Date();
    fixedShiftStart.setHours(8, 0, 0, 0);
    const fixedShiftEnd = new Date(
      fixedShiftStart.getTime() + 8 * 60 * 60 * 1000,
    );

    activeShift = await prisma.shift.update({
      where: {
        id: activeShift.id,
      },
      data: {
        startsAt: fixedShiftStart,
        endsAt: fixedShiftEnd,
      },
    });

    const shiftAnchoredOrder = await seedMedicationOrder({
      residentId: seededResidents[0].id,
      medicationName: 'Amlodipine',
    });
    const shiftAnchoredSchedule = await seedMedicationSchedule({
      medicationOrderId: shiftAnchoredOrder.id,
      roundLabel: 'MORNING',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
    });

    const handoverAnchoredOrder = await seedMedicationOrder({
      residentId: seededResidents[1].id,
      medicationName: 'Donepezil',
    });
    const handoverAnchoredSchedule = await seedMedicationSchedule({
      medicationOrderId: handoverAnchoredOrder.id,
      roundLabel: 'MORNING',
      anchorType: 'HANDOVER_ACKNOWLEDGED',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
    });

    const initialGenerateResponse =
      typedResponse<MedicationRoundGenerateResponse>(
        await request(app.getHttpServer())
          .post(`/shifts/${activeShift.id}/generate-medication-round`)
          .set('Authorization', `Bearer ${nurseToken}`)
          .expect(201),
      );

    expect(initialGenerateResponse.body.generatedCount).toBe(1);

    const firstDoseInstance =
      await prisma.medicationDoseInstance.findUniqueOrThrow({
        where: {
          shiftId_scheduleId: {
            shiftId: activeShift.id,
            scheduleId: shiftAnchoredSchedule.id,
          },
        },
      });
    expect(firstDoseInstance.dueWindowStart.toISOString()).toBe(
      fixedShiftStart.toISOString(),
    );
    expect(firstDoseInstance.dueWindowEnd.toISOString()).toBe(
      new Date(fixedShiftStart.getTime() + 60 * 60 * 1000).toISOString(),
    );

    const shiftHandover = await prisma.handover.findFirstOrThrow({
      where: {
        shiftId: activeShift.id,
      },
    });
    const acknowledgedAt = new Date(fixedShiftStart.getTime() + 3 * 60 * 1000);
    await prisma.handoverAcknowledgement.create({
      data: {
        handoverId: shiftHandover.id,
        acknowledgedById: nurseUserId,
        acknowledgedAt,
      },
    });

    const secondGenerateResponse =
      typedResponse<MedicationRoundGenerateResponse>(
        await request(app.getHttpServer())
          .post(`/shifts/${activeShift.id}/generate-medication-round`)
          .set('Authorization', `Bearer ${nurseToken}`)
          .expect(201),
      );
    expect(secondGenerateResponse.body.generatedCount).toBe(1);

    const handoverDoseInstance =
      await prisma.medicationDoseInstance.findUniqueOrThrow({
        where: {
          shiftId_scheduleId: {
            shiftId: activeShift.id,
            scheduleId: handoverAnchoredSchedule.id,
          },
        },
      });
    expect(handoverDoseInstance.dueWindowStart.toISOString()).toBe(
      acknowledgedAt.toISOString(),
    );
    expect(handoverDoseInstance.dueWindowEnd.toISOString()).toBe(
      new Date(acknowledgedAt.getTime() + 60 * 60 * 1000).toISOString(),
    );

    const thirdGenerateResponse =
      typedResponse<MedicationRoundGenerateResponse>(
        await request(app.getHttpServer())
          .post(`/shifts/${activeShift.id}/generate-medication-round`)
          .set('Authorization', `Bearer ${nurseToken}`)
          .expect(201),
      );
    expect(thirdGenerateResponse.body.generatedCount).toBe(0);
  });

  it('blocks medication round access and medication actions before handover acknowledgement, then unlocks the round after acknowledgement', async () => {
    const nurseToken = await login('nurse@sercesync.local');
    const order = await seedMedicationOrder({
      residentId: seededResidents[2].id,
      medicationName: 'Metformin',
    });
    await seedMedicationSchedule({
      medicationOrderId: order.id,
      roundLabel: 'MORNING',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
    });

    const generateResponse = typedResponse<MedicationRoundGenerateResponse>(
      await request(app.getHttpServer())
        .post(`/shifts/${activeShift.id}/generate-medication-round`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(201),
    );
    const doseInstanceId = generateResponse.body.generatedDoseInstanceIds[0];

    const roundBeforeAcknowledgement = typedResponse<{ message: string }>(
      await request(app.getHttpServer())
        .get(`/shifts/${activeShift.id}/medication-round`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(403),
    );
    expect(roundBeforeAcknowledgement.body.message).toBe(
      'Medication actions are blocked until the current shift handover is acknowledged.',
    );

    const administerBeforeAcknowledgement = typedResponse<{ message: string }>(
      await request(app.getHttpServer())
        .post(`/medication-dose-instances/${doseInstanceId}/administer`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .send({
          doseGiven: '1',
          doseUnit: 'tablet',
        })
        .expect(403),
    );
    expect(administerBeforeAcknowledgement.body.message).toBe(
      'Medication actions are blocked until the current shift handover is acknowledged.',
    );

    await acknowledgeCurrentHandover(nurseToken);

    const roundAfterAcknowledgement = typedResponse<MedicationRoundResponse>(
      await request(app.getHttpServer())
        .get(`/shifts/${activeShift.id}/medication-round`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(200),
    );

    expect(roundAfterAcknowledgement.body.shift.handoverAcknowledged).toBe(
      true,
    );
    expect(roundAfterAcknowledgement.body.groupedRounds).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          roundLabel: 'MORNING',
          items: expect.arrayContaining([
            expect.objectContaining({
              id: doseInstanceId,
              medicationName: 'Metformin',
            }),
          ]),
        }),
      ]),
    );
  });

  it('rejects invalid resident and shift ids on resident profile and medication routes with 400 responses', async () => {
    const nurseToken = await login('nurse@sercesync.local');

    const invalidResidentProfile = typedResponse<{
      message: string | string[];
    }>(
      await request(app.getHttpServer())
        .get('/residents/null')
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(400),
    );
    expect(String(invalidResidentProfile.body.message)).toMatch(/uuid/i);

    const invalidResidentEmar = typedResponse<{ message: string | string[] }>(
      await request(app.getHttpServer())
        .get('/residents/null/emar')
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(400),
    );
    expect(String(invalidResidentEmar.body.message)).toMatch(/uuid/i);

    const invalidMedicationRound = typedResponse<{
      message: string | string[];
    }>(
      await request(app.getHttpServer())
        .get('/shifts/null/medication-round')
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(400),
    );
    expect(String(invalidMedicationRound.body.message)).toMatch(/uuid/i);
  });

  it('writes an audit event when a resident medication chart is viewed', async () => {
    const nurseToken = await login('nurse@sercesync.local');
    await seedMedicationOrder({
      residentId: seededResidents[2].id,
      medicationName: 'Atorvastatin',
    });

    const medicationViewAuditCountBefore = await prisma.auditEvent.count({
      where: {
        kind: 'MEDICATION_RECORD_VIEWED',
      },
    });

    await request(app.getHttpServer())
      .get(`/residents/${seededResidents[2].id}/emar`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .expect(200);

    const medicationViewAudit = await prisma.auditEvent.findFirstOrThrow({
      where: {
        kind: 'MEDICATION_RECORD_VIEWED',
        residentId: seededResidents[2].id,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    expect(await prisma.auditEvent.count({
      where: {
        kind: 'MEDICATION_RECORD_VIEWED',
      },
    })).toBeGreaterThan(medicationViewAuditCountBefore);
    expect(medicationViewAudit.details).toMatchObject({
      residentId: seededResidents[2].id,
      residentName: seededResidents[2].fullName,
      viewerRole: 'NURSE',
      chartStatus: 'ACTIVE',
      accessScope: 'active-shift-floor-scope',
    });
  });

  it('records administered medication, creates resident timeline entries, and exposes medication audit history', async () => {
    const nurseToken = await login('nurse@sercesync.local');
    const managerToken = await login('manager@sercesync.local');
    const order = await seedMedicationOrder({
      residentId: seededResidents[3].id,
      medicationName: 'Levothyroxine',
    });
    await seedMedicationSchedule({
      medicationOrderId: order.id,
      roundLabel: 'MORNING',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 0,
      windowEndOffsetMinutes: 60,
    });

    await request(app.getHttpServer())
      .post(`/shifts/${activeShift.id}/generate-medication-round`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .expect(201);
    await acknowledgeCurrentHandover(nurseToken);

    const generatedDoseInstance =
      await prisma.medicationDoseInstance.findFirstOrThrow({
        where: {
          medicationOrderId: order.id,
          shiftId: activeShift.id,
        },
      });

    const administerResponse = typedResponse<MedicationOutcomeResponse>(
      await request(app.getHttpServer())
        .post(
          `/medication-dose-instances/${generatedDoseInstance.id}/administer`,
        )
        .set('Authorization', `Bearer ${nurseToken}`)
        .send({
          doseGiven: '1',
          doseUnit: 'tablet',
          notes: 'Administered with water and observed swallowing.',
        })
        .expect(201),
    );

    expect(administerResponse.body.doseInstance.status).toBe('ADMINISTERED');
    expect(administerResponse.body.administrationEvent.eventType).toBe(
      'ADMINISTERED',
    );

    const residentTimelineEntry =
      await prisma.residentTimelineEntry.findFirstOrThrow({
        where: {
          residentId: seededResidents[3].id,
          type: 'MEDICATION_NOTE',
          title: {
            contains: 'Levothyroxine',
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });
    expect(residentTimelineEntry.details).toContain('Levothyroxine');
    expect(residentTimelineEntry.details).toContain('administered');

    const auditResponse = typedResponse<{
      workflowNote: string;
      auditEvents: Array<{
        kind: string;
        residentId: string | null;
        medicationOrderId: string | null;
        medicationName: string | null;
      }>;
    }>(
      await request(app.getHttpServer())
        .get('/manager/medication-audit')
        .set('Authorization', `Bearer ${managerToken}`)
        .expect(200),
    );

    expect(auditResponse.body.auditEvents).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          kind: 'MEDICATION_DOSE_ADMINISTERED',
          residentId: seededResidents[3].id,
          medicationOrderId: order.id,
          medicationName: 'Levothyroxine',
        }),
      ]),
    );
  });

  it('requires a reason for refused, omitted, delayed, and not-available medication outcomes', async () => {
    const nurseToken = await login('nurse@sercesync.local');
    await acknowledgeCurrentHandover(nurseToken);

    const cases = [
      {
        medicationName: 'Refused Case',
        endpoint: 'refuse',
      },
      {
        medicationName: 'Omitted Case',
        endpoint: 'omit',
      },
      {
        medicationName: 'Delayed Case',
        endpoint: 'delay',
      },
      {
        medicationName: 'Unavailable Case',
        endpoint: 'not-available',
      },
    ] as const;

    for (const entry of cases) {
      const order = await seedMedicationOrder({
        residentId: seededResidents[4].id,
        medicationName: entry.medicationName,
      });
      const schedule = await seedMedicationSchedule({
        medicationOrderId: order.id,
      });
      const dueDose = await prisma.medicationDoseInstance.create({
        data: {
          residentId: seededResidents[4].id,
          medicationOrderId: order.id,
          scheduleId: schedule.id,
          shiftId: activeShift.id,
          dueWindowStart: new Date(Date.now() - 10 * 60 * 1000),
          dueWindowEnd: new Date(Date.now() + 50 * 60 * 1000),
          status: 'DUE',
          generatedAt: new Date(),
          requiresWitness: false,
        },
      });

      await request(app.getHttpServer())
        .post(`/medication-dose-instances/${dueDose.id}/${entry.endpoint}`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .send({
          notes: 'Reason omitted on purpose for validation coverage.',
        })
        .expect(400);
    }
  });

  it('records PRN offered, administered, refused, and not-given events while keeping PRN medication off timed rounds', async () => {
    const managerToken = await login('manager@sercesync.local');
    const nurseToken = await login('nurse@sercesync.local');

    const createPrnOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[5].id}/medications`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          medicationName: 'Lorazepam',
          formulation: 'tablet',
          strength: '0.5mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          route: 'oral',
          instructions:
            'Offer for acute anxiety following the current PRN MAR.',
          startDate: startOfToday().toISOString(),
          isPRN: true,
          sourceType: 'MANUAL_ENTRY',
          changeReason: 'PRN support order for anxious episodes.',
        })
        .expect(201),
    );
    const prnOrderId = createPrnOrderResponse.body.medicationOrder.id;

    await request(app.getHttpServer())
      .post(`/medications/${prnOrderId}/prn-protocol`)
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        indication: 'Anxiety or visible agitation',
        whenToOffer: 'Offer when the resident is anxious or distressed.',
        doseInstructions: 'Give one tablet by mouth if required.',
        minimumIntervalMinutes: 240,
        maxDosePer24Hours: 3,
        expectedEffect: 'Resident should become calmer within 30 minutes.',
        monitoringRequired: 'Observe level of calmness and drowsiness.',
        whenToEscalate: 'Escalate if agitation continues or worsens.',
      })
      .expect(201);

    await acknowledgeCurrentHandover(nurseToken);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[5].id}/prn-events`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .send({
        medicationOrderId: prnOrderId,
        eventType: 'PRN_OFFERED',
        reason: 'Resident appeared anxious before lunch.',
      })
      .expect(201);

    const prnAdministeredResponse = typedResponse<{
      warning: string | null;
      administrationEvent: {
        eventType: string;
      };
    }>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[5].id}/prn-events`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .send({
          medicationOrderId: prnOrderId,
          eventType: 'PRN_ADMINISTERED',
          doseGiven: '1',
          doseUnit: 'tablet',
          reason: 'Resident remained anxious after reassurance.',
        })
        .expect(201),
    );
    expect(prnAdministeredResponse.body.administrationEvent.eventType).toBe(
      'PRN_ADMINISTERED',
    );
    expect(prnAdministeredResponse.body.warning).toContain(
      'Check prescribed PRN instructions before administration.',
    );

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[5].id}/prn-events`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .send({
        medicationOrderId: prnOrderId,
        eventType: 'PRN_REFUSED',
        reason: 'Resident declined after explanation.',
      })
      .expect(201);

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[5].id}/prn-events`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .send({
        medicationOrderId: prnOrderId,
        eventType: 'PRN_NOT_GIVEN',
        reason: 'Symptoms settled before the dose was needed.',
      })
      .expect(201);

    const recordedPrnEvents =
      await prisma.medicationAdministrationEvent.findMany({
        where: {
          residentId: seededResidents[5].id,
          medicationOrderId: prnOrderId,
        },
        orderBy: {
          recordedAt: 'asc',
        },
      });
    expect(recordedPrnEvents.map((event) => event.eventType)).toEqual([
      'PRN_OFFERED',
      'PRN_ADMINISTERED',
      'PRN_REFUSED',
      'PRN_NOT_GIVEN',
    ]);

    const emarResponse = typedResponse<ResidentEmarResponse>(
      await request(app.getHttpServer())
        .get(`/residents/${seededResidents[5].id}/emar`)
        .set('Authorization', `Bearer ${nurseToken}`)
        .expect(200),
    );
    expect(emarResponse.body.prnMedications).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          id: prnOrderId,
          schedules: [],
          prnProtocol: expect.objectContaining({
            minimumIntervalMinutes: 240,
          }),
        }),
      ]),
    );

    const prnDoseInstances = await prisma.medicationDoseInstance.count({
      where: {
        medicationOrderId: prnOrderId,
      },
    });
    expect(prnDoseInstances).toBe(0);
  });

  it('marks overdue medication and surfaces it in manager medication exceptions, overdue views, dashboards, and audit logs', async () => {
    const managerToken = await login('manager@sercesync.local');
    const order = await seedMedicationOrder({
      residentId: seededResidents[6].id,
      medicationName: 'Bisoprolol',
    });
    const schedule = await seedMedicationSchedule({
      medicationOrderId: order.id,
      roundLabel: 'MIDDAY',
      anchorType: 'SHIFT_START',
      windowStartOffsetMinutes: 30,
      windowEndOffsetMinutes: 60,
    });

    const doseInstance = await prisma.medicationDoseInstance.create({
      data: {
        residentId: seededResidents[6].id,
        medicationOrderId: order.id,
        scheduleId: schedule.id,
        shiftId: activeShift.id,
        dueWindowStart: new Date(Date.now() - 2 * 60 * 60 * 1000),
        dueWindowEnd: new Date(Date.now() - 60 * 60 * 1000),
        status: 'DUE',
        generatedAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
        requiresWitness: false,
      },
    });

    const exceptionsResponse =
      typedResponse<ManagerMedicationExceptionsResponse>(
        await request(app.getHttpServer())
          .get('/manager/medication-exceptions')
          .set('Authorization', `Bearer ${managerToken}`)
          .expect(200),
      );

    expect(exceptionsResponse.body.exceptions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          doseInstanceId: doseInstance.id,
          residentId: seededResidents[6].id,
          residentName: seededResidents[6].fullName,
          medicationName: 'Bisoprolol',
          status: 'OVERDUE',
          residentEmarPath: `/residents/${seededResidents[6].id}/emar`,
        }),
      ]),
    );

    const overdueResponse = typedResponse<ManagerOverdueMedicationResponse>(
      await request(app.getHttpServer())
        .get('/manager/overdue-medication')
        .set('Authorization', `Bearer ${managerToken}`)
        .expect(200),
    );
    expect(overdueResponse.body.overdueMedication).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          doseInstanceId: doseInstance.id,
          residentName: seededResidents[6].fullName,
          medicationName: 'Bisoprolol',
          status: 'OVERDUE',
        }),
      ]),
    );

    const dashboardResponse = typedResponse<
      ManagerDashboardResponse & {
        medicationOverview: {
          totals: {
            overdue: number;
          };
          exceptions: Array<{
            doseInstanceId: string;
            status: string;
          }>;
        };
      }
    >(
      await request(app.getHttpServer())
        .get('/manager/dashboard')
        .query({ shiftId: activeShift.id })
        .set('Authorization', `Bearer ${managerToken}`)
        .expect(200),
    );
    expect(dashboardResponse.body.medicationOverview.totals.overdue).toBe(1);
    expect(dashboardResponse.body.medicationOverview.exceptions).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          doseInstanceId: doseInstance.id,
          status: 'OVERDUE',
        }),
      ]),
    );

    const viewAuditEvent = await prisma.auditEvent.findFirst({
      where: {
        kind: 'MEDICATION_EXCEPTION_VIEWED',
        userId: (
          await prisma.user.findUniqueOrThrow({
            where: {
              email: 'manager@sercesync.local',
            },
          })
        ).id,
      },
      orderBy: {
        createdAt: 'desc',
      },
    });
    expect(viewAuditEvent).not.toBeNull();
  });

  it('enforces role-based access for medication order management and medication administration recording', async () => {
    const managerToken = await login('manager@sercesync.local');
    const nurseToken = await login('nurse@sercesync.local');
    const carerToken = await login('carer@sercesync.local');

    await request(app.getHttpServer())
      .post(`/residents/${seededResidents[7].id}/medications`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .send({
        medicationName: 'Ibuprofen',
        formulation: 'tablet',
        strength: '200mg tablet',
        doseAmount: '1',
        doseUnit: 'tablet',
        route: 'oral',
        instructions: 'Manager-only order creation should block this request.',
        startDate: startOfToday().toISOString(),
      })
      .expect(403);

    const createdOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${seededResidents[7].id}/medications`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          medicationName: 'Ibuprofen',
          formulation: 'tablet',
          strength: '200mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          route: 'oral',
          instructions: 'Give with food following the current MAR.',
          startDate: startOfToday().toISOString(),
          changeReason: 'Created for access-control coverage.',
        })
        .expect(201),
    );

    await request(app.getHttpServer())
      .patch(`/medications/${createdOrderResponse.body.medicationOrder.id}`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .send({
        instructions: 'Attempted nurse edit should fail.',
        reason: 'Permission test.',
      })
      .expect(403);

    const schedule = await seedMedicationSchedule({
      medicationOrderId: createdOrderResponse.body.medicationOrder.id,
    });
    const dueDose = await prisma.medicationDoseInstance.create({
      data: {
        residentId: seededResidents[7].id,
        medicationOrderId: createdOrderResponse.body.medicationOrder.id,
        scheduleId: schedule.id,
        shiftId: activeShift.id,
        dueWindowStart: new Date(Date.now() - 10 * 60 * 1000),
        dueWindowEnd: new Date(Date.now() + 50 * 60 * 1000),
        status: 'DUE',
        generatedAt: new Date(),
        requiresWitness: false,
      },
    });

    await acknowledgeCurrentHandover(nurseToken);

    await request(app.getHttpServer())
      .post(`/medication-dose-instances/${dueDose.id}/administer`)
      .set('Authorization', `Bearer ${carerToken}`)
      .send({
        doseGiven: '1',
        doseUnit: 'tablet',
      })
      .expect(403);
  });

  it('preserves resident floor filtering for nurse medication views and round access', async () => {
    const managerToken = await login('manager@sercesync.local');
    const nurseToken = await login('nurse@sercesync.local');

    const createOrderResponse = typedResponse<MedicationOrderWriteResponse>(
      await request(app.getHttpServer())
        .post(`/residents/${outOfScopeResident.id}/medications`)
        .set('Authorization', `Bearer ${managerToken}`)
        .send({
          medicationName: 'Warfarin',
          formulation: 'tablet',
          strength: '1mg tablet',
          doseAmount: '1',
          doseUnit: 'tablet',
          route: 'oral',
          instructions: 'Maple floor order used to verify floor filtering.',
          startDate: startOfToday().toISOString(),
          changeReason: 'Cross-floor filtering coverage.',
        })
        .expect(201),
    );

    await request(app.getHttpServer())
      .post(
        `/medications/${createOrderResponse.body.medicationOrder.id}/schedules`,
      )
      .set('Authorization', `Bearer ${managerToken}`)
      .send({
        roundLabel: 'MORNING',
        anchorType: 'SHIFT_START',
        windowStartOffsetMinutes: 0,
        windowEndOffsetMinutes: 60,
      })
      .expect(201);

    await request(app.getHttpServer())
      .get(`/residents/${outOfScopeResident.id}/emar`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .expect(404);

    await request(app.getHttpServer())
      .get(`/shifts/${mapleActiveShift.id}/medication-round`)
      .set('Authorization', `Bearer ${nurseToken}`)
      .expect(404);
  });

  it('rejects protected task access without a bearer token', () => {
    return request(app.getHttpServer()).get('/tasks/current').expect(401);
  });
});
