import {
  Prisma,
  MedicationAdministrationEventType,
  MedicationDoseStatus,
  MedicationOrderSourceType,
  MedicationScheduleAnchorType,
  MedicationStockTransactionType,
  type ShiftStatus,
} from '@prisma/client';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { ManagerDashboardStreamService } from '../manager-dashboard-stream/manager-dashboard-stream.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePrnEventDto } from './dto/create-prn-event.dto';
import { DeactivateMedicationOrderDto } from './dto/deactivate-medication-order.dto';
import { CreateMedicationStockTransactionDto } from './dto/create-medication-stock-transaction.dto';
import { RecordDoseOutcomeDto } from './dto/record-dose-outcome.dto';
import { MedicationsService } from './medications.service';

type DeepPartial<T> = {
  [K in keyof T]?: T[K] extends Array<infer U>
    ? Array<DeepPartial<U>>
    : T[K] extends ReadonlyArray<infer U>
      ? ReadonlyArray<DeepPartial<U>>
      : T[K] extends Date
        ? T[K]
        : T[K] extends object
          ? DeepPartial<T[K]>
          : T[K];
};

type ResidentFixture = {
  id: string;
  fullName: string;
  roomLabel: string;
  roomNumber: string;
  floorNumber: number;
  unitLabel: string;
  isActive: boolean;
};

type ShiftFixture = {
  id: string;
  name: string;
  status: ShiftStatus;
  startsAt: Date;
  endsAt: Date;
  floorNumber: number;
  unitLabel: string;
  handover: {
    acknowledgements: Array<{
      acknowledgedAt: Date;
      acknowledgedById: string;
    }>;
  } | null;
};

type MedicationOrderFixture = {
  id: string;
  residentId: string;
  chartId: string;
  medicationName: string;
  formulation: string | null;
  strength: string | null;
  doseAmount: string;
  doseUnit: string;
  route: string;
  instructions: string;
  startDate: Date;
  endDate: Date | null;
  isActive: boolean;
  isControlledDrug: boolean;
  requiresWitness: boolean;
  isPRN: boolean;
  sourceType: MedicationOrderSourceType;
  createdByUserId: string;
  updatedByUserId: string;
  createdAt: Date;
  updatedAt: Date;
  deactivatedAt: Date | null;
  deactivationReason: string | null;
  schedules: Array<{
    id: string;
    roundLabel: string;
    anchorType: MedicationScheduleAnchorType;
    windowStartOffsetMinutes: number | null;
    windowEndOffsetMinutes: number | null;
    fixedTimeLocal: string | null;
    daysOfWeek: string[];
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
  }>;
  prnProtocol: {
    id: string;
    indication: string;
    whenToOffer: string;
    doseInstructions: string;
    minimumIntervalMinutes: number | null;
    maxDosePer24Hours: number | null;
    expectedEffect: string | null;
    monitoringRequired: string | null;
    whenToEscalate: string | null;
    active: boolean;
    createdAt: Date;
    updatedAt: Date;
  } | null;
  stockRecord: {
    id: string;
    currentQuantity: string;
    quantityUnit: string;
    lastCheckedByUserId: string | null;
    lastCheckedAt: Date | null;
    notes: string | null;
    updatedAt: Date;
  } | null;
};

type MedicationDoseInstanceFixture = {
  id: string;
  residentId: string;
  shiftId: string;
  medicationOrderId: string;
  scheduleId: string;
  dueWindowStart: Date;
  dueWindowEnd: Date;
  status: MedicationDoseStatus;
  generatedAt: Date;
  recordedByUserId: string | null;
  recordedAt: Date | null;
  reason: string | null;
  notes: string | null;
  requiresWitness: boolean;
  witnessUserId: string | null;
  medicationOrder: {
    id: string;
    medicationName: string;
    formulation: string | null;
    strength: string | null;
    doseAmount: string;
    doseUnit: string;
    route: string;
    instructions: string;
    requiresWitness: boolean;
    isActive?: boolean;
    resident: {
      id: string;
      fullName: string;
      roomLabel: string;
      floorNumber: number;
      unitLabel: string;
    };
  };
  schedule: {
    id: string;
    roundLabel: string;
    anchorType: MedicationScheduleAnchorType;
  };
  shift?: ShiftFixture;
};

