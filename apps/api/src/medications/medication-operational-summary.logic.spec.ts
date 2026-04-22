import {
  MedicationAdministrationEventType,
  MedicationDoseStatus,
} from '@prisma/client';
import {
  buildResidentOperationalSummary,
  deriveStockException,
} from './medication-operational-summary.logic';

describe('medication operational summary logic', () => {
  const resident = {
    id: 'resident-1',
    fullName: 'Ada Lovelace',
    roomLabel: '101',
    floorNumber: 1,
    unitLabel: 'Oak',
  };

  it('flags missing stock for active orders', () => {
    expect(
      deriveStockException(resident, {
        id: 'order-1',
        residentId: resident.id,
        medicationName: 'Paracetamol',
        isActive: true,
        isPRN: false,
        isControlledDrug: false,
        requiresWitness: false,
        stockRecord: null,
      }),
    ).toMatchObject({
      code: 'MISSING_STOCK_RECORD',
      medicationOrderId: 'order-1',
    });
  });

  it('builds a compatibility headline from overdue and due-soon doses', () => {
    const now = new Date('2026-04-19T09:00:00.000Z');
    const summary = buildResidentOperationalSummary(
      {
        resident,
        orders: [
          {
            id: 'order-1',
            residentId: resident.id,
            medicationName: 'Morphine',
            isActive: true,
            isPRN: false,
            isControlledDrug: true,
            requiresWitness: true,
            stockRecord: {
              currentQuantity: '12',
              quantityUnit: 'tablets',
              lastCheckedAt: new Date('2026-04-19T07:00:00.000Z'),
            },
          },
        ],
        doses: [
          {
            residentId: resident.id,
            dueWindowStart: new Date('2026-04-19T08:00:00.000Z'),
            dueWindowEnd: new Date('2026-04-19T08:30:00.000Z'),
            status: MedicationDoseStatus.OVERDUE,
          },
          {
            residentId: resident.id,
            dueWindowStart: new Date('2026-04-19T09:30:00.000Z'),
            dueWindowEnd: new Date('2026-04-19T10:00:00.000Z'),
            status: MedicationDoseStatus.DUE,
          },
        ],
        prnEvents: [
          {
            residentId: resident.id,
            eventType: MedicationAdministrationEventType.PRN_ADMINISTERED,
            recordedAt: new Date('2026-04-19T06:00:00.000Z'),
          },
        ],
        allergies: [{ residentId: resident.id, substance: 'Penicillin' }],
        lastAdministrationAt: new Date('2026-04-19T06:00:00.000Z'),
        generatedAt: now,
      },
      now,
    );

    expect(summary.taskSummaryCompatible.headline).toBe('1 medication overdue');
    expect(summary.openDoses.dueWithinHour).toBe(1);
    expect(summary.prn.administeredLast24Hours).toBe(1);
    expect(summary.activeOrders.controlledDrugs).toBe(1);
  });
});
