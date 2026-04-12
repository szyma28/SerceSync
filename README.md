# SerceSync

SerceSync is a care-home workflow system designed to improve handover reliability, task accountability, exception visibility, and audit-ready reporting.

The project is being developed as a final-year software development dissertation project and consists of:
- a Flutter mobile app for carers and senior carers
- a Flutter web app for managers
- a NestJS backend API
- a PostgreSQL database accessed through Prisma

## Key features

- mandatory shift-start handover acknowledgement
- clear task completion, defer, and escalate flows
- manager-facing exception visibility and reporting
- audit-oriented workflow tracking
- deterministic simulation support for testing and demonstration

## Core workflow

The main workflow SerceSync is designed around is:

1. shift start
2. mandatory handover acknowledgement
3. task completion during shift
4. manager exceptions dashboard and evidence reporting

## Delivery methodology

The implementation is being delivered as a series of small vertical slices.

Each slice should:
- solve one meaningful workflow end to end
- enforce business rules in the API rather than in the clients
- include test evidence before it is treated as complete
- produce a supporting feature note in `docs/` for dissertation traceability

Completed slices and supporting delivery notes are documented in:
- `docs/requirements/handover-acknowledgement-vertical-slice.md`
- `docs/requirements/task-accountability-backend-slice.md`
- `docs/requirements/mobile-shift-workspace-vertical-slice.md`
- `docs/requirements/manager-residents-media-live-shift-vertical-slice.md`
- `docs/requirements/mobile-workspace-ia-pivot.md`

## Technology stack

- Frontend: Flutter and Dart
- Backend: NestJS and TypeScript
- Database: PostgreSQL
- ORM: Prisma

## Architecture overview

SerceSync follows a client-server architecture:

- Flutter mobile app -> NestJS API
- Flutter web app -> NestJS API
- NestJS API -> PostgreSQL via Prisma

PostgreSQL is never accessed directly by Flutter clients. Authentication, role-based access control, workflow logic, audit logic, and reporting should all be enforced server-side.

## Project structure

```text
FlutterAppSerceSync/
  README.md
  .gitignore
  .editorconfig
  .env.example
  docs/
    architecture/
    requirements/
    testing/
  apps/
    mobile/
    web/
    api/
```

## Development requirements

Install the following before running the project:

### General
- Git
- Node.js LTS
- pnpm
- PostgreSQL
- Flutter SDK
- Xcode (for iOS simulator on macOS)

### Verify Flutter

```bash
flutter --version
flutter doctor
```

### Verify Node and pnpm

```bash
node --version
pnpm --version
```

### Verify PostgreSQL

```bash
psql --version
```

Recommended baseline versions:

- Node.js 22 LTS or newer
- pnpm 10 or newer
- Flutter stable channel
- PostgreSQL 16 or newer

## Getting started

This repository contains the current dissertation prototype together with the slice notes used to document delivery decisions and traceable progress.

### 1. Enter the project

```bash
cd FlutterAppSerceSync
```

### 2. Copy local environment values

```bash
cp .env.example .env
```

Adjust values as needed for your local machine.

If your local PostgreSQL role is not `postgres`, update `DATABASE_URL` to match your machine.

Example for a local Homebrew PostgreSQL install on macOS:

```bash
DATABASE_URL=postgresql://your_local_role@localhost:5432/sercesync?host=/tmp
```

### 3. Create the local PostgreSQL database

If PostgreSQL is already running locally, create the development database:

```bash
createdb sercesync
```

If you prefer using `psql`:

```bash
psql postgres -c "CREATE DATABASE sercesync;"
```

### 4. Initialize the backend database foundation

```bash
cd apps/api
pnpm run prisma:format
pnpm run prisma:validate
pnpm run prisma:generate
pnpm run db:migrate
```

This applies the Prisma migrations and initializes the backend schema.

### 5. Seed the current demo data

```bash
pnpm run db:seed
```

The seed currently creates demo users, an active shift, a handover, live tasks, and resident records so the implemented mobile and web slices can be demonstrated locally.

