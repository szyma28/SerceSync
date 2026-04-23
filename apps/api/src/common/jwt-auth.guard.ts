import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import type { Request } from 'express';
import { MANAGER_SESSION_COOKIE_NAME } from '../auth/auth.constants';
import { isAllowedWebOrigin, normalizeOrigin } from '../http-security';
import type { AuthenticatedUser } from './authenticated-user.interface';

type JwtPayload = Omit<AuthenticatedUser, 'userId'> & {
  sub: string;
};

type TokenSource = 'authorization-header' | 'manager-session-cookie';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  private readManagerSessionCookie(request: Request) {
    const cookieHeader = request.headers.cookie;
    if (!cookieHeader) {
      return null;
    }

    for (const rawCookie of cookieHeader.split(';')) {
      const cookie = rawCookie.trim();
      if (!cookie.startsWith(`${MANAGER_SESSION_COOKIE_NAME}=`)) {
        continue;
      }

      const token = cookie.substring(MANAGER_SESSION_COOKIE_NAME.length + 1);
      if (token.trim().length === 0) {
        return null;
      }

      return token;
    }

    return null;
  }

  private requestUsesUnsafeMethod(request: Request) {
    return !['GET', 'HEAD', 'OPTIONS'].includes(
      (request.method ?? 'GET').toUpperCase(),
    );
  }

  private resolveRequestOrigin(request: Request) {
    const originHeader = request.headers.origin;
    if (typeof originHeader === 'string' && originHeader.trim().length > 0) {
      return normalizeOrigin(originHeader);
    }

    const refererHeader = request.headers.referer;
    if (typeof refererHeader === 'string' && refererHeader.trim().length > 0) {
      return normalizeOrigin(refererHeader);
    }

    return null;
  }

  private ensureCookieBackedUnsafeRequestIsTrustedOrigin(request: Request) {
    if (!this.requestUsesUnsafeMethod(request)) {
      return;
    }

    const requestOrigin = this.resolveRequestOrigin(request);
    if (!requestOrigin || !isAllowedWebOrigin(requestOrigin)) {
      throw new ForbiddenException(
        'Cookie-authenticated write requests must originate from an allowlisted web origin.',
      );
    }
  }

  private extractAccessToken(request: Request): {
    token: string;
    source: TokenSource;
  } {
    const authorizationHeader = request.headers.authorization;
    if (authorizationHeader) {
      const [scheme, token] = authorizationHeader.split(' ');

      if (scheme !== 'Bearer' || !token) {
        throw new UnauthorizedException(
          'Authorization header must use Bearer token format.',
        );
      }

      return {
        token,
        source: 'authorization-header',
      };
    }

    const cookieAccessToken = this.readManagerSessionCookie(request);
    if (cookieAccessToken) {
      this.ensureCookieBackedUnsafeRequestIsTrustedOrigin(request);
      return {
        token: cookieAccessToken,
        source: 'manager-session-cookie',
      };
    }

    throw new UnauthorizedException(
      'Missing Authorization header or manager session cookie.',
    );
  }

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: AuthenticatedUser }>();
    const { token } = this.extractAccessToken(request);

    try {
      const payload = await this.jwtService.verifyAsync<JwtPayload>(token);
      request.user = {
        userId: payload.sub,
        email: payload.email,
        role: payload.role,
        displayName: payload.displayName,
      };

      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token.');
    }
  }
}
