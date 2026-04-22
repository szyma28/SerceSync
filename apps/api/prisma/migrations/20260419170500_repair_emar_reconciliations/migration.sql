DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'MedicationReconciliationStatus'
  ) THEN
    CREATE TYPE "MedicationReconciliationStatus" AS ENUM (
      'PENDING',
      'COMPLETED',
      'CANCELLED'
    );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type
    WHERE typname = 'MedicationReconciliationTriggerType'
  ) THEN
    CREATE TYPE "MedicationReconciliationTriggerType" AS ENUM (
      'DOWNTIME',
      'CARE_TRANSITION',
      'ROUTINE_REVIEW',
      'CONTROLLED_DRUG_CHECK'
    );
  END IF;
END $$;

ALTER TYPE "AuditEventKind"
ADD VALUE IF NOT EXISTS 'MEDICATION_RECONCILIATION_STARTED';

ALTER TYPE "AuditEventKind"
ADD VALUE IF NOT EXISTS 'MEDICATION_RECONCILIATION_COMPLETED';

ALTER TYPE "AuditEventKind"
ADD VALUE IF NOT EXISTS 'MEDICATION_DOWNTIME_PACK_EXPORTED';

CREATE TABLE IF NOT EXISTS "medication_reconciliations" (
  "id" UUID NOT NULL,
  "residentId" UUID NOT NULL,
  "status" "MedicationReconciliationStatus" NOT NULL DEFAULT 'PENDING',
  "triggerType" "MedicationReconciliationTriggerType" NOT NULL,
  "downtimeStartedAt" TIMESTAMP(3),
  "downtimeEndedAt" TIMESTAMP(3),
  "paperRecordLocation" TEXT,
  "discrepancySummary" TEXT,
  "controlledDrugCheckSummary" TEXT,
  "notes" TEXT,
  "createdByUserId" UUID NOT NULL,
  "completedByUserId" UUID,
  "completedAt" TIMESTAMP(3),
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,

  CONSTRAINT "medication_reconciliations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "medication_reconciliations_residentId_status_createdAt_idx"
ON "medication_reconciliations"("residentId", "status", "createdAt");

CREATE INDEX IF NOT EXISTS "medication_reconciliations_status_createdAt_idx"
ON "medication_reconciliations"("status", "createdAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'medication_reconciliations_residentId_fkey'
  ) THEN
    ALTER TABLE "medication_reconciliations"
    ADD CONSTRAINT "medication_reconciliations_residentId_fkey"
    FOREIGN KEY ("residentId")
    REFERENCES "residents"("id")
    ON DELETE CASCADE
    ON UPDATE CASCADE;
  END IF;
END $$;
