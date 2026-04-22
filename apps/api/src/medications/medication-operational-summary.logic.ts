import {
  MedicationAdministrationEventType,
  MedicationDoseStatus,
} from '@prisma/client';
import type {
  MedicationResidentIdentity,
  MedicationResidentOperationalSummary,
  MedicationShiftOperationalSummary,
  MedicationStockException,
  MedicationTaskCompatibleSummary,
} from './medication-operational-summary.types';

type OrderInput = {
  id: string;
  residentId: string;
  medicationName: string;
  isActive: boolean;
  isPRN: boolean;
  isControlledDrug: boolean;
  requiresWitness: boolean;
  stockRecord: {
    currentQuantity: string;
    quantityUnit: string;
    lastCheckedAt: Date | null;
  } | null;
};

type DoseInput = {
  residentId: string;
  dueWindowStart: Date;
  dueWindowEnd: Date;
  status: MedicationDoseStatus;
};

type PrnEventInput = {
  residentId: string;
  eventType: MedicationAdministrationEventType;
  recordedAt: Date;
};

type AllergyInput = {
  residentId: string;
  substance: string;
};

type ResidentSummaryInput = {
  resident: MedicationResidentIdentity;
  orders: OrderInput[];
  doses: DoseInput[];
  prnEvents: PrnEventInput[];
  allergies: AllergyInput[];
  lastAdministrationAt: Date | null;
  generatedAt: Date;
};

const oneHourMs = 60 * 60 * 1000;
const twentyFourHoursMs = 24 * 60 * 60 * 1000;
const formatMedicationCount = (
  count: number,
  singularLabel: string,
  pluralLabel: string = `${singularLabel}s`,
) => `${count} ${count === 1 ? singularLabel : pluralLabel}`;

const parseQuantity = (value: string) => {
  const numeric = Number.parseFloat(value.trim());
  return Number.isFinite(numeric) ? numeric : null;
};

const buildTaskCompatibleSummary = (args: {
  due: number;
  overdue: number;
  dueWithinHour: number;
  attentionFlags: number;
  exceptionCount: number;
  stockExceptionCount: number;
}): MedicationTaskCompatibleSummary => {
  const warnings: string[] = [];
  if (args.overdue > 0) {
    warnings.push(
      `${formatMedicationCount(args.overdue, 'medication')} overdue`,
    );
  }
  if (args.dueWithinHour > 0) {
    warnings.push(
      `${formatMedicationCount(
        args.dueWithinHour,
        'medication',
      )} due within the next hour`,
    );
  }
  if (args.exceptionCount > 0) {
    warnings.push(
      `${formatMedicationCount(
        args.exceptionCount,
        'medication exception',
      )} recorded this shift`,
    );
  }
  if (args.stockExceptionCount > 0) {
    warnings.push(
      `${formatMedicationCount(
        args.stockExceptionCount,
        'stock issue',
      )} affecting active medication`,
    );
  }

  let headline: string | null = null;
  if (args.overdue > 0) {
    headline = `${formatMedicationCount(args.overdue, 'medication')} overdue`;
  } else if (args.dueWithinHour > 0) {
    headline = `${formatMedicationCount(args.dueWithinHour, 'medication')} due soon`;
  } else if (args.exceptionCount > 0) {
    headline = `${formatMedicationCount(args.exceptionCount, 'medication exception')} open`;
  } else if (args.stockExceptionCount > 0) {
    headline = `${formatMedicationCount(args.stockExceptionCount, 'stock issue')} open`;
  } else if (args.due > 0) {
    headline = `${formatMedicationCount(args.due, 'medication')} active`;
  }

  return {
    total: args.due + args.overdue,
    overdue: args.overdue,
    dueWithinHour: args.dueWithinHour,
    highPriority: args.attentionFlags,
    headline,
    warnings,
  };
};

