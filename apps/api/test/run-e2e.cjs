const { execFileSync } = require('node:child_process');
const os = require('node:os');
const path = require('node:path');

const { Client } = require('pg');
const { config: loadEnv } = require('dotenv');

const apiRoot = path.resolve(__dirname, '..');

loadEnv({ path: path.join(apiRoot, '.env') });
loadEnv({ path: path.resolve(apiRoot, '../../.env'), override: false });

function buildTestDatabaseUrl() {
  const sourceUrl = process.env.DATABASE_URL;

  if (!sourceUrl) {
    throw new Error('DATABASE_URL must be defined before running e2e tests.');
  }

  const testUrl = new URL(sourceUrl);
  const databaseName = testUrl.pathname.replace(/^\//, '');

  if (!databaseName) {
    throw new Error('DATABASE_URL must include a database name before running e2e tests.');
  }

  if (!databaseName.endsWith('_test')) {
    testUrl.pathname = `/${databaseName}_test`;
  }

  return testUrl;
}

function isLocalDatabaseHost(databaseUrl) {
  return (
    !databaseUrl.hostname ||
    databaseUrl.hostname === 'localhost' ||
    databaseUrl.hostname === '127.0.0.1' ||
    databaseUrl.hostname === '::1'
  );
}

function cloneUrl(databaseUrl) {
  return new URL(databaseUrl.toString());
}

function buildAdminUrl(databaseUrl) {
  const adminUrl = cloneUrl(databaseUrl);
  adminUrl.pathname = '/postgres';
  return adminUrl;
}

function buildLocalFallbackCandidates(databaseUrl) {
  if (!isLocalDatabaseHost(databaseUrl)) {
    return [];
  }

  const localUser = os.userInfo().username;
  const candidates = [];

  const sameHostCandidate = cloneUrl(databaseUrl);
  sameHostCandidate.username = localUser;
  sameHostCandidate.password = '';
  candidates.push(sameHostCandidate);

  const socketCandidate = cloneUrl(databaseUrl);
  socketCandidate.username = localUser;
  socketCandidate.password = '';
  socketCandidate.searchParams.set('host', '/tmp');
  candidates.push(socketCandidate);

  return candidates.filter(
    (candidate, index, allCandidates) =>
      allCandidates.findIndex(
        (entry) => entry.toString() === candidate.toString(),
      ) === index,
  );
}

async function canConnect(connectionString) {
  const client = new Client({ connectionString });

  try {
    await client.connect();
    return { ok: true };
  } catch (error) {
    return { ok: false, error };
  } finally {
    try {
      await client.end();
    } catch {
      // Ignore close errors for failed connection attempts.
    }
  }
}

function formatConnectionTarget(databaseUrl) {
  const sanitizedUrl = cloneUrl(databaseUrl);
  sanitizedUrl.password = '';
  return sanitizedUrl.toString();
}

async function resolveUsableDatabaseUrl(databaseUrl) {
  const candidates = [
    databaseUrl,
    ...buildLocalFallbackCandidates(databaseUrl),
  ];

  let lastError;

  for (const candidate of candidates) {
    const adminConnectionAttempt = await canConnect(
      buildAdminUrl(candidate).toString(),
    );

    if (adminConnectionAttempt.ok) {
      if (candidate.toString() !== databaseUrl.toString()) {
        console.warn(
          [
            'e2e database runner: DATABASE_URL could not connect with the configured role.',
            `Falling back to local Postgres user via ${formatConnectionTarget(candidate)}.`,
          ].join(' '),
        );
      }

      return candidate;
    }

    lastError = adminConnectionAttempt.error;
  }

  throw lastError;
}

async function ensureDatabaseExists(databaseUrl) {
  const adminUrl = buildAdminUrl(databaseUrl);
  const databaseName = databaseUrl.pathname.replace(/^\//, '');

  const client = new Client({ connectionString: adminUrl.toString() });
  await client.connect();

  try {
    const existingDatabase = await client.query(
      'SELECT 1 FROM pg_database WHERE datname = $1',
      [databaseName],
    );

    if (existingDatabase.rowCount === 0) {
      const escapedDatabaseName = databaseName.replace(/"/g, '""');
      await client.query(`CREATE DATABASE "${escapedDatabaseName}"`);
    }
  } finally {
    await client.end();
  }
}

function run(command, args, env) {
  execFileSync(command, args, {
    cwd: apiRoot,
    env,
    stdio: 'inherit',
  });
}

async function main() {
  const testDatabaseUrl = await resolveUsableDatabaseUrl(buildTestDatabaseUrl());
  await ensureDatabaseExists(testDatabaseUrl);

  const env = {
    ...process.env,
    APP_ENV: 'test',
    DATABASE_URL: testDatabaseUrl.toString(),
    NODE_OPTIONS: [process.env.NODE_OPTIONS, '--no-deprecation']
      .filter(Boolean)
      .join(' '),
    NODE_ENV: 'test',
  };

  run('pnpm', ['exec', 'prisma', 'migrate', 'deploy'], env);
  run('pnpm', ['exec', 'jest', '--config', './test/jest-e2e.json'], env);
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exit(1);
});
