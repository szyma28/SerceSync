# Handover Acknowledgement Vertical Slice

## Document purpose

This document records the first implemented SerceSync feature slice in a format similar to a pull request explanation. It is intended to support both engineering continuity and dissertation traceability.

## Feature summary

This slice implements the first end-to-end care workflow in the project:

1. a carer logs in
2. the system resolves the user's active shift
3. the current handover is shown to the carer
4. the carer acknowledges the handover
5. the acknowledgement is written to the database and captured in the audit trail

The slice spans:

- database schema
- backend API
- seeded demo data
- mobile UI
- automated verification

## Why this feature was selected first

Mandatory handover acknowledgement sits at the center of the SerceSync problem statement. If a shift cannot reliably prove that handover information was seen and acknowledged, downstream task completion and manager exception reporting are weaker and harder to defend academically.

Implementing this slice first gives the project:

- a clear patient-safety-oriented workflow to demonstrate
- a concrete audit event to trace across the system
- a small but complete user journey for evaluation
- a stable baseline for later task and exception features

## Methodology alignment

This feature was implemented using the project's working methodology rather than as an isolated coding task.

### 1. Vertical slice delivery

The project is being delivered in thin, demonstrable slices instead of building all backend layers first and all client layers later. This slice proves one meaningful workflow from persistence to interface.

### 2. API-first workflow control

SerceSync is designed so that workflow rules are enforced server-side. The mobile app does not decide whether a handover is valid, active, or already acknowledged. It calls the API, and the API applies the business rules and writes the audit evidence.

### 3. Evidence-led development

The slice was not treated as complete when the code compiled. Completion required:

- schema migration
- seeded demo data
- unit and e2e verification
- mobile widget coverage
- documentation of the feature and its purpose

### 4. Dissertation traceability

This document links implementation choices back to the dissertation framing:

- problem addressed: unreliable handover confirmation
- implemented mechanism: mandatory acknowledgement capture
- evidence produced: API tests, mobile test, database migration, audit event
- next research step: extend the same pattern into task accountability and exception reporting

## Scope implemented

### Backend endpoints

- `POST /auth/login`
- `GET /shifts/current`
- `GET /handovers/current`
- `POST /handovers/current/acknowledge`

### Database changes

Added `HandoverAcknowledgement` to record who acknowledged a handover and when.

Key design rules:

- one acknowledgement per user per handover
- acknowledgement linked to both `handover` and `user`
- acknowledgement creation also produces an `AuditEvent`

### Demo data

A seed script now creates:

- role: `CARER`
- user: `carer@sercesync.local`
- active shift for that user
- handover summary for that shift

This keeps demonstrations repeatable and supports deterministic evaluation.

### Mobile app changes

The mobile app is no longer just a placeholder screen for this slice. It now provides:

- login form
- configurable API base URL
- current handover display
- acknowledge action
- refresh and logout flow

## Technical design notes

### Authentication

Authentication is intentionally minimal for this slice:

- email and password login
- JWT returned by the API
- guard-protected shift and handover endpoints

This is enough to exercise role-aware server-side flow control without prematurely expanding into a full auth subsystem.

### Handover acknowledgement behavior

The acknowledgement endpoint is idempotent from the user's perspective:

- if the handover was not yet acknowledged, it creates the acknowledgement and audit event
- if it was already acknowledged, it returns the current acknowledged state

This reduces accidental duplicate actions and simplifies mobile behavior.

### Auditability

Two important audit events are now created in the slice:

- `USER_LOGIN`
- `HANDOVER_ACKNOWLEDGED`

This begins the evidence trail required for later manager reporting features.

## Files and responsibilities

### Backend

- `apps/api/prisma/schema.prisma`
- `apps/api/prisma/seed.cjs`
- `apps/api/src/auth/*`
- `apps/api/src/common/*`
- `apps/api/src/handovers/*`
- `apps/api/src/shifts/*`
- `apps/api/src/prisma/prisma.service.ts`
- `apps/api/test/app.e2e-spec.ts`

### Mobile

- `apps/mobile/lib/main.dart`
- `apps/mobile/test/widget_test.dart`

## Verification completed

### API

- `pnpm run build`
- `pnpm run test`
- `pnpm run test:e2e`

### Mobile

- `flutter analyze`
- `flutter test`

## Risks and current limitations

This slice is intentionally minimal. The following are not yet implemented:

- role-based authorization beyond carrying the role in the token
- refresh tokens or session revocation
- manager-facing web views
- task completion flows
- exception escalation flows
- production-grade error mapping and observability

These omissions are acceptable at this stage because the goal of the slice is to validate the end-to-end handover acknowledgement mechanism first.

## Outcome

The project now has its first meaningful vertical slice. SerceSync can demonstrate a real workflow rather than only a scaffold:

1. authenticate a care worker
2. resolve the current shift and handover
3. record a mandatory acknowledgement
4. persist evidence in the database and audit log

This establishes the implementation pattern for the next slices:

- build one user-important workflow at a time
- enforce rules in the API
- capture audit evidence as part of the workflow
- verify with automated tests
- document the slice for dissertation traceability