export const deriveStockException = (
  resident: MedicationResidentIdentity,
  order: OrderInput,
): MedicationStockException | null => {
  if (!order.isActive) {
    return null;
  }

  if (order.stockRecord == null) {
    return {
      medicationOrderId: order.id,
      residentId: resident.id,
      residentName: resident.fullName,
      medicationName: order.medicationName,
      code: 'MISSING_STOCK_RECORD',
      message: 'No stock record is linked to this active medication order.',
      quantity: null,
      quantityUnit: null,
      lastCheckedAt: null,
    };
  }

  const quantity = parseQuantity(order.stockRecord.currentQuantity);
  if (quantity == null) {
    return {
      medicationOrderId: order.id,
      residentId: resident.id,
      residentName: resident.fullName,
      medicationName: order.medicationName,
      code: 'UNPARSEABLE_STOCK_QUANTITY',
      message: 'The current stock quantity is not a numeric value.',
      quantity: order.stockRecord.currentQuantity,
      quantityUnit: order.stockRecord.quantityUnit,
      lastCheckedAt: order.stockRecord.lastCheckedAt,
    };
  }

  if (quantity <= 0) {
    return {
      medicationOrderId: order.id,
      residentId: resident.id,
      residentName: resident.fullName,
      medicationName: order.medicationName,
      code: 'NON_POSITIVE_STOCK',
      message: 'The current stock quantity is zero or below.',
      quantity: order.stockRecord.currentQuantity,
      quantityUnit: order.stockRecord.quantityUnit,
      lastCheckedAt: order.stockRecord.lastCheckedAt,
    };
  }

  if (order.stockRecord.lastCheckedAt == null) {
    return {
      medicationOrderId: order.id,
      residentId: resident.id,
      residentName: resident.fullName,
      medicationName: order.medicationName,
      code: 'UNCHECKED_STOCK',
      message: 'This stock record has never been checked.',
      quantity: order.stockRecord.currentQuantity,
      quantityUnit: order.stockRecord.quantityUnit,
      lastCheckedAt: null,
    };
  }

  return null;
};

export const buildResidentOperationalSummary = (
  input: ResidentSummaryInput,
  referenceTime = new Date(),
): MedicationResidentOperationalSummary => {
  const overdue = input.doses.filter(
    (dose) =>
      dose.status === MedicationDoseStatus.OVERDUE ||
      (dose.status === MedicationDoseStatus.DUE &&
        dose.dueWindowEnd.getTime() < referenceTime.getTime()),
  );
  const due = input.doses.filter(
    (dose) =>
      dose.status === MedicationDoseStatus.DUE &&
      dose.dueWindowEnd.getTime() >= referenceTime.getTime(),
  );
  const dueSoon = due.filter((dose) => {
    const diffMs = dose.dueWindowStart.getTime() - referenceTime.getTime();
    return diffMs >= 0 && diffMs <= oneHourMs;
  });
  const exceptionStatuses = new Set<MedicationDoseStatus>([
    MedicationDoseStatus.REFUSED,
    MedicationDoseStatus.OMITTED,
    MedicationDoseStatus.DELAYED,
    MedicationDoseStatus.NOT_AVAILABLE,
    MedicationDoseStatus.HELD,
  ]);
  const exceptions = input.doses.filter((dose) =>
    exceptionStatuses.has(dose.status),
  );
  const recentPrnEvents = input.prnEvents.filter(
    (event) =>
      referenceTime.getTime() - event.recordedAt.getTime() <= twentyFourHoursMs,
  );
  const stockExceptions = input.orders
    .map((order) => deriveStockException(input.resident, order))
    .filter((entry): entry is MedicationStockException => entry != null);
  const activeOrders = input.orders.filter((order) => order.isActive);
  const nextDueAt =
    due
      .map((entry) => entry.dueWindowStart)
      .sort((left, right) => left.getTime() - right.getTime())[0] ?? null;
  const attentionFlags =
    activeOrders.filter(
      (order) => order.isControlledDrug || order.requiresWitness,
    ).length +
    input.allergies.length +
    stockExceptions.length;

  return {
    resident: input.resident,
    taskSummaryCompatible: buildTaskCompatibleSummary({
      due: due.length,
      overdue: overdue.length,
      dueWithinHour: dueSoon.length,
      attentionFlags,
      exceptionCount: exceptions.length,
      stockExceptionCount: stockExceptions.length,
    }),
    activeOrders: {
      total: activeOrders.length,
      scheduled: activeOrders.filter((order) => !order.isPRN).length,
      prn: activeOrders.filter((order) => order.isPRN).length,
      controlledDrugs: activeOrders.filter((order) => order.isControlledDrug)
        .length,
      witnessRequired: activeOrders.filter((order) => order.requiresWitness)
        .length,
    },
    openDoses: {
      due: due.length,
      overdue: overdue.length,
      dueWithinHour: dueSoon.length,
      nextDueAt,
    },
    exceptions: {
      refused: exceptions.filter(
        (dose) => dose.status === MedicationDoseStatus.REFUSED,
      ).length,
      omitted: exceptions.filter(
        (dose) => dose.status === MedicationDoseStatus.OMITTED,
      ).length,
      delayed: exceptions.filter(
        (dose) => dose.status === MedicationDoseStatus.DELAYED,
      ).length,
      notAvailable: exceptions.filter(
        (dose) => dose.status === MedicationDoseStatus.NOT_AVAILABLE,
      ).length,
      held: exceptions.filter(
        (dose) => dose.status === MedicationDoseStatus.HELD,
      ).length,
      total: exceptions.length,
    },
    prn: {
      administeredLast24Hours: recentPrnEvents.filter(
        (event) =>
          event.eventType ===
          MedicationAdministrationEventType.PRN_ADMINISTERED,
      ).length,
      refusedLast24Hours: recentPrnEvents.filter(
        (event) =>
          event.eventType === MedicationAdministrationEventType.PRN_REFUSED,
      ).length,
      notGivenLast24Hours: recentPrnEvents.filter(
        (event) =>
          event.eventType === MedicationAdministrationEventType.PRN_NOT_GIVEN,
      ).length,
      offeredLast24Hours: recentPrnEvents.filter(
        (event) =>
          event.eventType === MedicationAdministrationEventType.PRN_OFFERED,
      ).length,
      latestRecordedAt: recentPrnEvents[0]?.recordedAt ?? null,
    },
    allergies: {
      total: input.allergies.length,
      substances: [...new Set(input.allergies.map((entry) => entry.substance))],
    },
    stock: {
      exceptionCount: stockExceptions.length,
      exceptions: stockExceptions,
    },
    lastAdministrationAt: input.lastAdministrationAt,
    generatedAt: input.generatedAt,
  };
};