type MedicationAdministrationEventFixture = {
  id: string;
  doseInstanceId: string | null;
  residentId: string;
  shiftId: string;
  medicationOrderId: string;
  eventType: MedicationAdministrationEventType;
  doseGiven: string | null;
  doseUnit: string | null;
  reason: string | null;
  notes: string | null;
  recordedByUserId: string;
  recordedAt: Date;
  witnessUserId: string | null;
  createdAt: Date;
  medicationOrder: {
    medicationName: string;
    strength: string | null;
    formulation: string | null;
  };
  resident: {
    fullName: string;
    roomLabel: string;
  };
};

type MedicationStockRecordFixture = {
  id: string;
  medicationOrderId: string;
  residentId: string;
  currentQuantity: string;
  quantityUnit: string;
  lastCheckedByUserId: string | null;
  lastCheckedAt: Date | null;
  notes: string | null;
  updatedAt: Date;
};

type MedicationStockRecordUpsertFixture = Pick<
  MedicationStockRecordFixture,
  | 'id'
  | 'currentQuantity'
  | 'quantityUnit'
  | 'lastCheckedByUserId'
  | 'lastCheckedAt'
  | 'notes'
  | 'updatedAt'
>;

type MedicationStockTransactionFixture = {
  id: string;
  stockRecordId: string;
  residentId: string;
  medicationOrderId: string;
  transactionType: MedicationStockTransactionType;
  quantity: string;
  quantityUnit: string;
  recordedByUserId: string;
  witnessUserId: string | null;
  reason: string | null;
  createdAt: Date;
};

type UserFixture = {
  id: string;
  displayName: string;
  role: {
    key: 'NURSE' | 'MANAGER' | 'CARER';
  };
};

type MedicationDueWindow = {
  anchorAt: Date;
  dueWindowStart: Date;
  dueWindowEnd: Date;
};

type MedicationsServiceInternals = {
  resolveDueWindow(args: {
    anchorType: MedicationScheduleAnchorType;
    shiftStartsAt: Date;
    shiftEndsAt: Date;
    handoverAcknowledgedAt: Date | null;
    fixedTimeLocal: string | null;
    windowStartOffsetMinutes: number | null;
    windowEndOffsetMinutes: number | null;
  }): MedicationDueWindow | null;
};

type PrismaTransactionHandler = <T>(
  callback: (tx: Prisma.TransactionClient) => Promise<T>,
) => Promise<T>;

type PrismaMock = {
  medicationOrder: {
    findFirst: jest.Mock<Promise<MedicationOrderFixture | null>, never[]>;
    findUnique: jest.Mock<Promise<MedicationOrderFixture | null>, never[]>;
    findMany: jest.Mock<Promise<MedicationOrderFixture[]>, never[]>;
    update: jest.Mock<Promise<MedicationOrderFixture>, never[]>;
  };
  medicationSchedule: {
    findUnique: jest.Mock<Promise<MedicationOrderFixture['schedules'][number] | null>, never[]>;
    update: jest.Mock<Promise<MedicationOrderFixture['schedules'][number]>, never[]>;
  };
  medicationDoseInstance: {
    findUnique: jest.Mock<Promise<MedicationDoseInstanceFixture | null>, never[]>;
    findMany: jest.Mock<Promise<MedicationDoseInstanceFixture[]>, never[]>;
    update: jest.Mock<Promise<MedicationDoseInstanceFixture>, never[]>;
    updateMany: jest.Mock<Promise<{ count: number }>, never[]>;
    create: jest.Mock<Promise<MedicationDoseInstanceFixture>, never[]>;
  };
  medicationAdministrationEvent: {
    findFirst: jest.Mock<Promise<MedicationAdministrationEventFixture | null>, never[]>;
    findMany: jest.Mock<Promise<MedicationAdministrationEventFixture[]>, never[]>;
    count: jest.Mock<Promise<number>, never[]>;
    create: jest.Mock<Promise<MedicationAdministrationEventFixture>, never[]>;
  };
  medicationStockRecord: {
    findUnique: jest.Mock<Promise<MedicationStockRecordFixture | null>, never[]>;
    upsert: jest.Mock<Promise<MedicationStockRecordUpsertFixture>, never[]>;
  };
  medicationStockTransaction: {
    create: jest.Mock<Promise<MedicationStockTransactionFixture>, never[]>;
  };
  resident: {
    findUnique: jest.Mock<Promise<ResidentFixture | null>, never[]>;
  };
  shift: {
    findFirst: jest.Mock<Promise<ShiftFixture | null>, never[]>;
    findUnique: jest.Mock<Promise<ShiftFixture | null>, never[]>;
    findMany: jest.Mock<Promise<ShiftFixture[]>, never[]>;
  };
  user: {
    findUnique: jest.Mock<Promise<UserFixture | null>, never[]>;
    findMany: jest.Mock<Promise<UserFixture[]>, never[]>;
  };
  auditEvent: {
    create: jest.Mock<Promise<{ id: string }>, never[]>;
  };
  residentTimelineEntry: {
    create: jest.Mock<Promise<{ id: string }>, never[]>;
  };
  medicationChangeLog: {
    create: jest.Mock<Promise<{ id: string }>, never[]>;
  };
  $transaction: jest.MockedFunction<PrismaTransactionHandler>;
};

