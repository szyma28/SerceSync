# Care Signals And Incident Response Future Slice

## Purpose

This note records follow-up product ideas from the SerceSync flow review for later planning.

Date captured: 2026-04-12

## Candidate product requirements

### 1. Medication safety support in the nurse persona flow

The nurse-facing experience should surface medication-related workload and risk cues more clearly to reduce the chance of medication errors.

Potential directions:
- Show a medication count for each resident or shift context.
- Highlight overdue, upcoming, or high-priority medication tasks.
- Surface medication-related warnings in the nurse persona or shift summary area.

### 2. Resident priority color cues on the residents page

Resident profiles should visually reflect urgency or care priority using a simple traffic-light style status treatment.

Suggested rule shape:
- Green for stable / no immediate concern.
- Amber for medium attention / follow-up needed.
- Red for urgent concern, active issue, or incident-related priority.

This should help carers and managers scan the list faster without opening every profile.

### 3. More specific structured care note types

Personal care notes should be broken into more precise sub-headings so carers can record care consistently and managers can review it more reliably.

Examples mentioned:
- Shower
- Continence
- Foot care
- Skin care

This likely needs a structured note model rather than one broad free-text bucket for "personal care".

### 4. Food intake logging

The app should support recording how much of each meal a resident ate.

Potential capture model:
- Meal type
- Amount eaten
- Time logged
- Optional notes or concerns

This would make nutrition tracking easier and give managers a clearer live picture of intake trends.

### 5. In-app incident forms with live manager escalation

Carers should be able to complete incident forms directly inside the app.

Manager-facing behavior should include:
- Incidents appearing as a red warning state.
- Live visibility in the manager view or feed.
- Clear distinction between routine updates and incident events.

This slice connects operational reporting with real-time management awareness rather than relying on delayed follow-up.

## Why these ideas matter

Across all five ideas, the common theme is stronger operational visibility:
- safer medication handling
- faster recognition of resident risk
- more structured care documentation
- better nutrition tracking
- faster incident escalation

Together, they point toward a future vertical slice focused on care signals, structured logging, and live exception handling.

## Planning note

When this work is picked up, it would make sense to split it into separate implementation tracks:
- resident priority signaling
- structured care note taxonomy
- meal intake logging
- incident workflow and manager alerting
- medication safety indicators