export const buildShiftOperationalSummary = (args: {
  shift: MedicationShiftOperationalSummary['shift'];
  residents: MedicationResidentOperationalSummary[];
  generatedAt: Date;
}): MedicationShiftOperationalSummary => {
  const totals = args.residents.reduce(
    (aggregate, resident) => {
      aggregate.residents += 1;
      aggregate.activeOrders += resident.activeOrders.total;
      aggregate.scheduledOrders += resident.activeOrders.scheduled;
      aggregate.prnOrders += resident.activeOrders.prn;
      aggregate.controlledDrugs += resident.activeOrders.controlledDrugs;
      aggregate.witnessRequiredOrders += resident.activeOrders.witnessRequired;
      aggregate.due += resident.openDoses.due;
      aggregate.overdue += resident.openDoses.overdue;
      aggregate.dueWithinHour += resident.openDoses.dueWithinHour;
      aggregate.exceptions += resident.exceptions.total;
      aggregate.prnAdministrationsLast24Hours +=
        resident.prn.administeredLast24Hours;
      aggregate.allergyAlerts += resident.allergies.total;
      aggregate.stockExceptions += resident.stock.exceptionCount;
      return aggregate;
    },
    {
      residents: 0,
      activeOrders: 0,
      scheduledOrders: 0,
      prnOrders: 0,
      controlledDrugs: 0,
      witnessRequiredOrders: 0,
      due: 0,
      overdue: 0,
      dueWithinHour: 0,
      exceptions: 0,
      prnAdministrationsLast24Hours: 0,
      allergyAlerts: 0,
      stockExceptions: 0,
    },
  );

  return {
    shift: args.shift,
    taskSummaryCompatible: buildTaskCompatibleSummary({
      due: totals.due,
      overdue: totals.overdue,
      dueWithinHour: totals.dueWithinHour,
      attentionFlags:
        totals.controlledDrugs +
        totals.witnessRequiredOrders +
        totals.allergyAlerts,
      exceptionCount: totals.exceptions,
      stockExceptionCount: totals.stockExceptions,
    }),
    totals,
    residents: args.residents,
    generatedAt: args.generatedAt,
  };
};
