import {
  Body,
  Controller,
  type ExecutionContext,
  ForbiddenException,
  Get,
  HttpCode,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { CookieOptions, Response } from 'express';
import type { Request } from 'express';
import { Throttle } from '@nestjs/throttler';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { CurrentUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { MANAGER_SESSION_COOKIE_NAME } from './auth.constants';
import { AuthService } from './auth.service';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { LoginDto } from './dto/login.dto';
import { isAllowedWebOrigin, normalizeOrigin } from '../http-security';

type SessionUser = {
  id: string;
  email: string;
  displayName: string;
  role: AuthenticatedUser['role'];
};

type LoginResponse = {
  accessToken: string;
  accessTokenExpiresAt: string;
  refreshToken: string;
  refreshTokenExpiresAt: string;
  user: SessionUser;
};

type ManagerBrowserSession = {
  user: SessionUser;
};

const authThrottleKey = (
  context: ExecutionContext,
  tracker: string,
  throttlerName: string,
) => {
  const request = context
    .switchToHttp()
    .getRequest<
      Request & { body?: { email?: string }; route?: { path?: string } }
    >();
  const email =
    typeof request.body?.email === 'string'
      ? request.body.email.trim().toLowerCase()
      : 'anonymous';
  const routePath = request.route?.path ?? request.path ?? 'auth';

  return `${throttlerName}:${routePath}:${tracker}:${email}`;
};

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  private managerSessionCookieOptions(maxAgeMs?: number): CookieOptions {
    const environment = (
      process.env.APP_ENV ??
      process.env.NODE_ENV ??
      ''
    ).toLowerCase();
    const isSecure = environment === 'production';

    return {
      httpOnly: true,
      sameSite: isSecure ? 'none' : 'lax',
      secure: isSecure,
      path: '/',
      ...(maxAgeMs == null ? {} : { maxAge: maxAgeMs }),
    };
  }

  private managerSessionCookieMaxAge(expiresAtIso: string) {
    const maxAgeMs = new Date(expiresAtIso).getTime() - Date.now();
    return maxAgeMs > 0 ? maxAgeMs : 0;
  }

  private applyNoStoreHeaders(response: Response) {
    response.setHeader(
      'Cache-Control',
      'no-store, no-cache, must-revalidate, private',
    );
    response.setHeader('Pragma', 'no-cache');
    response.setHeader('Expires', '0');
  }

  private ensureTrustedBrowserOrigin(request: Request) {
    const requestOrigin =
      normalizeOrigin(request.headers.origin) ??
      normalizeOrigin(request.headers.referer);

    if (!requestOrigin || !isAllowedWebOrigin(requestOrigin)) {
      throw new ForbiddenException(
        'Cookie-authenticated browser write requests must come from an allowlisted web origin.',
      );
    }
  }

  @Throttle({
    default: {
      limit: 20,
      ttl: 60_000,
      generateKey: authThrottleKey,
    },
  })
  @Post('login')
  login(
    @Body() loginDto: LoginDto,
    @Res({ passthrough: true }) response: Response,
  ): Promise<LoginResponse> {
    this.applyNoStoreHeaders(response);
    return this.authService.login(loginDto);
  }

  @Throttle({
    default: {
      limit: 60,
      ttl: 60_000,
    },
  })
  @Post('refresh')
  @HttpCode(200)
  refreshMobileSession(
    @Body() refreshTokenDto: RefreshTokenDto,
    @Res({ passthrough: true }) response: Response,
  ): Promise<LoginResponse> {
    this.applyNoStoreHeaders(response);
    return this.authService.refreshMobileSession(refreshTokenDto.refreshToken);
  }

  @Throttle({
    default: {
      limit: 60,
      ttl: 60_000,
    },
  })
  @Post('logout')
  @HttpCode(200)
  logoutMobileSession(
    @Body() refreshTokenDto: RefreshTokenDto,
    @Res({ passthrough: true }) response: Response,
  ) {
    this.applyNoStoreHeaders(response);
    return this.authService.logoutMobileSession(refreshTokenDto.refreshToken);
  }

  @Throttle({
    default: {
      limit: 20,
      ttl: 60_000,
      generateKey: authThrottleKey,
    },
  })
  @Post('manager/login')
  async loginManagerBrowser(
    @Body() loginDto: LoginDto,
    @Res({ passthrough: true }) response: Response,
  ): Promise<ManagerBrowserSession> {
    const session = await this.authService.loginManagerBrowser(loginDto);
    this.applyNoStoreHeaders(response);
    response.cookie(
      MANAGER_SESSION_COOKIE_NAME,
      session.accessToken,
      this.managerSessionCookieOptions(
        this.managerSessionCookieMaxAge(session.accessTokenExpiresAt),
      ),
    );

    return this.authService.buildManagerBrowserSession(session.user);
  }

  @Throttle({
    default: {
      limit: 60,
      ttl: 60_000,
    },
  })
  @Get('manager/session')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('MANAGER')
  async getManagerBrowserSession(
    @CurrentUser() user: AuthenticatedUser,
    @Res({ passthrough: true }) response: Response,
  ): Promise<ManagerBrowserSession> {
    const renewedSession =
      await this.authService.renewManagerBrowserSession(user);
    this.applyNoStoreHeaders(response);
    response.cookie(
      MANAGER_SESSION_COOKIE_NAME,
      renewedSession.accessToken,
      this.managerSessionCookieOptions(
        this.managerSessionCookieMaxAge(renewedSession.accessTokenExpiresAt),
      ),
    );
    return this.authService.buildManagerBrowserSessionFromRequestUser(user);
  }

  @Throttle({
    default: {
      limit: 30,
      ttl: 60_000,
    },
  })
  @Post('manager/logout')
  @HttpCode(200)
  logoutManagerBrowser(
    @Req() request: Request,
    @Res({ passthrough: true }) response: Response,
  ) {
    this.ensureTrustedBrowserOrigin(request);
    this.applyNoStoreHeaders(response);
    response.clearCookie(
      MANAGER_SESSION_COOKIE_NAME,
      this.managerSessionCookieOptions(),
    );

    return { success: true };
  }
}
