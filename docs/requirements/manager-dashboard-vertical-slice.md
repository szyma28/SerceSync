# Manager Dashboard Vertical Slice

## Document purpose

This document records the manager dashboard overview as a dedicated SerceSync vertical slice in the same dissertation-support format as the earlier requirement notes.

The slice is intended to support:

- engineering continuity
- dissertation traceability
- explanation of why the manager dashboard belongs in the current implementation sequence
- evidence that the web manager experience now includes an operational overview surface rather than only a resident-management shell

## Slice summary

This slice delivers the first believable manager landing dashboard in the Flutter web application:

1. a manager signs in to the web workspace
2. the client requests the active shift options and selects a shift context
3. the client requests `/manager/dashboard?shiftId=...`
4. the backend resolves the selected active shift that should drive the overview
5. the backend derives dashboard metrics from task state, assigned users, and handover acknowledgements
6. the backend returns an exception feed and compliance trend series scoped to that unit
7. the web workspace renders a `Unit Overview` dashboard with summary cards, live exception visibility, a compliance chart, and a shift selector when more than one active shift exists
8. the manager keeps the same workspace shell and sidebar while moving between dashboard and residents

The slice spans:

- manager-only backend aggregation
- web API consumption and typed dashboard models
- dashboard presentation components
- manager workspace shell and sidebar behavior
- responsive widescreen layout refinement
- automated verification for the web workspace

## Why this slice was selected now

The project already had the beginnings of a manager-facing workspace through resident management, but that was not enough to demonstrate what a manager actually needs when opening the system at the start of a shift or while monitoring the unit.

Without a dashboard, the manager web experience remained incomplete in three important ways.

### 1. Resident CRUD alone does not provide operational awareness

Managers need to understand what is going wrong on the floor before deciding where to act. A resident directory is useful, but it does not communicate risk, urgency, or current shift conditions.

### 2. Earlier care-accountability slices needed a manager-facing readout

Previous slices introduced handover acknowledgement, task accountability, and live shift relationships. Those are important backend and mobile foundations, but they gain much more dissertation value when the system can also present their consequences to a manager through an overview surface.

### 3. The dissertation needs a clearer management-evaluation surface

The manager dashboard allows the prototype to demonstrate:

- visibility of overdue and escalated work
- awareness of unread handovers
- a current-shift progress signal
- a shortlist of live exceptions

That makes the manager role materially different from the carer role and creates a stronger basis for evaluating the system as a care-coordination tool.

## Relationship to earlier requirement notes

This slice extends prior work rather than replacing it.

### `handover-acknowledgement-vertical-slice.md`

That slice created the acknowledgement mechanism. The current dashboard slice surfaces one of its practical outcomes through the `unreadHandovers` signal.

### `task-accountability-backend-slice.md`

That slice established backend task-state logic and accountability patterns. The dashboard now turns that backend truth into manager-readable summary metrics and exception visibility.

### `manager-residents-media-live-shift-vertical-slice.md`

That slice created a first meaningful manager workspace and resident-management flow. The current slice builds on it by giving managers a dashboard landing state rather than forcing the web experience to begin and end with resident CRUD.

## Methodology alignment

### 1. Vertical-slice delivery

This was implemented as a true slice across backend and web rather than as isolated styling or API work. The manager dashboard only becomes meaningful when:

- the backend computes the overview
- the web client consumes a typed response
- the shell and layout support the overview cleanly

### 2. API-first workflow authority

The manager dashboard is not assembled from arbitrary client-side demo values. The server remains authoritative for:

- the active shift used for the dashboard
- the selected shift scope used for the dashboard
- overdue and escalated task counts
- unread handover count
- the contents and ordering of the exception feed
- the compliance series returned to the web client

This matters technically and academically because the management surface remains tied to server-side workflow truth.

### 3. Evidence-led completion

The slice was not treated as complete when a dashboard screen first rendered. Completion required:

- backend route availability
- typed web API consumption
- dashboard UI composition
- responsive layout stabilization
- sidebar zoom-behavior hardening
- `flutter analyze`
- `flutter test test/widget_test.dart`
- requirement documentation

### 4. Dissertation traceability

This slice strengthens traceability between problem framing and implementation:

- problem addressed: poor manager visibility of live care risk
- implemented mechanism: dashboard overview backed by active-shift data
- evidence produced: dashboard endpoint, typed client contract, verified web rendering, documented feature slice

## Scope implemented

### Backend manager dashboard endpoint

The backend now exposes a manager-only dashboard route:

- `GET /manager/dashboard/shifts`
- `GET /manager/dashboard?shiftId=...`

