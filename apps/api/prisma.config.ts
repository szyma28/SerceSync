import { config as loadEnv } from 'dotenv';
import { defineConfig } from 'prisma/config';

// Prefer package-local overrides, then fall back to the repo-level env file.
loadEnv({ path: '.env' });
loadEnv({ path: '../../.env', override: false });

export default defineConfig({
  schema: 'prisma/schema.prisma',
  migrations: {
    path: 'prisma/migrations',
  },
  datasource: {
    url: process.env.DATABASE_URL ?? '',
  },
});
