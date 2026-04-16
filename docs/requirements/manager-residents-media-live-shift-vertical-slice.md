# Manager Residents, Media Evidence, and Live Shift Vertical Slice

## Document purpose

This document records the next substantial SerceSync vertical slice in the same dissertation-traceability format as the earlier requirement notes.

The slice moves the project from a seeded resident workflow into a more credible operational prototype by implementing three linked capabilities:

1. manager-created and manager-editable residents on top of the shared seeded model
2. real resident timeline photo evidence upload instead of a placeholder-only flow
3. a live `My Shift` experience driven by backend shift and user-assignment data

This note is intended to support:

- engineering continuity
- dissertation traceability
- explanation of why these three changes belong in the same slice
- evidence that the mobile, web, and backend layers now align more closely around the same workflow reality

## Slice summary

This slice delivers a fuller care-operations loop across backend, mobile, and web:

1. a manager signs in using the seeded manager account
2. the manager views a shared residents directory that contains both seeded and newly created records
3. the manager creates or edits a resident directly against the backend
4. a carer opens the resident detail view on mobile
5. the carer records a structured timeline entry and may attach photo evidence
6. the backend stores the evidence metadata, preserves the file, and exposes the media through an authenticated route
7. the same resident detail flow renders the evidence back in the care timeline
8. the carer opens `My Shift`
9. `My Shift` resolves current and upcoming assignments from backend shift/user relationships rather than a static client-side rota

The slice spans:

- database schema
- migration and seed data
- backend authorization and workflow APIs
- Flutter mobile models, API integration, and screens
- Flutter web manager workspace
- automated verification
- production-style build verification

## Why these changes were grouped together

These three items were implemented together because they are tightly connected in both product logic and dissertation value.

### 1. Resident management without manager control would remain artificial

Earlier slices depended on seeded residents only. That was useful for stabilising backend and mobile workflows, but it left the prototype unable to demonstrate one of the most basic operational realities in a care setting: manager control over the resident directory.

Adding manager CRUD turns residents from static demo fixtures into managed records.

### 2. Timeline evidence without real upload would remain a mock interaction

The mobile resident documentation flow already pointed toward structured entries and future evidence capture, but until this slice the evidence path was only conceptual. Introducing real file upload turns the feature from an interface suggestion into an auditable technical mechanism.

### 3. `My Shift` needed to stop depending on local assumptions

The mobile app had already pivoted toward a more realistic post-handover workspace, but `My Shift` still depended on static client-side assumptions. Making it live off shift assignments closes an important credibility gap: the app now reflects real backend assignment state rather than a hand-crafted presentation model.

### 4. Together they strengthen the dissertation evaluation surface

Grouped together, these changes allow the prototype to demonstrate:

- manager authority over core operational data
- documented care activity with evidential attachments
- mobile shift awareness driven by backend truth

That is a more convincing and academically defensible milestone than implementing each item in isolation as an unrelated patch.

## Relationship to earlier requirement notes

This slice extends the work recorded in the previous documents rather than replacing it.

### `handover-acknowledgement-vertical-slice.md`

That slice established the safe shift-start pattern and audit-backed acknowledgement. This slice builds on that by enriching what happens after handover: resident management, resident documentation, and live shift awareness.

### `task-accountability-backend-slice.md`

That slice stabilised the backend contract for post-handover task state and accountability. This slice does not replace that logic. Instead, it extends the operational model around it by:

- giving managers direct control over resident records
- making resident timeline documentation richer
- making shift assignment visibility more faithful

### `mobile-workspace-ia-pivot.md`

That note explained why the mobile app was moving toward `Priorities`, `Residents`, and `My Shift`. This slice operationalises that direction by making two of those destinations substantially more real:

- `Residents` now supports actual evidence-bearing documentation
- `My Shift` now reflects backend assignment data

### `mobile-shift-workspace-vertical-slice.md`

That slice created the mobile workspace shell and first-pass resident flows. This slice hardens those foundations by replacing two notable placeholders:

- placeholder resident evidence flow
- placeholder `My Shift` rota assumptions

## Methodology alignment

### 1. Continue thin vertical-slice delivery