### 6. Reset the demo back to the standard baseline

If you want the same known resident directory, handover, and live priority set again before a demo or review, run:

```bash
cd apps/api
pnpm run db:reset-demo
```

This clears the local demo workflow data that changes during use and recreates the standard baseline, including:
- the active carer shift
- the current handover
- the four live priority tasks used in the mobile workflow
- the seeded resident directory used by both mobile and manager web


## Environment configuration

A project-level `.env.example` file defines the minimum required local environment variables.

No real resident-identifiable data should be used in development, testing, or demonstration. Synthetic data only.

### Current environment variables

| Variable | Purpose |
| --- | --- |
| `APP_ENV` | Current application environment |
| `API_PORT` | Local NestJS API port |
| `API_BASE_URL` | Base URL used by clients to reach the API |
| `JWT_SECRET` | Secret used for token signing |
| `JWT_EXPIRES_IN` | Token lifetime |
| `DATABASE_URL` | PostgreSQL connection string |
| `WEB_APP_URL` | Local Flutter web URL |
| `MOBILE_APP_SCHEME` | Reserved mobile app scheme identifier |



## Current run commands

### Mobile app

```bash
cd apps/mobile
flutter run
```

The mobile app now includes multiple connected workflow slices:
- login with seeded demo credentials
- current handover display
- handover acknowledgement
- post-handover workspace navigation across Priorities, Residents, and My Shift
- live priority completion from the resident detail screen
- resident notes with optional photo evidence upload
- shift assignments pulled from the API

The API base URL defaults to `http://localhost:3000`.
If you need to override it, pass a Dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

### Web app

```bash
cd apps/web
flutter run -d chrome
```

The web app now includes a first-pass manager workspace with:
- manager login
- resident directory visibility across floors
- create and edit resident records

### API

```bash
cd apps/api
pnpm run start:dev
```

The API now supports the currently delivered slices with:
- `POST /auth/login`
- `GET /shifts/current`
- `GET /shifts/my`
- `GET /handovers/current`
- `POST /handovers/current/acknowledge`
- `GET /tasks/current`
- `POST /tasks/:id/complete`
- `POST /tasks/:id/defer`
- `POST /tasks/:id/escalate`
- `GET /residents`
- `GET /residents/:id`
- `POST /residents/:id/timeline`
- `GET /resident-media/:id`
- `GET /manager/residents`
- `POST /manager/residents`
- `PATCH /manager/residents/:id`

### Prisma and database scripts

```bash
cd apps/api
pnpm run prisma:format
pnpm run prisma:validate
pnpm run prisma:generate
pnpm run db:migrate
pnpm run db:seed
pnpm run db:reset-demo
pnpm run db:status
```

### Current schema foundation

The current Prisma schema includes:

- `Role`
- `User`
- `Shift`
- `Handover`
- `HandoverAcknowledgement`
- `Task`
- `Resident`
- `ResidentTimelineEntry`
- `ResidentTimelineMedia`
- `AuditEvent`

This now supports:

- the handover acknowledgement vertical slice
- the task accountability backend slice
- the mobile shift workspace slice
- the manager residents, media, and live shift slice

The next planned workflow step is the manager exceptions dashboard and evidence reporting layer.

## Current demo credentials

After running `pnpm run db:seed`, use:

- carer: `carer@sercesync.local` / `Password123!`
- manager: `manager@sercesync.local` / `Password123!`

## Continuous integration

The repository includes a minimal GitHub Actions workflow in `.github/workflows/ci.yml`.
It runs on every push to `main` and on every pull request.

### CI checks

- `apps/mobile`: `flutter analyze` and `flutter test`
- `apps/web`: `flutter analyze` and `flutter test`
- `apps/api`: `pnpm run prisma:generate`, `pnpm run db:deploy`, `pnpm run build`, `pnpm run test`, and `pnpm run test:e2e`

The API CI job uses a temporary PostgreSQL service inside GitHub Actions, so it does not depend on any external hosted database.
