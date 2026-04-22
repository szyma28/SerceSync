import {
  Body,
  Controller,
  Get,
  HttpCode,
  Post,
  Req,
  Res,
  UseGuards,
} from '@nestjs/common';
import type { CookieOptions, Response } from 'express';
import type { Request } from 'express';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { CurrentUser } from '../common/current-user.decorator';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { MANAGER_SESSION_COOKIE_NAME } from './auth.constants';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';

type SessionUser = {
  id: string;
  email: string;
  displayName: string;
  role: AuthenticatedUser['role'];
};

type LoginResponse = {
  accessToken: string;
  user: SessionUser;
};

type ManagerBrowserSession = {
  accessToken: string;
  user: SessionUser;
};

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  private readManagerSessionToken(request: Request) {
    const authorizationHeader = request.headers.authorization;
    if (authorizationHeader) {
      const [scheme, token] = authorizationHeader.split(' ');
      if (scheme === 'Bearer' && token && token.trim().length > 0) {
        return token.trim();
      }
    }

    const cookieHeader = request.headers.cookie;
    if (!cookieHeader) {
      return '';
    }

    for (const rawCookie of cookieHeader.split(';')) {
      const cookie = rawCookie.trim();
      if (!cookie.startsWith(`${MANAGER_SESSION_COOKIE_NAME}=`)) {
        continue;
      }

      const token = cookie.substring(MANAGER_SESSION_COOKIE_NAME.length + 1);
      return token.trim();
    }

    return '';
  }

  private managerSessionCookieOptions(): CookieOptions {
    const isSecure = process.env.NODE_ENV === 'production';

    return {
      httpOnly: true,
      sameSite: isSecure ? 'none' : 'lax',
      secure: isSecure,
      path: '/',
    };
  }

  @Post('login')
  login(@Body() loginDto: LoginDto): Promise<LoginResponse> {
    return this.authService.login(loginDto);
  }

  @Post('manager/login')
  async loginManagerBrowser(
    @Body() loginDto: LoginDto,
    @Res({ passthrough: true }) response: Response,
  ): Promise<ManagerBrowserSession> {
    const session = await this.authService.loginManagerBrowser(loginDto);
    response.cookie(
      MANAGER_SESSION_COOKIE_NAME,
      session.accessToken,
      this.managerSessionCookieOptions(),
    );

    return this.authService.buildManagerBrowserSession(
      session.accessToken,
      session.user,
    );
  }

  @Get('manager/session')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('MANAGER')
  getManagerBrowserSession(
    @Req() request: Request,
    @CurrentUser() user: AuthenticatedUser,
  ): ManagerBrowserSession {
    return this.authService.buildManagerBrowserSessionFromRequestUser(
      this.readManagerSessionToken(request),
      user,
    );
  }

  @Post('manager/logout')
  @HttpCode(200)
  logoutManagerBrowser(@Res({ passthrough: true }) response: Response) {
    response.clearCookie(
      MANAGER_SESSION_COOKIE_NAME,
      this.managerSessionCookieOptions(),
    );

    return { success: true };
  }
}
