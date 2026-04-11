# Mobile Shift Workspace Vertical Slice

## Document purpose

This document records the first substantial mobile implementation slice for SerceSync in the same traceability format as the earlier requirement notes.

Unlike the earlier backend-first work, this slice brings the project into a more realistic product form. It connects the previously established handover and task-accountability contracts to a working Flutter client and reframes the post-handover mobile experience as a real shift workspace rather than a placeholder task shell.

This note is intended to support:

- engineering continuity
- dissertation traceability
- explanation of why the mobile architecture changed
- explanation of how the mobile work builds on the previous slices

## Slice summary

This slice delivers the first credible mobile care workflow in SerceSync:

1. the carer opens the mobile app
2. the carer logs in against the live API
3. the app resolves and displays the current handover
4. the carer acknowledges the handover
5. the app transitions into a post-handover shift workspace
6. the workspace exposes three real destinations:
   - `Priorities`
   - `Residents`
   - `My Shift`
7. current backend task/accountability items are reframed as care priorities
8. resident-centred navigation and documentation patterns are introduced

The slice spans:

- mobile application structure
- API integration
- mobile UI and navigation
- mobile interaction design
- dissertation-support documentation
- local development and simulator tooling
- automated verification

## Why this slice follows the earlier work

The earlier SerceSync slices established two backend truths:

1. a carer must acknowledge handover before a shift is treated as properly started
2. once the shift begins, work needs to be accountable through task state transitions and audit evidence

Those slices created the workflow rules, but they did not yet create a believable mobile product experience. The project therefore reached an important transition point: continuing to add backend features without improving the mobile information architecture would make the prototype technically richer but experientially weaker.

This slice was implemented next because it closes that gap.

It gives the dissertation a stronger evaluation surface by showing:

- how a safety-critical shift begins
- how the app frames work after handover
- how resident-centred documentation can start to emerge from the same workflow
- how practical mobile usability is shaped by governance constraints

## Relationship to the existing requirement notes

This slice does not replace the earlier notes. It builds on them.

### `handover-acknowledgement-vertical-slice.md`

That note described the first end-to-end workflow from login to audit-backed handover acknowledgement. This mobile slice takes that workflow and gives it a real interface, so the handover process is no longer only a backend and test artefact.

### `task-accountability-backend-slice.md`

That note described the second slice, where the task workflow contract was stabilised on the API side. This mobile slice consumes that contract and changes how it is presented: the same operational data is now framed as care priorities rather than a generic task list.

### `mobile-workspace-ia-pivot.md`

That note explains the product direction of the mobile IA pivot. The current slice document goes further by describing the implemented mobile foundation, the interface behaviour, the supporting files, and the dissertation significance of the work.

## Methodology alignment

### 1. Continue vertical-slice delivery, but move the centre of gravity to mobile

The project is still being delivered as thin, demonstrable slices. The difference here is that the meaningful increment is now centred on the mobile experience rather than exclusively on backend workflows.

This keeps the project balanced:

- backend rules remain authoritative
- frontend behaviour becomes demonstrable and evaluable
- documentation remains aligned with the implementation order

### 2. Preserve API-first workflow control

The mobile client does not invent workflow truth locally.

It still relies on backend authority for:

- authentication
- current handover state
- handover acknowledgement
- current task retrieval
- task state transitions such as complete, defer, and escalate

The mobile app is therefore an interface over the established workflow rules rather than a separate source of business logic.

### 3. Improve realism without overreaching scope

This slice intentionally avoids pretending that the prototype already has a complete resident-record system or a fully governed image-capture pipeline.

Instead, it introduces:

- real top-level destinations
- real first-pass resident detail views
- real work-facing shift information
- explicit placeholders where future governance-heavy functionality will belong

This keeps the slice academically honest and technically safer.

### 4. Document product and governance decisions as part of the implementation

The mobile work is not treated as complete simply because screens render. The slice also captures:

- why the app now pivots to `Priorities`, `Residents`, and `My Shift`
- why photo support is deferred to governed placeholders
- why BYOD suitability differs across mobile features

That documentation is part of the slice, not an afterthought.

## Scope implemented

### Mobile application foundation

The Flutter app has been moved beyond the single-screen placeholder stage and restructured into a more maintainable client application.

The mobile layer now includes:

- a dedicated API client
- typed models for auth, handover, task, and workspace presentation
- a shared visual theme
- reusable widgets for status and care-work cards
- bundled image assets used across login, empty states, and care context

This gives the project a cleaner platform for future slices rather than keeping all behaviour inside a monolithic screen.