function createPrismaMock(): PrismaMock {
  const prisma = {
    medicationOrder: {
      findFirst: jest.fn() as PrismaMock['medicationOrder']['findFirst'],
      findUnique: jest.fn() as PrismaMock['medicationOrder']['findUnique'],
      findMany: jest.fn() as PrismaMock['medicationOrder']['findMany'],
      update: jest.fn() as PrismaMock['medicationOrder']['update'],
    },
    medicationSchedule: {
      findUnique: jest.fn() as PrismaMock['medicationSchedule']['findUnique'],
      update: jest.fn() as PrismaMock['medicationSchedule']['update'],
    },
    medicationDoseInstance: {
      findUnique: jest.fn() as PrismaMock['medicationDoseInstance']['findUnique'],
      findMany: jest.fn() as PrismaMock['medicationDoseInstance']['findMany'],
      update: jest.fn() as PrismaMock['medicationDoseInstance']['update'],
      updateMany: jest.fn() as PrismaMock['medicationDoseInstance']['updateMany'],
      create: jest.fn() as PrismaMock['medicationDoseInstance']['create'],
    },
    medicationAdministrationEvent: {
      findFirst: jest.fn() as PrismaMock['medicationAdministrationEvent']['findFirst'],
      findMany: jest.fn() as PrismaMock['medicationAdministrationEvent']['findMany'],
      count: jest.fn() as PrismaMock['medicationAdministrationEvent']['count'],
      create: jest.fn() as PrismaMock['medicationAdministrationEvent']['create'],
    },
    medicationStockRecord: {
      findUnique: jest.fn() as PrismaMock['medicationStockRecord']['findUnique'],
      upsert: jest.fn() as PrismaMock['medicationStockRecord']['upsert'],
    },
    medicationStockTransaction: {
      create: jest.fn() as PrismaMock['medicationStockTransaction']['create'],
    },
    resident: {
      findUnique: jest.fn() as PrismaMock['resident']['findUnique'],
    },
    shift: {
      findFirst: jest.fn() as PrismaMock['shift']['findFirst'],
      findUnique: jest.fn() as PrismaMock['shift']['findUnique'],
      findMany: jest.fn() as PrismaMock['shift']['findMany'],
    },
    user: {
      findUnique: jest.fn() as PrismaMock['user']['findUnique'],
      findMany: jest.fn() as PrismaMock['user']['findMany'],
    },
    auditEvent: {
      create: jest.fn() as PrismaMock['auditEvent']['create'],
    },
    residentTimelineEntry: {
      create: jest.fn() as PrismaMock['residentTimelineEntry']['create'],
    },
    medicationChangeLog: {
      create: jest.fn() as PrismaMock['medicationChangeLog']['create'],
    },
    $transaction: jest.fn() as PrismaMock['$transaction'],
  } satisfies PrismaMock;

  prisma.$transaction.mockImplementation(async (callback) =>
    callback(prisma as never),
  );

  return prisma;
}

function createStreamMock() {
  return {
    publishShiftUpdate: jest.fn(),
  };
}

