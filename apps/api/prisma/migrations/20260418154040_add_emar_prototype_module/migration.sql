-- CreateEnum
CREATE TYPE "MedicationChartStatus" AS ENUM ('ACTIVE', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "MedicationRoundLabel" AS ENUM ('MORNING', 'MIDDAY', 'EVENING', 'BEDTIME', 'CUSTOM');

-- CreateEnum
CREATE TYPE "MedicationScheduleAnchorType" AS ENUM ('SHIFT_START', 'HANDOVER_ACKNOWLEDGED', 'FIXED_TIME');

-- CreateEnum
CREATE TYPE "MedicationDoseStatus" AS ENUM ('DUE', 'ADMINISTERED', 'REFUSED', 'OMITTED', 'DELAYED', 'NOT_AVAILABLE', 'HELD', 'CANCELLED', 'OVERDUE');

-- CreateEnum
CREATE TYPE "MedicationAdministrationEventType" AS ENUM ('ADMINISTERED', 'REFUSED', 'OMITTED', 'DELAYED', 'NOT_AVAILABLE', 'HELD', 'PRN_OFFERED', 'PRN_ADMINISTERED', 'PRN_REFUSED', 'PRN_NOT_GIVEN');

-- CreateEnum
CREATE TYPE "MedicationOrderSourceType" AS ENUM ('MANUAL_ENTRY', 'PHARMACY_SUPPLIED', 'IMPORTED');

-- CreateEnum
CREATE TYPE "MedicationStockTransactionType" AS ENUM ('RECEIVED', 'ADMINISTERED', 'DISPOSED', 'RETURNED', 'ADJUSTED');

-- CreateEnum
CREATE TYPE "MedicationChangeType" AS ENUM ('CREATED', 'UPDATED', 'DEACTIVATED', 'REACTIVATED', 'SCHEDULE_CHANGED', 'PRN_PROTOCOL_CHANGED');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_CHART_CREATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_ORDER_CREATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_ORDER_UPDATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_ORDER_DEACTIVATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_SCHEDULE_CREATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_SCHEDULE_UPDATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_INSTANCE_GENERATED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_ADMINISTERED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_REFUSED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_OMITTED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_DELAYED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_NOT_AVAILABLE';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_DOSE_HELD';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_PRN_EVENT_RECORDED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_STOCK_TRANSACTION_RECORDED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_ALLERGY_RECORDED';
ALTER TYPE "AuditEventKind" ADD VALUE 'MEDICATION_EXCEPTION_VIEWED';

-- AlterTable
ALTER TABLE "audit_events" ADD COLUMN     "medicationDoseInstanceId" UUID,
ADD COLUMN     "medicationOrderId" UUID,
ADD COLUMN     "residentId" UUID;

-- CreateTable
CREATE TABLE "resident_medication_charts" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "status" "MedicationChartStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdByUserId" UUID NOT NULL,
    "reviewedByUserId" UUID,
    "archivedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "resident_medication_charts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_orders" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "chartId" UUID NOT NULL,
    "medicationName" TEXT NOT NULL,
    "formulation" TEXT,
    "strength" TEXT,
    "doseAmount" TEXT NOT NULL,
    "doseUnit" TEXT NOT NULL,
    "route" TEXT NOT NULL,
    "instructions" TEXT NOT NULL,
    "startDate" DATE NOT NULL,
    "endDate" DATE,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "isControlledDrug" BOOLEAN NOT NULL DEFAULT false,
    "requiresWitness" BOOLEAN NOT NULL DEFAULT false,
    "isPRN" BOOLEAN NOT NULL DEFAULT false,
    "sourceType" "MedicationOrderSourceType" NOT NULL DEFAULT 'MANUAL_ENTRY',
    "createdByUserId" UUID NOT NULL,
    "updatedByUserId" UUID NOT NULL,
    "deactivatedAt" TIMESTAMP(3),
    "deactivationReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medication_orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_schedules" (
    "id" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "roundLabel" "MedicationRoundLabel" NOT NULL,
    "anchorType" "MedicationScheduleAnchorType" NOT NULL,
    "windowStartOffsetMinutes" INTEGER,
    "windowEndOffsetMinutes" INTEGER,
    "fixedTimeLocal" TEXT,
    "daysOfWeek" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medication_schedules_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_dose_instances" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "scheduleId" UUID NOT NULL,
    "shiftId" UUID NOT NULL,
    "dueWindowStart" TIMESTAMP(3) NOT NULL,
    "dueWindowEnd" TIMESTAMP(3) NOT NULL,
    "status" "MedicationDoseStatus" NOT NULL DEFAULT 'DUE',
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "recordedByUserId" UUID,
    "recordedAt" TIMESTAMP(3),
    "reason" TEXT,
    "notes" TEXT,
    "requiresWitness" BOOLEAN NOT NULL DEFAULT false,
    "witnessUserId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medication_dose_instances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_administration_events" (
    "id" UUID NOT NULL,
    "doseInstanceId" UUID,
    "residentId" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "shiftId" UUID NOT NULL,
    "eventType" "MedicationAdministrationEventType" NOT NULL,
    "doseGiven" TEXT,
    "doseUnit" TEXT,
    "reason" TEXT,
    "notes" TEXT,
    "recordedByUserId" UUID NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL,
    "witnessUserId" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_administration_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "prn_protocols" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "indication" TEXT NOT NULL,
    "whenToOffer" TEXT NOT NULL,
    "doseInstructions" TEXT NOT NULL,
    "minimumIntervalMinutes" INTEGER,
    "maxDosePer24Hours" INTEGER,
    "expectedEffect" TEXT,
    "monitoringRequired" TEXT,
    "whenToEscalate" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdByUserId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "prn_protocols_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_allergy_intolerances" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "substance" TEXT NOT NULL,
    "reaction" TEXT,
    "severity" TEXT,
    "recordedByUserId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medication_allergy_intolerances_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_stock_records" (
    "id" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "currentQuantity" TEXT NOT NULL,
    "quantityUnit" TEXT NOT NULL,
    "lastCheckedByUserId" UUID,
    "lastCheckedAt" TIMESTAMP(3),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "medication_stock_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_stock_transactions" (
    "id" UUID NOT NULL,
    "stockRecordId" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "transactionType" "MedicationStockTransactionType" NOT NULL,
    "quantity" TEXT NOT NULL,
    "quantityUnit" TEXT NOT NULL,
    "recordedByUserId" UUID NOT NULL,
    "witnessUserId" UUID,
    "reason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_stock_transactions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "medication_change_logs" (
    "id" UUID NOT NULL,
    "medicationOrderId" UUID NOT NULL,
    "residentId" UUID NOT NULL,
    "changedByUserId" UUID NOT NULL,
    "changeType" "MedicationChangeType" NOT NULL,
    "previousValueJson" JSONB,
    "newValueJson" JSONB,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "medication_change_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "resident_medication_charts_residentId_status_idx" ON "resident_medication_charts"("residentId", "status");

-- CreateIndex
CREATE INDEX "medication_orders_residentId_isActive_idx" ON "medication_orders"("residentId", "isActive");

-- CreateIndex
CREATE INDEX "medication_orders_chartId_idx" ON "medication_orders"("chartId");

-- CreateIndex
CREATE INDEX "medication_schedules_medicationOrderId_active_idx" ON "medication_schedules"("medicationOrderId", "active");

-- CreateIndex
CREATE INDEX "medication_dose_instances_residentId_status_idx" ON "medication_dose_instances"("residentId", "status");

-- CreateIndex
CREATE INDEX "medication_dose_instances_shiftId_status_dueWindowEnd_idx" ON "medication_dose_instances"("shiftId", "status", "dueWindowEnd");

-- CreateIndex
CREATE INDEX "medication_dose_instances_medicationOrderId_idx" ON "medication_dose_instances"("medicationOrderId");

-- CreateIndex
CREATE UNIQUE INDEX "medication_dose_instances_shiftId_scheduleId_key" ON "medication_dose_instances"("shiftId", "scheduleId");

-- CreateIndex
CREATE INDEX "medication_administration_events_doseInstanceId_idx" ON "medication_administration_events"("doseInstanceId");

-- CreateIndex
CREATE INDEX "medication_administration_events_residentId_recordedAt_idx" ON "medication_administration_events"("residentId", "recordedAt");

-- CreateIndex
CREATE INDEX "medication_administration_events_shiftId_recordedAt_idx" ON "medication_administration_events"("shiftId", "recordedAt");

-- CreateIndex
CREATE UNIQUE INDEX "prn_protocols_medicationOrderId_key" ON "prn_protocols"("medicationOrderId");

-- CreateIndex
CREATE INDEX "prn_protocols_residentId_active_idx" ON "prn_protocols"("residentId", "active");

-- CreateIndex
CREATE INDEX "medication_allergy_intolerances_residentId_createdAt_idx" ON "medication_allergy_intolerances"("residentId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "medication_stock_records_medicationOrderId_key" ON "medication_stock_records"("medicationOrderId");

-- CreateIndex
CREATE INDEX "medication_stock_records_residentId_idx" ON "medication_stock_records"("residentId");

-- CreateIndex
CREATE INDEX "medication_stock_transactions_stockRecordId_createdAt_idx" ON "medication_stock_transactions"("stockRecordId", "createdAt");

-- CreateIndex
CREATE INDEX "medication_stock_transactions_residentId_createdAt_idx" ON "medication_stock_transactions"("residentId", "createdAt");

-- CreateIndex
CREATE INDEX "medication_change_logs_residentId_createdAt_idx" ON "medication_change_logs"("residentId", "createdAt");

-- CreateIndex
CREATE INDEX "medication_change_logs_medicationOrderId_createdAt_idx" ON "medication_change_logs"("medicationOrderId", "createdAt");

-- CreateIndex
CREATE INDEX "audit_events_residentId_idx" ON "audit_events"("residentId");

-- CreateIndex
CREATE INDEX "audit_events_medicationOrderId_idx" ON "audit_events"("medicationOrderId");

-- CreateIndex
CREATE INDEX "audit_events_medicationDoseInstanceId_idx" ON "audit_events"("medicationDoseInstanceId");

-- AddForeignKey
ALTER TABLE "resident_medication_charts" ADD CONSTRAINT "resident_medication_charts_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_orders" ADD CONSTRAINT "medication_orders_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_orders" ADD CONSTRAINT "medication_orders_chartId_fkey" FOREIGN KEY ("chartId") REFERENCES "resident_medication_charts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_schedules" ADD CONSTRAINT "medication_schedules_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_dose_instances" ADD CONSTRAINT "medication_dose_instances_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_dose_instances" ADD CONSTRAINT "medication_dose_instances_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_dose_instances" ADD CONSTRAINT "medication_dose_instances_scheduleId_fkey" FOREIGN KEY ("scheduleId") REFERENCES "medication_schedules"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_dose_instances" ADD CONSTRAINT "medication_dose_instances_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "shifts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_administration_events" ADD CONSTRAINT "medication_administration_events_doseInstanceId_fkey" FOREIGN KEY ("doseInstanceId") REFERENCES "medication_dose_instances"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_administration_events" ADD CONSTRAINT "medication_administration_events_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_administration_events" ADD CONSTRAINT "medication_administration_events_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_administration_events" ADD CONSTRAINT "medication_administration_events_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "shifts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prn_protocols" ADD CONSTRAINT "prn_protocols_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "prn_protocols" ADD CONSTRAINT "prn_protocols_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_allergy_intolerances" ADD CONSTRAINT "medication_allergy_intolerances_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_stock_records" ADD CONSTRAINT "medication_stock_records_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_stock_records" ADD CONSTRAINT "medication_stock_records_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_stock_transactions" ADD CONSTRAINT "medication_stock_transactions_stockRecordId_fkey" FOREIGN KEY ("stockRecordId") REFERENCES "medication_stock_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_stock_transactions" ADD CONSTRAINT "medication_stock_transactions_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_stock_transactions" ADD CONSTRAINT "medication_stock_transactions_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_change_logs" ADD CONSTRAINT "medication_change_logs_medicationOrderId_fkey" FOREIGN KEY ("medicationOrderId") REFERENCES "medication_orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "medication_change_logs" ADD CONSTRAINT "medication_change_logs_residentId_fkey" FOREIGN KEY ("residentId") REFERENCES "residents"("id") ON DELETE CASCADE ON UPDATE CASCADE;
