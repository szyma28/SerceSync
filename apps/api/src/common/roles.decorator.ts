import type { RoleKey } from '@prisma/client';
import { SetMetadata } from '@nestjs/common';

export const ROLES_KEY = 'roles';

export const Roles = (...roles: RoleKey[]) => SetMetadata(ROLES_KEY, roles);
