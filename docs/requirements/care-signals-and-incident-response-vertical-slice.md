# Care Signals And Incident Response Vertical Slice

Date: 2026-04-15

## Purpose

This document records the implementation and cleanup pass for the care-signals and incident-response slice. It exists so the feature is not only present in code, but also explainable in terms of behaviour, architecture, verification, and maintainability.

## What This Slice Adds

The slice introduces a resident-priority model that can be elevated by live incidents, plus end-to-end reporting and resolution workflows across API, mobile, and manager web surfaces.

### API behaviour

- Residents now carry a baseline priority as part of their managed record.
- Open and acknowledged incidents can temporarily override baseline priority to drive a live care-signal state.
- Carers can create timeline entries with optional personal-care subtype and optional evidence media.
- Carers can report incidents with severity, category, details, and optional evidence media.
- Managers can acknowledge incidents and then resolve them in a controlled state progression.
- The dashboard can surface incident pressure, overdue work, unread handovers, and a ranked exception feed.

### Mobile behaviour

- The resident detail view now shows the effective resident priority, including whether it is being driven by a live incident override.
- Active incidents are summarised directly in the resident detail flow so carers can understand why a resident has become amber or red.
- Carers can add richer care notes and submit incidents without leaving the resident context.
- Evidence attachments are previewed before submission so the user sees what is being uploaded.

### Manager web behaviour

- Manager residents and dashboard views now display live resident priority, active incident counts, and incident-driven exception states.
- Dashboard exception items distinguish between incident severity and task-state pressure so the manager view reflects operational urgency instead of only task completion.

## Cleanup And Refactor Pass

This implementation pass also included a targeted quality review so the new slice is easier to maintain and safer to extend.

### 1. Local e2e Postgres reliability fix

The API e2e runner previously assumed a local `postgres` role from the root `DATABASE_URL`. On this machine the available local superuser is `erykszymanski`, so the suite failed before it could validate the feature.

The e2e runner was updated to:

- try the configured local connection first
- detect a local-role mismatch for localhost-style development databases
- fall back to the current OS user for local-only execution
- try a local socket-host variant when appropriate
- print a safe, password-free fallback message so the reason is visible during test runs

This keeps production and CI behaviour untouched while making local verification dependable.

### 2. Resident detail screen decomposition

The resident detail screen had grown into a large, mixed-responsibility file that contained:

- resident header rendering
- active-task UI and completion flow
- timeline cards and evidence previews
- bottom-sheet scaffolding
- note-entry form logic
- incident-report form logic

That screen was split into focused part files:

- `resident_detail_header.dart`
- `resident_detail_tasks.dart`
- `resident_detail_timeline.dart`
- `resident_detail_sheet_widgets.dart`
- `resident_detail_entry_sheet.dart`
- `resident_detail_incident_sheet.dart`

The parent file now keeps state coordination and workflow entry points, while the extracted files own their local presentation concerns. Reusable sheet chrome and evidence preview UI were centralised so the note and incident flows no longer duplicate modal scaffolding.

### 3. Residents service extraction

The residents service had accumulated both orchestration logic and large amounts of pure formatting and response-mapping code. That made the service harder to scan because database work, business rules, and presentation shaping were interleaved.

The service was split along responsibility lines:

- `resident-priority.ts` now owns live-priority calculation and active-incident rules.
- `residents.constants.ts` now owns shared labels, active incident statuses, incident include shape, and timeline-entry title fallback rules.
- `residents.presentation.ts` now owns context-line formatting, task alerts, response mappers, dashboard exception feed helpers, and compliance-series shaping.

After the extraction, `residents.service.ts` is primarily responsible for:

- validation
- persistence
- transaction boundaries
- audit event creation
- composing the response using dedicated helper modules

This keeps business rules in obvious places and reduces the cost of future feature edits.

## Why This Structure Is Better

- Priority rules can now be changed without searching through controller and mapping code.
- Presentation changes for dashboard and resident views are isolated from Prisma transactions.
- The resident mobile flow is easier to read because sheet widgets, task cards, and timeline cards are grouped by concern.
- Local verification is less fragile, which lowers the cost of regression checking during future implementation passes.

## Verification Completed

The following verification steps were run after the cleanup:

### API

- `pnpm exec tsc --noEmit -p tsconfig.json`
- `pnpm run test:e2e`

Result:

- TypeScript compilation passed.
- E2E suite passed with 13/13 tests.

### Mobile

- `flutter analyze`
- `flutter test`

Result:

- Analyzer passed with no issues.
- Widget test suite passed with 9/9 tests.

## Follow-Up Recommendations

1. Add focused unit tests around `resident-priority.ts` and `residents.presentation.ts` so future edits to priority and exception-feed behaviour fail fast without needing full e2e coverage.
2. Consider extracting media persistence into its own helper if incident or timeline evidence handling grows beyond image uploads.
3. When this slice is pushed, keep it on its own branch and PR so the review remains focused on care signals, incidents, and the maintainability improvements introduced here.
