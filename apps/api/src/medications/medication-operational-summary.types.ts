export type MedicationTaskCompatibleSummary = {
  total: number;
  overdue: number;
  dueWithinHour: number;
  highPriority: number;
  headline: string | null;
  warnings: string[];
};

export type MedicationStockExceptionCode =
  | 'MISSING_STOCK_RECORD'
  | 'UNPARSEABLE_STOCK_QUANTITY'
  | 'NON_POSITIVE_STOCK'
  | 'UNCHECKED_STOCK';

export type MedicationStockException = {
  medicationOrderId: string;
  residentId: string;
  residentName: string;
  medicationName: string;
  code: MedicationStockExceptionCode;
  message: string;
  quantity: string | null;
  quantityUnit: string | null;
  lastCheckedAt: Date | null;
};

export type MedicationResidentIdentity = {
  id: string;
  fullName: string;
  roomLabel: string;
  floorNumber: number;
  unitLabel: string;
};

export type MedicationResidentOperationalSummary = {
  resident: MedicationResidentIdentity;
  taskSummaryCompatible: MedicationTaskCompatibleSummary;
  activeOrders: {
    total: number;
    scheduled: number;
    prn: number;
    controlledDrugs: number;
    witnessRequired: number;
  };
  openDoses: {
    due: number;
    overdue: number;
    dueWithinHour: number;
    nextDueAt: Date | null;
  };
  exceptions: {
    refused: number;
    omitted: number;
    delayed: number;
    notAvailable: number;
    held: number;
    total: number;
  };
  prn: {
    administeredLast24Hours: number;
    refusedLast24Hours: number;
    notGivenLast24Hours: number;
    offeredLast24Hours: number;
    latestRecordedAt: Date | null;
  };
  allergies: {
    total: number;
    substances: string[];
  };
  stock: {
    exceptionCount: number;
    exceptions: MedicationStockException[];
  };
  lastAdministrationAt: Date | null;
  generatedAt: Date;
};

export type MedicationShiftOperationalSummary = {
  shift: {
    id: string;
    name: string;
    status: string;
    startsAt: Date;
    endsAt: Date;
    floorNumber: number;
    unitLabel: string;
  };
  taskSummaryCompatible: MedicationTaskCompatibleSummary;
  totals: {
    residents: number;
    activeOrders: number;
    scheduledOrders: number;
    prnOrders: number;
    controlledDrugs: number;
    witnessRequiredOrders: number;
    due: number;
    overdue: number;
    dueWithinHour: number;
    exceptions: number;
    prnAdministrationsLast24Hours: number;
    allergyAlerts: number;
    stockExceptions: number;
  };
  residents: MedicationResidentOperationalSummary[];
  generatedAt: Date;
};
