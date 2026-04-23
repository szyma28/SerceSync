import { randomBytes, createHash } from 'crypto';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { AuditEventKind, Prisma, RoleKey } from '@prisma/client';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';

type UserWithRole = Prisma.UserGetPayload<{
  include: { role: true };
}>;

interface AuthenticatedUserPayload {
  id: string;
  email: string;
  displayName: string;
  role: RoleKey;
}

type MobileAuthSession = {
  accessToken: string;
  accessTokenExpiresAt: string;
  refreshToken: string;
  refreshTokenExpiresAt: string;
  user: AuthenticatedUserPayload;
};

type RefreshRotationResult = {
  refreshToken: string;
  refreshTokenExpiresAt: Date;
  user: UserWithRole;
};

type ManagerBrowserAuthSession = {
  accessToken: string;
  accessTokenExpiresAt: string;
  user: AuthenticatedUserPayload;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  private async findActiveUserByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
      include: { role: true },
    });
  }

  private buildUserPayload(
    user: Pick<UserWithRole, 'id' | 'email' | 'displayName'> & {
      role: Pick<UserWithRole['role'], 'key'>;
    },
  ): AuthenticatedUserPayload {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      role: user.role.key,
    };
  }

  private async validateCredentials(loginDto: LoginDto): Promise<UserWithRole> {
    const user = await this.findActiveUserByEmail(loginDto.email);

    if (!user || !user.isActive || !user.passwordHash) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const passwordMatches = await bcrypt.compare(
      loginDto.password,
      user.passwordHash,
    );

    if (!passwordMatches) {
      throw new UnauthorizedException('Invalid credentials.');
    }

    return user;
  }

  private async createAccessToken(
    user: Pick<UserWithRole, 'id' | 'email' | 'displayName'> & {
      role: Pick<UserWithRole['role'], 'key'>;
    },
    options?: {
      expiresIn?: string;
    },
  ) {
    return this.jwtService.signAsync(
      {
        sub: user.id,
        email: user.email,
        role: user.role.key,
        displayName: user.displayName,
      },
      options?.expiresIn == null
        ? undefined
        : { expiresIn: options.expiresIn as never },
    );
  }

  private resolveAccessTokenExpiry(accessToken: string) {
    const decoded = this.jwtService.decode(accessToken);
    if (
      decoded &&
      typeof decoded === 'object' &&
      'exp' in decoded &&
      typeof decoded.exp === 'number'
    ) {
      return new Date(decoded.exp * 1000);
    }

    throw new Error('Could not determine access token expiration timestamp.');
  }

  private resolveRefreshTokenTtlMs() {
    const rawValue =
      this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') ?? '14d';
    const normalized = rawValue.trim().toLowerCase();
    const match = normalized.match(/^(\d+)([mhd])$/);

    if (!match) {
      throw new Error(
        'JWT_REFRESH_EXPIRES_IN must be formatted as an integer followed by m, h, or d.',
      );
    }

    const amount = Number(match[1]);
    const unit = match[2];
    const multiplier =
      unit === 'm'
        ? 60 * 1000
        : unit === 'h'
          ? 60 * 60 * 1000
          : 24 * 60 * 60 * 1000;

    return amount * multiplier;
  }

  private buildRefreshTokenExpiry(referenceTime = Date.now()) {
    return new Date(referenceTime + this.resolveRefreshTokenTtlMs());
  }

  private resolveManagerJwtExpiresIn() {
    return (
      this.configService.get<string>('MANAGER_JWT_EXPIRES_IN')?.trim() || '8h'
    );
  }

  private hashRefreshToken(refreshToken: string) {
    return createHash('sha256').update(refreshToken).digest('hex');
  }

  private async createRefreshSession(userId: string) {
    const refreshToken = randomBytes(48).toString('hex');
    const refreshTokenExpiresAt = this.buildRefreshTokenExpiry();

    await this.prisma.mobileRefreshSession.create({
      data: {
        userId,
        tokenHash: this.hashRefreshToken(refreshToken),
        expiresAt: refreshTokenExpiresAt,
      },
    });

    return {
      refreshToken,
      refreshTokenExpiresAt,
    };
  }

  private buildMobileAuthSession(args: {
    accessToken: string;
    refreshToken: string;
    refreshTokenExpiresAt: Date;
    user: Pick<UserWithRole, 'id' | 'email' | 'displayName'> & {
      role: Pick<UserWithRole['role'], 'key'>;
    };
  }): MobileAuthSession {
    return {
      accessToken: args.accessToken,
      accessTokenExpiresAt: this.resolveAccessTokenExpiry(
        args.accessToken,
      ).toISOString(),
      refreshToken: args.refreshToken,
      refreshTokenExpiresAt: args.refreshTokenExpiresAt.toISOString(),
      user: this.buildUserPayload(args.user),
    };
  }

  private async createManagerBrowserAuthSession(
    user: Pick<UserWithRole, 'id' | 'email' | 'displayName'> & {
      role: Pick<UserWithRole['role'], 'key'>;
    },
  ): Promise<ManagerBrowserAuthSession> {
    const accessToken = await this.createAccessToken(user, {
      expiresIn: this.resolveManagerJwtExpiresIn(),
    });

    return {
      accessToken,
      accessTokenExpiresAt:
        this.resolveAccessTokenExpiry(accessToken).toISOString(),
      user: this.buildUserPayload(user),
    };
  }

  private async createAuditEvent(
    kind: AuditEventKind,
    userId: string,
    source: string,
  ) {
    await this.prisma.auditEvent.create({
      data: {
        kind,
        userId,
        details: {
          source,
        },
      },
    });
  }

  private async rotateRefreshSession(
    refreshToken: string,
  ): Promise<RefreshRotationResult> {
    const now = new Date();
    const existingSession = await this.prisma.mobileRefreshSession.findUnique({
      where: {
        tokenHash: this.hashRefreshToken(refreshToken.trim()),
      },
      include: {
        user: {
          include: {
            role: true,
          },
        },
      },
    });

    if (
      !existingSession ||
      existingSession.revokedAt != null ||
      existingSession.expiresAt.getTime() <= now.getTime() ||
      !existingSession.user.isActive
    ) {
      throw new UnauthorizedException('Refresh session is invalid or expired.');
    }

    const nextRefreshToken = randomBytes(48).toString('hex');
    const nextRefreshTokenExpiresAt = this.buildRefreshTokenExpiry();

    await this.prisma.$transaction(async (tx) => {
      await tx.mobileRefreshSession.update({
        where: {
          id: existingSession.id,
        },
        data: {
          revokedAt: now,
          lastUsedAt: now,
        },
      });

      await tx.mobileRefreshSession.create({
        data: {
          userId: existingSession.userId,
          tokenHash: this.hashRefreshToken(nextRefreshToken),
          expiresAt: nextRefreshTokenExpiresAt,
          lastUsedAt: now,
        },
      });
    });

    return {
      refreshToken: nextRefreshToken,
      refreshTokenExpiresAt: nextRefreshTokenExpiresAt,
      user: existingSession.user,
    };
  }

  async login(loginDto: LoginDto): Promise<MobileAuthSession> {
    const user = await this.validateCredentials(loginDto);
    const accessToken = await this.createAccessToken(user);
    const { refreshToken, refreshTokenExpiresAt } =
      await this.createRefreshSession(user.id);

    await this.createAuditEvent('USER_LOGIN', user.id, 'mobile-login');

    return this.buildMobileAuthSession({
      accessToken,
      refreshToken,
      refreshTokenExpiresAt,
      user,
    });
  }

  async refreshMobileSession(refreshToken: string): Promise<MobileAuthSession> {
    const rotation = await this.rotateRefreshSession(refreshToken);
    const accessToken = await this.createAccessToken(rotation.user);

    return this.buildMobileAuthSession({
      accessToken,
      refreshToken: rotation.refreshToken,
      refreshTokenExpiresAt: rotation.refreshTokenExpiresAt,
      user: rotation.user,
    });
  }

  async logoutMobileSession(refreshToken: string) {
    const existingSession = await this.prisma.mobileRefreshSession.findUnique({
      where: {
        tokenHash: this.hashRefreshToken(refreshToken.trim()),
      },
    });

    if (!existingSession || existingSession.revokedAt != null) {
      return { success: true };
    }

    await this.prisma.mobileRefreshSession.update({
      where: {
        id: existingSession.id,
      },
      data: {
        revokedAt: new Date(),
        lastUsedAt: new Date(),
      },
    });

    await this.createAuditEvent(
      'USER_LOGOUT',
      existingSession.userId,
      'mobile-logout',
    );

    return { success: true };
  }

  async loginManagerBrowser(loginDto: LoginDto) {
    const user = await this.validateCredentials(loginDto);
    if (user.role.key !== 'MANAGER') {
      throw new UnauthorizedException('Invalid credentials.');
    }

    await this.createAuditEvent('USER_LOGIN', user.id, 'manager-web-login');

    return this.createManagerBrowserAuthSession(user);
  }

  async renewManagerBrowserSession(user: AuthenticatedUser) {
    return this.createManagerBrowserAuthSession({
      id: user.userId,
      email: user.email,
      displayName: user.displayName,
      role: { key: user.role },
    });
  }

  buildManagerBrowserSession(user: AuthenticatedUserPayload) {
    return {
      user,
    };
  }

  buildManagerBrowserSessionFromRequestUser(user: AuthenticatedUser) {
    return this.buildManagerBrowserSession({
      id: user.userId,
      email: user.email,
      displayName: user.displayName,
      role: user.role,
    });
  }
}
