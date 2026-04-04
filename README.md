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

This repository currently contains the project foundation only.

### 1. Enter the project

```bash
cd FlutterAppSerceSync
```

### 2. Copy local environment values

```bash
cp .env.example .env
```

Adjust values as needed for your local machine.

### 3. Create the local PostgreSQL database

If PostgreSQL is already running locally, create the development database:

```bash
createdb sercesync
```

If you prefer using `psql`:

```bash
psql postgres -c "CREATE DATABASE sercesync;"
```


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

The scaffold currently targets iOS only, which matches the initial project priority for care staff workflows.
It currently displays a simple foundation placeholder screen rather than any real application workflow.

### Web app

```bash
cd apps/web
flutter run -d chrome
```

This scaffold is reserved for the manager-facing web application.
It currently displays a simple foundation placeholder screen rather than any real manager features.

### API

```bash
cd apps/api
pnpm run start:dev
```

The API scaffold includes the initial NestJS configuration, validation, auth support packages, and Prisma dependencies needed for the next implementation phase.
Its current root endpoint is only a simple foundation status response.