### Login and API connection

The app now supports:

- email/password login
- configurable API base URL
- live authentication against the backend
- in-memory transition into the authenticated workflow

This keeps the mobile slice connected to the project’s API-first direction and makes backend demonstration flows usable from the phone client.

### Handover screen as the gateway into the shift

The handover screen now serves as the operational gateway into the shift workflow.

The screen supports:

- loading the current handover snapshot
- showing shift context and user context
- acknowledging the current handover
- handling already-acknowledged states safely
- refresh
- logout

The key behavioural change in this slice is what happens after acknowledgement: instead of sending the user to a generic task board, the app now enters the new workspace shell.

### Shift workspace shell

This slice introduces a new workspace shell that becomes the main post-handover home for the mobile app.

The shell provides a bottom navigation bar with three real destinations:

- `Priorities`
- `Residents`
- `My Shift`

This replaces the earlier placeholder module framing and ensures that each navigation destination is meaningful, reachable, and coherent with the care workflow.

### `Priorities`

The earlier “task board” concept has been reframed into `Priorities`.

This is not only a rename. It is a shift in the mental model of the screen:

- from checklist completion
- toward live care awareness and intervention planning

Current backend task items are adapted into a presentation layer that groups work into:

- `Urgent Now`
- `Due Within 1 Hour`
- `Reminders`

The screen now supports:

- countdown-style language for time-sensitive work
- softer reminder treatment for lower-urgency prompts
- consistent card framing around resident, room, reason, and time state
- care-oriented actions such as opening a resident, adding a note, marking something seen, or escalating

Existing empty, loading, and error states were preserved but reworded to align with the new screen identity.

### `Residents`

The app now includes a first-pass resident workspace rather than leaving resident access implicit or deferred.

The resident list screen shows:

- head-and-shoulders recognition imagery
- resident name
- room
- lightweight context such as alerts or due-soon state

Selecting a resident opens a first-pass detail screen with:

- resident header
- assignment context
- “today” summary
- recent timeline entries
- structured quick-add actions for documentation

The structured entry categories introduced in this slice are:

- `Care Given`
- `Observation`
- `Personal Care`
- `Nutrition / Hydration`
- `Mobility / Repositioning`
- `Medication Note`
- `Escalation`

This creates a stronger resident-centred direction for later implementation while keeping the current milestone intentionally narrow and safe.

### `My Shift`

The third destination is now `My Shift`, replacing the generic profile pattern.

This screen contains:

- current unit or floor assignment
- shift start and end
- handover acknowledgement state
- rota and upcoming shifts
- settings entry
- logout

This screen is deliberately work-specific. It is intended to feel like an operational companion to the shift rather than a personal account page.

### Photo evidence placeholders and governance

This slice deliberately does not implement unrestricted photo capture or upload logic.

Instead, it introduces the product and documentation scaffolding needed for future governed image support. The project now explicitly distinguishes:

- identity photos used for resident recognition
- care-evidence images such as wound-progress documentation
- life-event or documentary photos where appropriate

The mobile UI surfaces these as placeholders or future affordances only. The dissertation notes record that full implementation would require:

- consent or lawful-basis handling
- secure storage and transport
- auditability
- role-based access control
- retention and deletion rules

### BYOD position

The slice also records an explicit product position on BYOD.

The current stance is that low-sensitivity shift-awareness content is more appropriate for broad mobile access than unrestricted resident documentation or image-capture workflows.

For the dissertation, this creates a clearer split:

- more BYOD-suitable: rota, assignment, shift-awareness, and `My Shift` content
- higher-control content: resident records, evidence capture, and sensitive care documentation

This strengthens the prototype’s credibility because it acknowledges deployment risk and governance constraints directly.

### Local developer workflow support

The mobile slice also includes helper scripts to make repeatable local verification easier.

These scripts support:

- starting the backend if it is not already running
- waiting for the health endpoint
- rebuilding and reinstalling the iOS simulator app
- launching a fresh simulator build

This reduces friction in demonstrating the mobile workflow repeatedly while the prototype is still being actively iterated.

## Technical design notes

### Presentation adapters rather than backend refactoring

The `Priorities` screen does not require a new backend contract for this milestone.

Instead, existing current-task responses are adapted into a workspace presentation model that adds:

- urgency band
- time-state language
- resident context
- reminder semantics

This keeps the slice safer because the API contract remains stable while the mobile interpretation becomes more care-oriented.

### Resident workflow is intentionally first-pass

The resident list and resident detail views are implemented as a first-pass interface.

