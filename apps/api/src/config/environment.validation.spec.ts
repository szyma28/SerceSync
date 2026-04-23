import { validateEnvironment } from './environment.validation';

describe('validateEnvironment', () => {
  it('accepts a configured database URL and JWT settings', () => {
    expect(
      validateEnvironment({
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
        JWT_SECRET: 'a'.repeat(32),
        JWT_EXPIRES_IN: '30m',
        JWT_REFRESH_EXPIRES_IN: '7d',
      }),
    ).toMatchObject({
      DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
      JWT_SECRET: 'a'.repeat(32),
      JWT_EXPIRES_IN: '30m',
      JWT_REFRESH_EXPIRES_IN: '7d',
    });
  });

  it('defaults JWT_EXPIRES_IN values when they are omitted', () => {
    expect(
      validateEnvironment({
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
        JWT_SECRET: 'b'.repeat(32),
      }),
    ).toMatchObject({
      JWT_EXPIRES_IN: '15m',
      JWT_REFRESH_EXPIRES_IN: '14d',
    });
  });

  it('rejects a missing JWT secret', () => {
    expect(() =>
      validateEnvironment({
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
      }),
    ).toThrow(/JWT_SECRET/);
  });

  it('rejects placeholder JWT secrets', () => {
    expect(() =>
      validateEnvironment({
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
        JWT_SECRET: 'change-me',
      }),
    ).toThrow(/disallowed placeholder/i);
  });

  it('rejects short JWT secrets', () => {
    expect(() =>
      validateEnvironment({
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/sercesync',
        JWT_SECRET: 'short-secret',
      }),
    ).toThrow(/at least 32 characters/i);
  });
});