The route is protected by:

- `JwtAuthGuard`
- `RolesGuard`
- `@Roles('MANAGER')`

This keeps management visibility behind authenticated and role-aware server control.

### Dashboard derivation logic

The manager dashboard snapshot is derived from the selected active shift rather than hand-built static demo values.

Implemented backend behavior includes:

- listing active shifts for manager selection
- resolving the selected active shift for dashboard use
- failing clearly when no active shift exists or no shift is selected
- classifying active-shift tasks into dashboard-relevant statuses
- counting overdue tasks
- counting escalated items
- deriving unread handovers from assigned users minus acknowledgements
- estimating shift completion percentage from elapsed shift time
- generating a prioritized exception feed scoped to the selected unit
- generating a compliance trend series for the chart

### Web manager dashboard client flow

The web manager workspace now includes a dedicated dashboard data path.

Implemented web behavior includes:

- authenticated `getActiveShifts` API client support
- authenticated `getDashboard` API client support
- typed `ManagerDashboardSnapshot` parsing
- in-session selected shift state
- dashboard loading and error state management in the workspace screen
- refresh support for the currently selected tab
- manager landing title of `Unit Overview`

### Dashboard presentation components

The manager overview screen now renders:

- five top-level metric cards
- a live exception feed card
- a compliance trend chart

The metrics currently include:

- overdue tasks
- escalated items
- unread handovers
- shift completion percentage

This gives the web app its first genuine manager command surface.

### Workspace and sidebar layout refinement

The dashboard slice also required shell stabilization work so the interface remained credible during demos and browser zoom changes.

Implemented layout behavior includes:

- a wider 16:9-oriented manager shell
- equal-width metric cards across supported breakpoints
- full-width stacking of the exception feed and compliance chart
- a manager sidebar with a pinned footer card
- full-width nurse artwork anchored above the footer
- sidebar scroll behavior that preserves footer space instead of letting the bottom elements drift unpredictably

## Technical design notes

### Manager overview is shift-centric

The dashboard is intentionally anchored to a manager-selected active shift rather than attempting to summarize all historical unit activity. This keeps the view focused on what matters operationally right now while remaining safe when multiple units have active shifts at the same time.

### Exception feed is prioritized, not exhaustive

The exception feed is designed as a short management signal rather than a full event log. It prioritizes:

- escalated tasks
- overdue tasks
- due-soon tasks

and caps the returned set to a small number of top items. This is appropriate for a landing dashboard and can later be extended into a deeper manager exceptions workspace.

### Compliance series is a management signal, not a historical analytics subsystem

The compliance chart is currently a derived trend visualization suitable for dashboard communication. It should be treated as a current management signal rather than a finished historical reporting engine.

### Sidebar layout needed to become structurally stable

Several implementation passes were required to avoid a visually unstable sidebar under zoom changes. The final approach separates:

- scrolling navigation content
- full-width artwork
- pinned profile footer

This is more robust than tying all sidebar content to one vertical flex layout.

## Files and responsibilities

### Backend

- `apps/api/src/residents/manager-dashboard.controller.ts`
- `apps/api/src/residents/residents.service.ts`

### Web

- `apps/web/lib/src/manager/manager_api_client.dart`
- `apps/web/lib/src/manager/manager_models.dart`
- `apps/web/lib/src/manager/manager_workspace.dart`
- `apps/web/lib/src/manager/manager_dashboard.dart`
- `apps/web/lib/src/manager/manager_sidebar.dart`
- `apps/web/test/widget_test.dart`

## Verification completed

### Web

- `flutter analyze`
- `flutter test test/widget_test.dart`

## Risks and current limitations

This slice is meaningful but still intentionally bounded.

Current limitations include:

- dashboard visibility depends on at least one active shift being present
- the compliance chart is a derived overview, not a historical reporting module
- the exception feed is intentionally short and not a full manager work queue
- `Staff & Shifts`, `Compliance Reports`, and `Demo Console` remain placeholder lanes in the current shell
- the export action is still staged for a later manager tools pass

These limits are acceptable for this slice because the goal is to establish a credible manager overview surface first.

## Outcome

SerceSync now has a real manager dashboard slice rather than only a manager shell.

The web experience can demonstrate a coherent manager journey:

1. sign in as a manager
2. open a dashboard shaped around the active shift
3. review live unit metrics
4. identify active exceptions and unread handovers
5. move into the rest of the manager workspace from a stronger operational starting point

This is a stronger and more defensible dissertation milestone because the project now demonstrates not just task execution and resident management, but management visibility over live care operations.
