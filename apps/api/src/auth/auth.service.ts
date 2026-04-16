import { Injectable, UnauthorizedException } from '@nestjs/common';
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

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
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
  ) {
    return this.jwtService.signAsync({
      sub: user.id,
      email: user.email,
      role: user.role.key,
      displayName: user.displayName,
    });
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

  async login(loginDto: LoginDto) {
    const user = await this.validateCredentials(loginDto);
    const accessToken = await this.createAccessToken(user);
    const userPayload = this.buildUserPayload(user);

    await this.createAuditEvent('USER_LOGIN', user.id, 'mobile-login');

    return {
      accessToken,
      user: userPayload,
    };
  }

  async loginManagerBrowser(loginDto: LoginDto) {
    const user = await this.validateCredentials(loginDto);
    if (user.role.key !== 'MANAGER') {
      throw new UnauthorizedException('Invalid credentials.');
    }

    const accessToken = await this.createAccessToken(user);
    const userPayload = this.buildUserPayload(user);

    await this.createAuditEvent('USER_LOGIN', user.id, 'manager-web-login');

    return {
      accessToken,
      user: userPayload,
    };
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
