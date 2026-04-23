# SerceSync API

NestJS backend for SerceSync.

It serves authentication, shifts, handovers, residents, medication workflows, offline-sync note and incident endpoints, manager dashboards, reporting exports, and audit workflows for the Flutter clients.

## Setup

```bash
pnpm install
```

## Run

```bash
pnpm run start:dev
```

For the seeded local demo workflow, these scripts are also useful:

```bash
pnpm run db:seed
pnpm run db:reset-local
pnpm run db:refresh-active-shifts
pnpm run db:deploy
```

## Verify

```bash
pnpm run build
pnpm run test
pnpm run test:e2e
```