That means the current slice focuses on:

- navigation clarity
- resident recognition
- documentation structure
- continuity-of-care framing

It does not yet attempt to claim:

- full resident-record completeness
- complete note persistence
- deep clinical workflow coverage

This was a deliberate scope decision.

### Navigation is now explicit and honest

The earlier mobile direction risked creating dead-end navigation labels or generic modules with weak meaning.

This slice corrects that by ensuring:

- each tab is real
- each tab reflects a distinct work mode
- the post-handover transition lands in a meaningful destination

This is important for both UX quality and dissertation evaluation because it produces a more believable prototype.

### Shared visual language

The app theme and shared widgets were expanded so the mobile client can present a more coherent visual identity.

This includes:

- a teal-led medical-adjacent palette
- shared elevation and surface rules
- reusable status chips
- reusable task and priority card patterns
- image-based empty and error states

This work matters because it improves consistency across the slice and reduces UI fragmentation as more screens are added.

## Files and responsibilities

### Mobile foundation

- `apps/mobile/lib/main.dart`
- `apps/mobile/lib/api/api_client.dart`
- `apps/mobile/lib/models/user.dart`
- `apps/mobile/lib/models/handover.dart`
- `apps/mobile/lib/models/task.dart`
- `apps/mobile/lib/models/workspace_models.dart`
- `apps/mobile/lib/theme/app_theme.dart`

### Screens

- `apps/mobile/lib/screens/login_screen.dart`
- `apps/mobile/lib/screens/handover_screen.dart`
- `apps/mobile/lib/screens/shift_workspace_screen.dart`
- `apps/mobile/lib/screens/priorities_screen.dart`
- `apps/mobile/lib/screens/residents_screen.dart`
- `apps/mobile/lib/screens/resident_detail_screen.dart`
- `apps/mobile/lib/screens/my_shift_screen.dart`
- `apps/mobile/lib/screens/task_board_screen.dart`

### Widgets

- `apps/mobile/lib/widgets/status_chip.dart`
- `apps/mobile/lib/widgets/task_card.dart`
- `apps/mobile/lib/widgets/priority_card.dart`

### Assets and platform support

- `apps/mobile/assets/images/*`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/pubspec.lock`
- `apps/mobile/ios/Podfile`
- `apps/mobile/ios/Podfile.lock`
- `apps/mobile/ios/Runner.xcodeproj/*`
- `apps/mobile/ios/Runner.xcworkspace/*`

### Documentation

- `docs/requirements/handover-acknowledgement-vertical-slice.md`
- `docs/requirements/task-accountability-backend-slice.md`
- `docs/requirements/mobile-workspace-ia-pivot.md`
- `docs/requirements/mobile-shift-workspace-vertical-slice.md`
- `docs/README.md`

### Local development support

- `scripts/start-dev-mobile.sh`
- `scripts/reinstall-ios-sim.sh`

## Verification completed

### Mobile validation

- `flutter analyze`
- `flutter test`

### Runtime verification

- fresh iOS simulator reinstall and relaunch using the local helper script

### Workflow coverage

The implemented slice has been verified through:

- login rendering and transition checks
- handover acknowledgement routing into the workspace
- workspace navigation smoke coverage
- rendering of the new top-level destinations

## Risks and current limitations

This slice is intentionally substantial but still bounded.

The following are not yet fully implemented:

- backend-driven resident list and resident detail data
- persisted resident timeline entry creation
- complete documentation workflow depth
- photo capture and upload
- consent and media-governance enforcement in code
- manager-facing views over the same mobile interactions

These are acceptable omissions at this stage because the purpose of the slice is to establish a credible mobile foundation and a more defensible post-handover information architecture first.

## Outcome

SerceSync now has more than backend slices and placeholder screens. It has the beginning of a believable mobile care product.

The project can now demonstrate a coherent sequence:

1. a carer logs in
2. the current handover is resolved and acknowledged
3. the app opens a real post-handover shift workspace
4. current work is presented as care priorities
5. residents can be browsed in a resident-centred interface
6. shift context is visible in a dedicated operational screen

This slice materially improves the prototype in three ways:

- it makes the mobile experience credible enough for evaluation
- it connects the earlier backend workflow slices to a real client surface
- it records the product and governance reasoning needed to defend the next implementation steps academically

It also establishes the delivery pattern for future work:

- preserve backend authority for workflow rules
- add thin but real mobile workflows
- improve the information architecture before deepening domain complexity
- document each slice in a way that supports both engineering and dissertation use
