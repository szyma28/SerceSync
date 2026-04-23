# SerceSync

SerceSync is a care-home workflow system focused on safer shift handovers, clearer task accountability, richer resident context, medication visibility, and manager-ready operational reporting.

The repository contains:

- a Flutter mobile app for carers and nurses
- a Flutter web app for managers
- a NestJS backend API
- a PostgreSQL database managed through Prisma

## Current product areas

### Mobile workspace

- login with seeded local accounts
- mandatory handover acknowledgement before shift work begins
- priorities view for urgent tasks and medication signals
- resident directory and resident detail workflows
- offline-capable text-note and incident capture with queued sync
- nurse-specific medication round tools
- personal-care, meal-intake, and incident-aware resident context

### Manager workspace

- manager login and session restore
- browser-session renewal and recovery after temporary API interruption
- live dashboard coverage across active floors
- resident directory with create and edit flows
- baseline priority and resident profile context management
- lightweight reporting and CSV export workflows

### Backend

- authentication and role-aware access
- shifts, handovers, residents, tasks, and medication workflows
- manager dashboard aggregation and reporting endpoints
- local seed and reset scripts for deterministic demo data

## Architecture overview

SerceSync uses a standard client-server split:

- Flutter mobile app -> NestJS API
- Flutter web app -> NestJS API
- NestJS API -> PostgreSQL via Prisma

The Flutter clients do not access PostgreSQL directly. Authentication, workflow rules, audit-sensitive behavior, and reporting logic are enforced in the API layer.

## Repository layout

```text
FlutterAppSerceSync/
  README.md
  .env.example
  apps/
    api/
    mobile/
    web/
  packages/
    sercesync_domain/
```

## Development requirements

Install the following before running the project:

- Git
- Node.js 22 LTS or newer
- pnpm 10 or newer
- PostgreSQL 16 or newer
- Flutter stable channel
- Xcode for the iOS simulator on macOS

Useful checks:

```bash
flutter --version
flutter doctor
node --version
pnpm --version
psql --version
```

## Getting started

### 1. Enter the project

```bash
cd FlutterAppSerceSync
```

### 2. Create local environment values

```bash
cp .env.example .env
```

Update `DATABASE_URL` if your local PostgreSQL role is not `postgres`.

Example for a local Homebrew PostgreSQL install on macOS:

```bash
DATABASE_URL=postgresql://your_local_role@localhost:5432/sercesync?host=/tmp
```

### 3. Create the local database

```bash
createdb sercesync
```

Or with `psql`:

```bash
psql postgres -c "CREATE DATABASE sercesync;"
```

### 4. Install backend dependencies and prepare Prisma

```bash
cd apps/api
pnpm install
pnpm run prisma:format
pnpm run prisma:validate
pnpm run prisma:generate
pnpm run db:migrate
```

### 5. Seed local baseline data

```bash
pnpm run db:seed
```

The seed creates local users, active and upcoming shifts, handover data, residents, tasks, incidents, medication context, and manager-facing records so the mobile and web apps can be exercised immediately.

### 6. Reset local demo data when needed

```bash
pnpm run db:reset-local
```

This restores the standard baseline for local review and testing.

### 7. Refresh active demo shifts during day-to-day testing

```bash
pnpm run db:refresh-active-shifts
```

This keeps the seeded active shifts aligned with the current day and prevents demo tasks from drifting into unrealistic overdue states after the database has been left running for a while.

### 8. Apply schema changes after pulling backend updates

```bash
pnpm run db:deploy
```

Run this after pulling backend/auth/schema changes so the local database matches the current code.

## Environment variables

| Variable | Purpose |
| --- | --- |
| `APP_ENV` | Current application environment |
| `API_PORT` | Local NestJS API port |
| `API_BASE_URL` | Base URL used by clients to reach the API |
| `JWT_SECRET` | Secret used for token signing |
| `JWT_EXPIRES_IN` | Token lifetime |
| `MANAGER_JWT_EXPIRES_IN` | Longer-lived browser session lifetime for the manager dashboard |
| `JWT_REFRESH_EXPIRES_IN` | Mobile refresh-session lifetime |
| `DATABASE_URL` | PostgreSQL connection string |
| `WEB_APP_URL` | Local Flutter web URL |
| `WEB_ALLOWED_ORIGINS` | Optional comma-separated additional web origins allowed to use credentialed CORS |
| `MOBILE_APP_SCHEME` | Reserved mobile app scheme identifier |

Use synthetic data only for development, testing, and demos.

## Running the apps

### API

```bash
cd apps/api
pnpm run start:dev
```

### Mobile

```bash
cd apps/mobile
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is omitted, the app defaults to `http://localhost:3000`.

### Web

```bash
cd apps/web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is omitted, the app defaults to `http://localhost:3000`.

For a closer match to the local demo/browser-session setup, you can also build and serve the web bundle on port `8080`:

```bash
flutter build web
cd build/web
python3 -m http.server 8080
```

## Verification

### API

```bash
cd apps/api
pnpm run build
pnpm run test
pnpm run test:e2e
```

### Mobile

```bash
cd apps/mobile
flutter analyze
flutter test
```

### Web

```bash
cd apps/web
flutter analyze
flutter test
```

## Seeded local accounts

Common local accounts used during development include:

- mobile carer: `carer@sercesync.local` / `Password123!`
- mobile nurse: `nurse@sercesync.local` / `Password123!`
- web manager: `manager@sercesync.local` / `Password123!`

## Notes

- Local scripts and seeded data are intended to make review and demos repeatable.
- The repository uses synthetic data only and is intended for dissertation/demo use, not production deployment.
- If `pnpm run test:e2e` fails, check that PostgreSQL is running and `DATABASE_URL` is valid before troubleshooting the app itself.
