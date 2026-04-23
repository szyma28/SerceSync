import { ValidationPipe, type INestApplication } from '@nestjs/common';
import type { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';
import type { NextFunction, Request, Response } from 'express';

const defaultAllowedWebOrigins = [
  'http://localhost:8080',
  'http://127.0.0.1:8080',
];

export function normalizeOrigin(origin: string | undefined) {
  if (!origin) {
    return null;
  }

  try {
    const normalized = new URL(origin.trim());
    if (normalized.protocol !== 'http:' && normalized.protocol !== 'https:') {
      return null;
    }

    return normalized.origin;
  } catch {
    return null;
  }
}

function isLoopbackOrigin(origin: string) {
  try {
    const parsed = new URL(origin);
    return ['localhost', '127.0.0.1', '::1', '[::1]'].includes(parsed.hostname);
  } catch {
    return false;
  }
}

export function readAllowedWebOrigins() {
  const configuredOrigins = (
    process.env.WEB_ALLOWED_ORIGINS ??
    process.env.DEMO_WEB_ORIGIN ??
    ''
  )
    .split(',')
    .map((origin) => normalizeOrigin(origin))
    .filter((origin): origin is string => origin != null);

  return new Set(
    [...defaultAllowedWebOrigins, process.env.WEB_APP_URL, ...configuredOrigins]
      .map((origin) => normalizeOrigin(origin))
      .filter((origin): origin is string => origin != null),
  );
}

export function isAllowedWebOrigin(origin: string | undefined) {
  const normalizedOrigin = normalizeOrigin(origin);
  if (!normalizedOrigin) {
    return false;
  }

  const allowedWebOrigins = readAllowedWebOrigins();
  return (
    allowedWebOrigins.has(normalizedOrigin) || isLoopbackOrigin(normalizedOrigin)
  );
}

export function buildCorsOptions(): CorsOptions {
  const allowedWebOrigins = readAllowedWebOrigins();

  return {
    origin(requestOrigin, callback) {
      if (!requestOrigin || requestOrigin === 'null') {
        callback(null, false);
        return;
      }

      const normalizedOrigin = normalizeOrigin(requestOrigin);
      if (!normalizedOrigin) {
        callback(null, false);
        return;
      }

      if (
        allowedWebOrigins.has(normalizedOrigin) ||
        isLoopbackOrigin(normalizedOrigin)
      ) {
        callback(null, normalizedOrigin);
        return;
      }

      callback(null, false);
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    optionsSuccessStatus: 204,
  };
}

function isSecureRequest(request: {
  secure?: boolean;
  headers?: Record<string, string | string[] | undefined>;
}) {
  const forwardedProto = request.headers?.['x-forwarded-proto'];
  return (
    request.secure === true ||
    forwardedProto === 'https' ||
    (Array.isArray(forwardedProto) && forwardedProto.includes('https'))
  );
}

export function configureHttpApp(app: INestApplication) {
  const httpAdapter = app.getHttpAdapter().getInstance();
  if (typeof httpAdapter.disable === 'function') {
    httpAdapter.disable('x-powered-by');
  }

  app.use((request: Request, response: Response, next: NextFunction) => {
    response.setHeader('X-Content-Type-Options', 'nosniff');
    response.setHeader('X-Frame-Options', 'DENY');
    response.setHeader('Referrer-Policy', 'no-referrer');
    response.setHeader(
      'Permissions-Policy',
      'camera=(), microphone=(), geolocation=()',
    );

    if (isSecureRequest(request)) {
      response.setHeader(
        'Strict-Transport-Security',
        'max-age=31536000; includeSubDomains',
      );
    }

    next();
  });

  app.enableCors(buildCorsOptions());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );
}
