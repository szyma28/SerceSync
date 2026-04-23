const minimumJwtSecretLength = 32;
const disallowedJwtSecrets = new Set([
  'change-me',
  'changeme',
  'default',
  'secret',
]);

function readTrimmedString(
  env: Record<string, unknown>,
  key: string,
): string | undefined {
  const value = env[key];
  if (typeof value !== 'string') {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function readRequiredString(env: Record<string, unknown>, key: string): string {
  const value = readTrimmedString(env, key);
  if (value) {
    return value;
  }

  throw new Error(
    `Missing required environment variable ${key}. Set it in your .env before starting the API.`,
  );
}

function validateJwtSecret(secret: string) {
  if (disallowedJwtSecrets.has(secret.toLowerCase())) {
    throw new Error(
      'JWT_SECRET uses a disallowed placeholder value. Generate a long random secret before starting the API.',
    );
  }

  if (secret.length < minimumJwtSecretLength) {
    throw new Error(
      `JWT_SECRET must be at least ${minimumJwtSecretLength} characters long.`,
    );
  }
}

export function validateEnvironment(
  env: Record<string, unknown>,
): Record<string, unknown> {
  const databaseUrl = readRequiredString(env, 'DATABASE_URL');
  const jwtSecret = readRequiredString(env, 'JWT_SECRET');
  const jwtExpiresIn = readTrimmedString(env, 'JWT_EXPIRES_IN') ?? '15m';
  const managerJwtExpiresIn =
    readTrimmedString(env, 'MANAGER_JWT_EXPIRES_IN') ?? '8h';
  const jwtRefreshExpiresIn =
    readTrimmedString(env, 'JWT_REFRESH_EXPIRES_IN') ?? '14d';

  validateJwtSecret(jwtSecret);

  return {
    ...env,
    DATABASE_URL: databaseUrl,
    JWT_SECRET: jwtSecret,
    JWT_EXPIRES_IN: jwtExpiresIn,
    MANAGER_JWT_EXPIRES_IN: managerJwtExpiresIn,
    JWT_REFRESH_EXPIRES_IN: jwtRefreshExpiresIn,
  };
}