function createService() {
  const prisma = createPrismaMock();
  const stream = createStreamMock();
  const service = new MedicationsService(
    prisma as never as PrismaService,
    stream as never as ManagerDashboardStreamService,
  );

  prisma.user.findMany.mockResolvedValue([]);
  prisma.medicationAdministrationEvent.count.mockResolvedValue(0);

  return { service, prisma, stream };
}

const nurseUser: AuthenticatedUser = {
  userId: 'nurse-1',
  email: 'nurse@example.com',
  role: 'NURSE',
  displayName: 'Nurse Joy',
};

const managerUser: AuthenticatedUser = {
  userId: 'manager-1',
  email: 'manager@example.com',
  role: 'MANAGER',
  displayName: 'Manager Oak',
};

function buildResident(overrides: DeepPartial<ResidentFixture> = {}): ResidentFixture {
  return {
    id: 'resident-1',
    fullName: 'Margaret Evans',
    roomLabel: '12A',
    roomNumber: '12',
    floorNumber: 2,
    unitLabel: 'Maple',
    isActive: true,
    ...overrides,
  } as ResidentFixture;
}

function buildShift(overrides: DeepPartial<ShiftFixture> = {}): ShiftFixture {
  return {
    id: 'shift-1',
    name: 'Night Shift',
    status: 'ACTIVE' as ShiftStatus,
    startsAt: new Date(2026, 3, 20, 20, 0, 0, 0),
    endsAt: new Date(2026, 3, 21, 8, 0, 0, 0),
    floorNumber: 2,
    unitLabel: 'Maple',
    handover: {
      acknowledgements: [
        {
          acknowledgedAt: new Date(2026, 3, 20, 20, 15, 0, 0),
          acknowledgedById: nurseUser.userId,
        },
      ],
    },
    ...overrides,
  } as ShiftFixture;
}

function buildMedicationOrder(
  overrides: DeepPartial<MedicationOrderFixture> = {},
): MedicationOrderFixture {
  return {
    id: 'order-1',
    residentId: 'resident-1',
    chartId: 'chart-1',
    medicationName: 'Lorazepam',
    formulation: 'Tablet',
    strength: '1mg',
    doseAmount: '1',
    doseUnit: 'tablet',
    route: 'Oral',
    instructions: 'Use as directed',
    startDate: new Date(2026, 3, 1, 9, 0, 0, 0),
    endDate: null,
    isActive: true,
    isControlledDrug: false,
    requiresWitness: false,
    isPRN: false,
    sourceType: MedicationOrderSourceType.MANUAL_ENTRY,
    createdByUserId: managerUser.userId,
    updatedByUserId: managerUser.userId,
    createdAt: new Date(2026, 3, 1, 9, 0, 0, 0),
    updatedAt: new Date(2026, 3, 1, 9, 0, 0, 0),
    deactivatedAt: null,
    deactivationReason: null,
    schedules: [],
    prnProtocol: null,
    stockRecord: null,
    ...overrides,
  } as MedicationOrderFixture;
}

function buildPrnOrder(
  overrides: DeepPartial<MedicationOrderFixture> = {},
): MedicationOrderFixture {
  return {
    id: 'order-1',
    residentId: 'resident-1',
    chartId: 'chart-1',
    medicationName: 'Lorazepam',
    strength: '1mg',
    doseUnit: 'tablet',
    isPRN: true,
    isActive: true,
    requiresWitness: false,
    prnProtocol: {
      id: 'prn-1',
      indication: 'Anxiety',
      whenToOffer: 'When distressed',
      doseInstructions: 'Offer one tablet',
      minimumIntervalMinutes: null,
      maxDosePer24Hours: null,
      expectedEffect: null,
      monitoringRequired: null,
      whenToEscalate: null,
      active: true,
      createdAt: new Date(2026, 3, 1, 9, 0, 0, 0),
      updatedAt: new Date(2026, 3, 1, 9, 0, 0, 0),
    },
    ...overrides,
  } as MedicationOrderFixture;
}

