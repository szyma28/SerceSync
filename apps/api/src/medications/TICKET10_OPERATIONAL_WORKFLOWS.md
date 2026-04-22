# Ticket 10: Operational eMAR workflows

This module now includes the smallest credible backend-first slice for three operational workflows:

1. Medication reconciliation
2. Downtime pack export
3. Controlled-drug stock recording guardrails

## Reconciliation

Schema:

- `MedicationReconciliation` model in `apps/api/prisma/schema.prisma`
- `MedicationReconciliationStatus`
- `MedicationReconciliationTriggerType`

API:

- `GET /residents/:residentId/medication-reconciliations`
- `POST /residents/:residentId/medication-reconciliations`
- `POST /residents/medication-reconciliations/:reconciliationId/complete`
- `GET /manager/medication-reconciliation-queue`

Main service hook points:

- `getResidentMedicationReconciliations(...)`
- `createMedicationReconciliation(...)`
- `completeMedicationReconciliation(...)`
- `getManagerMedicationReconciliationQueue(...)`

Behavior:

- Reconciliations are resident-scoped and auditable.
- Opening and completing a reconciliation writes resident timeline entries.
- Opening and completing a reconciliation also writes medication audit events.
- Resident eMAR payloads now expose reconciliation history and an operational summary that highlights pending items.

## Downtime pack

API:

- `GET /residents/:residentId/emar/downtime-pack/export`

Main service hook point:

- `exportResidentDowntimePackCsv(...)`

Behavior:

- Produces a paper-friendly CSV snapshot for downtime use.
- Includes current order/schedule context, reconciliation summary, and controlled-drug note text.
- Emits a `MEDICATION_DOWNTIME_PACK_EXPORTED` audit event.

## Controlled-drug workflow

Main service hook point:

- `createStockTransaction(...)`

Behavior:

- Controlled-drug `RECEIVED`, `RETURNED`, `DISPOSED`, and `ADJUSTED` transactions require a witness.
- Controlled-drug `RETURNED`, `DISPOSED`, and `ADJUSTED` transactions require a reason.
- Controlled-drug stock actions write a resident timeline entry.
- Stock responses now include workflow guidance text for UI consumption.

## Current limits

This is intentionally a smallest credible slice, not a full operational build:

- No dedicated mobile or web reconciliation UI yet
- No paper-to-digital downtime import flow yet
- No automatic controlled-drug balance verification against dose administrations yet
- No printable PDF pack yet; export is CSV-only
- No migration file has been added for the new Prisma schema yet

## Safe next steps

1. Add a Prisma migration for `MedicationReconciliation` and the new enum values.
2. Add manager/mobile UI for opening and completing reconciliations.
3. Add a downtime recovery flow that records who transcribed paper administrations.
4. Add controlled-drug discrepancy dashboards using stock ledger vs administration history.