This work still follows the same project methodology: deliver one meaningful workflow increment across the stack instead of splitting work by technical layer.

This slice is meaningful because it now allows the system to demonstrate:

- management of resident records
- care documentation with image evidence
- backend-backed shift awareness

### 2. Preserve API-first workflow authority

The client layers do not invent resident, media, or shift truth locally.

The backend remains authoritative for:

- who may manage residents
- how residents are created and updated
- how resident timeline entries are stored
- whether uploaded media is accepted
- how media is retrieved
- which shifts are assigned to the current user
- which current shift is active

This is important both technically and academically because workflow rules remain centrally enforceable and auditable.

### 3. Replace placeholders only when the full path exists

The evidence flow was not marked complete when the UI allowed image selection. It was only treated as complete once:

- multipart upload was accepted server-side
- metadata was persisted
- media retrieval was protected
- resident detail responses included media
- the mobile client rendered uploaded evidence again

The same principle was applied to `My Shift`: the screen was not considered live until it consumed an API that derived assignments from actual backend user/shift relations.

### 4. Evidence-led completion criteria

This slice was only treated as complete after:

- schema update
- migration
- seed update
- backend tests
- mobile tests
- web tests
- backend build
- web build
- mobile simulator build
- requirement documentation

## Scope implemented

### Backend data-model changes

The schema now supports resident timeline media as a first-class concept.

Added or extended concepts include:

- `RESIDENT_TIMELINE_MEDIA_ATTACHED` audit event kind
- uploader relation from `User` to resident timeline media
- `ResidentTimelineMedia` model
- media relationship on `ResidentTimelineEntry`

This allows evidence metadata to be attached to timeline entries while preserving user linkage and later audit/reporting potential.

### Manager resident management

Manager-specific resident APIs were added so a manager can create and update residents directly.

Implemented backend behaviour includes:

- manager-only route protection
- DTO validation for resident creation
- DTO validation for resident update
- conflict handling for duplicate floor/room combinations
- resident mapping suitable for a manager-facing web workspace

### Real resident media evidence upload

Resident timeline entry creation now supports multipart uploads with an `evidence` file.

The implemented path includes:

- authenticated timeline entry creation
- image-only validation
- backend file persistence to local temp-backed storage
- media metadata persistence
- audit event creation when evidence is attached
- authenticated media streaming route
- resident detail payloads that include timeline media metadata

This is the first real implementation of care-evidence media in the project.

### Live shift overview

`My Shift` is no longer driven by local demo assumptions.

The backend now exposes a live shift overview endpoint that returns:

- `currentShift`
- all assigned shifts for the current user
- acknowledgement state for the current user where relevant

This allows the client to render current and upcoming shifts from backend truth.

### Seed data changes

The seed script was expanded to support this new slice.

It now creates:

- `MANAGER` role
- seeded manager user: `manager@sercesync.local`
- active shift assigned to the seeded carer
- two future shifts assigned to the same carer
- refreshed resident/task dataset aligned with the new shift overview and resident workflows

This keeps local verification and demonstrations deterministic.

### Mobile changes

The mobile app now includes:

- models for resident timeline media
- model support for evidence files before upload
- model support for live shift assignments and shift overview
- API client support for `/shifts/my`
- API client support for multipart resident timeline uploads
- authenticated media URL handling
- live `My Shift` loading from the backend
- resident detail evidence picker via image selection
- resident timeline rendering of evidence attachments

### Web changes

The web app now includes a first-pass manager workspace rather than only a placeholder shell.

Implemented web behaviour includes:

- manager sign-in using the seeded manager account
- resident directory retrieval from the backend
- resident create form
- resident edit flow
- manager-specific API client for resident CRUD

This gives the project its first meaningful manager-facing interface.

## Technical design notes

### Authorization model

Manager resident CRUD was not added as an unprotected convenience endpoint. It is explicitly protected through role metadata and a role guard layered on top of JWT authentication.

This matters because resident record management is more sensitive than generic read access and needs to remain server-controlled.

### Media-storage design choice

For this slice, evidence files are persisted to a temp-backed local storage directory rather than external object storage.

This is acceptable for the current stage because it:

- proves the full upload and retrieval workflow
- keeps the implementation small enough for a dissertation prototype milestone
- avoids prematurely introducing cloud-storage complexity

However, it is intentionally not the final production design.

### Authenticated media retrieval

Media is not exposed through an unauthenticated public URL. Retrieval is routed through an authenticated backend controller so access can remain consistent with user scope and later role rules.

This is an important governance-oriented design decision because care evidence should not become casually public due to convenience shortcuts.

### Live shift derivation

The new shift overview does not duplicate shift data into a separate mobile-specific table. It derives the mobile-friendly response from existing shift records and their user assignments.

This keeps the source of truth simpler and avoids unnecessary model fragmentation.

## Files and responsibilities

### Backend

- `apps/api/prisma/schema.prisma`
- `apps/api/prisma/migrations/20260411191228_add_manager_residents_media_and_shift_overview/migration.sql`
- `apps/api/prisma/seed.cjs`
- `apps/api/src/common/roles.decorator.ts`
- `apps/api/src/common/roles.guard.ts`
- `apps/api/src/residents/dto/create-manager-resident.dto.ts`
- `apps/api/src/residents/dto/update-manager-resident.dto.ts`
- `apps/api/src/residents/residents.controller.ts`
- `apps/api/src/residents/manager-residents.controller.ts`
- `apps/api/src/residents/resident-media.controller.ts`
- `apps/api/src/residents/residents.service.ts`
- `apps/api/src/residents/residents.module.ts`
- `apps/api/src/shifts/shifts.controller.ts`
- `apps/api/src/shifts/shifts.service.ts`
- `apps/api/test/app.e2e-spec.ts`

### Mobile

- `apps/mobile/lib/models/workspace_models.dart`
- `apps/mobile/lib/api/api_client.dart`
- `apps/mobile/lib/screens/my_shift_screen.dart`
- `apps/mobile/lib/screens/shift_workspace_screen.dart`
- `apps/mobile/lib/screens/resident_detail_screen.dart`
- `apps/mobile/pubspec.yaml`
- `apps/mobile/test/widget_test.dart`

### Web

- `apps/web/lib/main.dart`
- `apps/web/pubspec.yaml`
- `apps/web/test/widget_test.dart`

## Verification completed

### Backend verification

- `npm run prisma:validate`
- `npm run prisma:generate`
- `npm run db:seed`
- `npm run test -- --runInBand`
- `npm run test:e2e -- --runInBand`
- `npm run build`

### Web verification

- `flutter analyze`
- `flutter test`
- `flutter build web`

### Mobile verification

- `flutter analyze`
- `flutter test`
- `flutter build ios --simulator --no-codesign`

## Risks and current limitations

This slice is materially stronger than the previous placeholder state, but several limitations remain intentional.

### 1. Evidence storage is not yet durable

Uploaded evidence currently uses local temp-backed storage. This proves the workflow but is not sufficient for production durability or deployment portability.

### 2. Evidence capture is gallery-based in this slice

The mobile flow currently uses image selection rather than a deeper capture pipeline with camera-specific UX, consent prompts, or richer metadata.

### 3. Manager resident workflow is create/edit only

The current manager workspace supports listing, creating, and editing residents. It does not yet include archive, delete, search, filtering, or richer resident administration.

### 4. Web manager workspace is functional but intentionally minimal

The web implementation is a first-pass operational workspace, not a polished administrative console.

### 5. `My Shift` is now live, but still concise

The shift overview is backend-driven, but the screen remains intentionally focused on assignment awareness rather than deeper operational reporting, handover history, or policy controls.

## Outcome

SerceSync now demonstrates a more credible cross-role care workflow than in the earlier slices:

1. managers can maintain resident records through the backend
2. carers can add real evidence-bearing documentation to resident timelines
3. mobile shift awareness is now tied to backend assignment truth

This is a meaningful step forward for the dissertation because it moves the prototype from seeded demonstration logic toward a system that better reflects:

- role separation
- care documentation continuity
- auditable evidence capture
- live operational shift context

The implementation pattern remains consistent with the rest of the project:

- keep business rules in the API
- deliver in narrow but meaningful slices
- verify each slice thoroughly
- document both the technical and research significance of the change
