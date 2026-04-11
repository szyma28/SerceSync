# Mobile Workspace IA Pivot

## Purpose

This note records the first mobile information-architecture pivot for SerceSync. The mobile app is no longer framed as a checklist-style task tool. Instead, the post-handover experience is being reshaped into a live shift workspace with three real destinations:

- `Priorities`
- `Residents`
- `My Shift`

This change aligns the mobile experience more closely with the intended care workflow for the dissertation prototype: safe shift start, live awareness of what matters now, and resident-centred documentation.

## Product Direction

### Priorities

`Priorities` replaces the earlier `Tasks` framing. The screen is intended to surface what needs attention now or soon, rather than encouraging carers to work through a game-like tick list. Priority content is grouped into three bands:

- `Urgent Now`
- `Due Within 1 Hour`
- `Reminders`

This supports countdown-style prompts for time-sensitive care, such as medication or repositioning, while also allowing softer reminders such as hygiene gaps or follow-up prompts.

### Residents

`Residents` becomes the main care workspace. The resident list shows identity cues and room context, then opens into a resident detail view with a daily summary, recent activity timeline, and structured note entry types. The intent is to make continuity of care visible across carers and across the shift.

Structured entry types in this milestone include:

- `Care Given`
- `Observation`
- `Personal Care`
- `Nutrition / Hydration`
- `Mobility / Repositioning`
- `Medication Note`
- `Escalation`

### My Shift

`My Shift` replaces the earlier generic `Profile` idea. It brings together current assignment, handover acknowledgement state, rota, and operational settings/logout in one place. This framing is closer to how the mobile app is expected to be used in practice.

## Photo Support And Governance

Photo support is part of the long-term care-evidence direction for SerceSync, but in this milestone it is surfaced only as a governed placeholder rather than a live capture/upload feature.

The dissertation should explicitly distinguish between different kinds of images:

- identity photos used to help staff recognise residents quickly
- care-evidence photos, such as wound-progress or skin-integrity documentation
- life-event or documentary photos where appropriate, such as birthdays or celebration moments

Before full photo support can be enabled, the design must include:

- consent and lawful-basis handling
- role-based access controls
- secure storage and transport controls
- auditability of who captured, viewed, and attached an image
- clear retention and deletion expectations

## BYOD Position

The current product stance is that BYOD is more appropriate for low-sensitivity shift-awareness features than for unrestricted resident-record or image capture workflows.

For dissertation purposes, the most defensible split is:

- BYOD-friendly: rota, assignment, shift-awareness, and other `My Shift` content
- more sensitive / higher control requirement: resident documentation, care evidence, and photo capture features

This strengthens the evaluation because it acknowledges that practical mobile usability and information governance do not always point to the same deployment model.

## Scope Of This Milestone

This first pass intentionally stops short of a full deep resident workflow. It delivers:

- a real post-handover workspace shell
- replacement of placeholder bottom-navigation destinations
- a first-pass `Priorities` screen driven by existing task data
- a first-pass `Residents` list and resident detail flow
- a first-pass `My Shift` screen
- governance-facing documentation for photo support and BYOD

Further iterations can deepen resident data integration, photo workflows, and policy enforcement once the backend and governance model are ready.