function buildDoseInstance(
  overrides: DeepPartial<MedicationDoseInstanceFixture> = {},
): MedicationDoseInstanceFixture {
  return {
    id: 'dose-1',
    residentId: 'resident-1',
    shiftId: 'shift-1',
    medicationOrderId: 'order-1',
    scheduleId: 'schedule-1',
    dueWindowStart: new Date(2026, 3, 20, 21, 0, 0, 0),
    dueWindowEnd: new Date(2026, 3, 20, 22, 0, 0, 0),
    status: MedicationDoseStatus.DUE,
    generatedAt: new Date(2026, 3, 20, 20, 0, 0, 0),
    recordedByUserId: null,
    recordedAt: null,
    reason: null,
    notes: null,
    requiresWitness: false,
    witnessUserId: null,
    medicationOrder: {
      id: 'order-1',
      medicationName: 'Metformin',
      formulation: 'Tablet',
      strength: '500mg',
      doseAmount: '1',
      doseUnit: 'tablet',
      route: 'Oral',
      instructions: 'With food',
      requiresWitness: false,
      resident: {
        id: 'resident-1',
        fullName: 'Margaret Evans',
        roomLabel: '12A',
        floorNumber: 2,
        unitLabel: 'Maple',
      },
    },
    schedule: {
      id: 'schedule-1',
      roundLabel: 'Evening round',
      anchorType: MedicationScheduleAnchorType.SHIFT_START,
    },
    ...overrides,
  } as MedicationDoseInstanceFixture;
}

function buildAdministrationEvent(
  overrides: DeepPartial<MedicationAdministrationEventFixture> = {},
): MedicationAdministrationEventFixture {
  return {
    id: 'event-1',
    doseInstanceId: 'dose-1',
    residentId: 'resident-1',
    shiftId: 'shift-1',
    medicationOrderId: 'order-1',
    eventType: MedicationAdministrationEventType.HELD,
    doseGiven: null,
    doseUnit: 'tablet',
    reason: 'Clinical hold',
    notes: 'Systolic pressure low',
    recordedByUserId: nurseUser.userId,
    recordedAt: new Date(2026, 3, 20, 21, 30, 0, 0),
    witnessUserId: null,
    createdAt: new Date(2026, 3, 20, 21, 30, 0, 0),
    medicationOrder: {
      medicationName: 'Metformin',
      strength: '500mg',
      formulation: 'Tablet',
    },
    resident: {
      fullName: 'Margaret Evans',
      roomLabel: '12A',
    },
    ...overrides,
  } as MedicationAdministrationEventFixture;
}

