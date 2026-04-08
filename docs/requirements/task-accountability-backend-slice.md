# Task Accountability Backend Slice

## Document purpose

This document records the second SerceSync feature slice in a pull-request-style format. Unlike the first slice, this one is intentionally backend-only. Its purpose is to stabilise the task workflow contract before mobile or web clients are extended.

## Feature summary

This slice adds the backend workflow for task accountability during an active shift:

1. the authenticated carer requests their current shift tasks
2. the API resolves the active shift and assigned tasks
3. the carer can complete, defer, or escalate a task
4. the API records the resulting task state and an audit event

Endpoints added:

- `GET /tasks/current`
- `POST /tasks/:id/complete`
- `POST /tasks/:id/defer`
- `POST /tasks/:id/escalate`

## Why this slice comes next

The first implemented slice proved that a handover could be acknowledged and audited. The next dissertation-relevant question is what happens after handover, when care work begins.

Task accountability is the next logical step because it turns a shift from a passive acknowledgement flow into an operational workflow with traceable outcomes:

- completed work
- deferred work
- escalated work

This directly supports the wider SerceSync objective of improving accountability and manager visibility.

## Methodology alignment

### 1. Build the contract before the UI

This slice is backend-only on purpose. The methodology here is to lock down the domain rules and API responses first, then connect clients once the shape is stable.

That keeps frontend work cleaner because:

- the endpoint set is known
- response payloads are predictable
- task transitions already enforce the correct rules

### 2. Thin vertical progression without premature UI churn

Although this slice does not yet add a new screen, it still follows the same project methodology:

- extend one meaningful workflow at a time
- keep the scope narrow
- validate with tests and seeded data
- document the reasoning and outcome

The difference is only where the slice stops: it currently ends at the API boundary, ready for the next frontend pass.

### 3. Evidence-first implementation

This slice was treated as complete only after:

- schema migration
- repeatable seed data
- endpoint implementation
- automated e2e verification
- documentation of why the slice exists and what it changes

## Scope implemented

### Current task retrieval

`GET /tasks/current` returns the authenticated user's tasks for their active shift.

The response includes:

- shift summary
- current user summary
- task list

### Task state transitions

Three explicit task actions are now supported:

- complete
- defer
- escalate

These actions are enforced by the API, not by clients.

### State guard rules

The backend currently enforces these rules:

- the task must belong to the user's active shift
- the task must be assigned to the authenticated user
- only `PENDING` or `OVERDUE` tasks can transition
- already completed, deferred, or escalated tasks cannot be updated again

### Overdue normalization

When current tasks are requested or a task action is attempted, the API first marks any past-due pending tasks in the active shift as `OVERDUE`.

This keeps task state closer to operational reality without introducing background schedulers yet.

## Database changes

The `Task` model was extended with:

- `statusNote`
- `statusUpdatedAt`

These fields allow the current task state to retain the latest explanatory note and action timestamp, while the audit log preserves the full event trail.

## Audit trail additions

This slice makes use of the existing audit event kinds:

- `TASK_COMPLETED`
- `TASK_DEFERRED`
- `TASK_ESCALATED`

Each action stores:

- previous status
- next status
- note or reason

This is important for later manager-facing reporting and dissertation evaluation of accountability evidence.

## Demo and seed support

The seed script now creates three demo tasks for the active shift:

- hydration round
- observation follow-up
- escalation review

This makes the next frontend integration deterministic and gives a stable backend demonstration dataset.

## Files and responsibilities

### Backend

- `apps/api/src/tasks/tasks.controller.ts`
- `apps/api/src/tasks/tasks.service.ts`
- `apps/api/src/tasks/tasks.module.ts`
- `apps/api/src/tasks/dto/complete-task.dto.ts`
- `apps/api/src/tasks/dto/task-reason.dto.ts`
- `apps/api/prisma/schema.prisma`
- `apps/api/prisma/seed.cjs`
- `apps/api/test/app.e2e-spec.ts`

### Supporting updates

- `apps/api/src/app.module.ts`
- `apps/api/src/app.service.ts`
- `apps/api/src/app.controller.spec.ts`

## Verification completed

- `pnpm run prisma:format`
- `pnpm run prisma:validate`
- `pnpm exec prisma migrate dev --name add_task_status_tracking`
- `pnpm run prisma:generate`
- `pnpm run db:seed`
- `pnpm run build`
- `pnpm run test`
- `pnpm run test:e2e`

## Current limitations

This slice intentionally does not yet include:

- mobile task UI
- web manager exception views
- task reassignment
- multi-user task collaboration
- reopening or undoing a task action
- background scheduling for overdue transitions

These are deferred so the core backend contract can remain small and verified first.

## Outcome

SerceSync now has the backend foundations for the full “post-handover” operational workflow:

1. acknowledge the shift handover
2. retrieve current tasks
3. complete, defer, or escalate work
4. preserve state and audit evidence

This gives the project a stronger application backbone and creates the right handoff point for the next phase.
