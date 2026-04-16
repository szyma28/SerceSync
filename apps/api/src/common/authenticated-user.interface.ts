import type { RoleKey } from '@prisma/client';

export interface AuthenticatedUser {
  userId: string;
  email: string;
  role: RoleKey;
  displayName: string;
}