describe('MedicationsService medication-focused coverage', () => {
  describe('PRN witness enforcement', () => {
    it('rejects witness-required PRN administration without a second authorised witness', async () => {
      const { service, prisma } = createService();
      prisma.resident.findUnique.mockResolvedValue(buildResident());
      prisma.shift.findFirst.mockResolvedValue(buildShift());
      prisma.medicationOrder.findFirst.mockResolvedValue(
        buildPrnOrder({ requiresWitness: true }),
      );

      const prnRequest: CreatePrnEventDto = {
        medicationOrderId: 'order-1',
        eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
        reason: 'Escalating anxiety symptoms',
      };

      await expect(
        service.recordPrnEvent('resident-1', nurseUser, prnRequest),
      ).rejects.toThrow(
        'Witness confirmation is required for this PRN medication before submission.',
      );

      expect(
        prisma.medicationAdministrationEvent.create,
      ).not.toHaveBeenCalled();
    });
  });

  describe('Held flow', () => {
    it('records HELD as a final dose outcome and publishes a manager update', async () => {
      const { service, prisma, stream } = createService();
      const initialDose = buildDoseInstance();
      const updatedDose = buildDoseInstance({
        status: MedicationDoseStatus.HELD,
        recordedByUserId: nurseUser.userId,
        recordedAt: new Date(2026, 3, 20, 21, 30, 0, 0),
        reason: 'Clinical hold',
        notes: 'Systolic pressure low',
      });
      const event = buildAdministrationEvent();

      prisma.medicationDoseInstance.findUnique.mockResolvedValue(initialDose);
      prisma.shift.findFirst.mockResolvedValue(buildShift());
      prisma.medicationDoseInstance.update.mockResolvedValue(updatedDose);
      prisma.medicationAdministrationEvent.create.mockResolvedValue(event);

      const holdRequest: RecordDoseOutcomeDto = {
        reason: 'Clinical hold',
        notes: 'Systolic pressure low',
      };

      const result = await service.holdDose('dose-1', nurseUser, {
        ...holdRequest,
      });

      expect(prisma.medicationDoseInstance.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'dose-1' },
          data: expect.objectContaining({
            status: MedicationDoseStatus.HELD,
            reason: 'Clinical hold',
            notes: 'Systolic pressure low',
            recordedByUserId: nurseUser.userId,
          }),
        }),
      );
      expect(prisma.medicationAdministrationEvent.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            doseInstanceId: 'dose-1',
            eventType: MedicationAdministrationEventType.HELD,
            reason: 'Clinical hold',
            notes: 'Systolic pressure low',
          }),
        }),
      );
      expect(stream.publishShiftUpdate).toHaveBeenCalledWith(
        initialDose.shiftId,
        'medication-updated',
      );
      expect(result.administrationEvent.eventType).toBe(
        MedicationAdministrationEventType.HELD,
      );
      expect(result.doseInstance.status).toBe(MedicationDoseStatus.HELD);
    });
  });

  describe('Red coverage for open medication gaps', () => {
    it(
      'deactivating an order should cancel unrecorded DUE and OVERDUE dose instances instead of leaving stale rounds actionable',
      async () => {
        const { service, prisma } = createService();
        const existingOrder = buildMedicationOrder();
        const deactivatedOrder = buildMedicationOrder({
          isActive: false,
          deactivatedAt: new Date(2026, 3, 20, 12, 0, 0, 0),
          deactivationReason: 'Course completed',
          updatedByUserId: managerUser.userId,
          updatedAt: new Date(2026, 3, 20, 12, 0, 0, 0),
        });

        prisma.medicationOrder.findUnique.mockResolvedValue(existingOrder);
        prisma.medicationOrder.update.mockResolvedValue(deactivatedOrder);
        prisma.medicationDoseInstance.findMany.mockResolvedValue([
          buildDoseInstance({
            status: MedicationDoseStatus.DUE,
            medicationOrder: {
              ...buildDoseInstance().medicationOrder,
              isActive: false,
            },
            shift: buildShift(),
          }),
        ]);

        const deactivateRequest: DeactivateMedicationOrderDto = {
          reason: 'Course completed',
        };

        await service.deactivateMedicationOrder(
          'order-1',
          managerUser,
          deactivateRequest,
        );

        expect(prisma.medicationDoseInstance.update).toHaveBeenCalledWith(
          expect.objectContaining({
            where: {
              id: 'dose-1',
            },
            data: expect.objectContaining({
              status: MedicationDoseStatus.CANCELLED,
              reason: expect.stringContaining('Course completed'),
              notes: expect.stringContaining('invalidated'),
            }),
          }),
        );
      },
    );

    it(
      'recordPrnEvent should stop a PRN administration that exceeds the configured maxDosePer24Hours limit',
      async () => {
        const { service, prisma } = createService();
        prisma.resident.findUnique.mockResolvedValue(buildResident());
        prisma.shift.findFirst.mockResolvedValue(buildShift());
        prisma.medicationOrder.findFirst.mockResolvedValue(
          buildPrnOrder({
            prnProtocol: {
              id: 'prn-1',
              indication: 'Anxiety',
              whenToOffer: 'When distressed',
              doseInstructions: 'Offer one tablet',
              minimumIntervalMinutes: null,
              maxDosePer24Hours: 1,
              expectedEffect: 'Calmer within 30 minutes',
              monitoringRequired: 'Observe sedation',
              whenToEscalate: 'Escalate if ineffective',
              active: true,
              createdAt: new Date(2026, 3, 1, 9, 0, 0, 0),
              updatedAt: new Date(2026, 3, 1, 9, 0, 0, 0),
            },
          }),
        );
        prisma.medicationAdministrationEvent.count.mockResolvedValue(1);
        prisma.medicationAdministrationEvent.create.mockResolvedValue(
          buildAdministrationEvent({
            doseInstanceId: null,
            eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
            reason: 'Escalating anxiety symptoms',
            notes: null,
          }),
        );

        const prnLimitRequest: CreatePrnEventDto = {
          medicationOrderId: 'order-1',
          eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
          reason: 'Escalating anxiety symptoms',
          doseGiven: '1',
          doseUnit: 'tablet',
        };

        await expect(
          service.recordPrnEvent('resident-1', nurseUser, prnLimitRequest),
        ).rejects.toThrow(/24[-\s]*hour|max/i);
      },
    );

    it(
      'overnight FIXED_TIME schedules should anchor to the next in-shift occurrence rather than the shift start calendar date',
      async () => {
        const { service } = createService();
        const dueWindow = (
          Object.getPrototypeOf(service) as {
            resolveDueWindow: MedicationsServiceInternals['resolveDueWindow'];
          }
        ).resolveDueWindow.call(service, {
          anchorType: MedicationScheduleAnchorType.FIXED_TIME,
          shiftStartsAt: new Date(2026, 3, 20, 20, 0, 0, 0),
          shiftEndsAt: new Date(2026, 3, 21, 8, 0, 0, 0),
          handoverAcknowledgedAt: null,
          fixedTimeLocal: '06:00',
          windowStartOffsetMinutes: 0,
          windowEndOffsetMinutes: 60,
        });

        expect(dueWindow).not.toBeNull();
        const resolvedDueWindow = dueWindow;
        if (!resolvedDueWindow) {
          throw new Error('Expected a due window to resolve');
        }

        expect(resolvedDueWindow.dueWindowStart).toEqual(
          new Date(2026, 3, 21, 6, 0, 0, 0),
        );
        expect(resolvedDueWindow.dueWindowEnd).toEqual(
          new Date(2026, 3, 21, 7, 0, 0, 0),
        );
      },
    );

    it(
      'stock transactions should apply quantity deltas to the running balance instead of overwriting currentQuantity with the submitted amount',
      async () => {
        const { service, prisma } = createService();
        prisma.resident.findUnique.mockResolvedValue(buildResident());
        prisma.medicationOrder.findUnique.mockResolvedValue(
          buildMedicationOrder({ requiresWitness: false }),
        );
        prisma.medicationStockRecord.findUnique.mockResolvedValue({
          id: 'stock-1',
          medicationOrderId: 'order-1',
          residentId: 'resident-1',
          currentQuantity: '30',
          quantityUnit: 'tablets',
          lastCheckedByUserId: managerUser.userId,
          lastCheckedAt: new Date(2026, 3, 20, 9, 0, 0, 0),
          notes: null,
          updatedAt: new Date(2026, 3, 20, 9, 0, 0, 0),
        });
        prisma.medicationStockRecord.upsert.mockResolvedValue({
          id: 'stock-1',
          currentQuantity: '28',
          quantityUnit: 'tablets',
          lastCheckedByUserId: managerUser.userId,
          lastCheckedAt: new Date(2026, 3, 20, 10, 0, 0, 0),
          notes: 'Administration recorded',
          updatedAt: new Date(2026, 3, 20, 10, 0, 0, 0),
        } satisfies MedicationStockRecordUpsertFixture);
        prisma.medicationStockTransaction.create.mockResolvedValue({
          id: 'txn-1',
          stockRecordId: 'stock-1',
          residentId: 'resident-1',
          medicationOrderId: 'order-1',
          transactionType: MedicationStockTransactionType.ADMINISTERED,
          quantity: '2',
          quantityUnit: 'tablets',
          reason: 'Administration recorded',
          recordedByUserId: managerUser.userId,
          witnessUserId: null,
          createdAt: new Date(2026, 3, 20, 10, 0, 0, 0),
        });

        await service.createStockTransaction('order-1', managerUser, {
          transactionType: MedicationStockTransactionType.ADMINISTERED,
          quantity: '2',
          quantityUnit: 'tablets',
          reason: 'Administration recorded',
        } satisfies CreateMedicationStockTransactionDto);

        expect(prisma.medicationStockRecord.findUnique).toHaveBeenCalledWith(
          expect.objectContaining({
            where: {
              medicationOrderId: 'order-1',
            },
          }),
        );
        expect(prisma.medicationStockRecord.upsert).toHaveBeenCalledWith(
          expect.objectContaining({
            update: expect.objectContaining({
              currentQuantity: '28',
            }),
            create: expect.objectContaining({
              currentQuantity: '28',
            }),
          }),
        );
      },
    );
  });
});
