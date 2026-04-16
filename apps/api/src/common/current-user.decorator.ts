import {
  createParamDecorator,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import type { AuthenticatedUser } from './authenticated-user.interface';

export const CurrentUser = createParamDecorator<undefined, AuthenticatedUser>(
  (_data, context: ExecutionContext): AuthenticatedUser => {
    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: AuthenticatedUser }>();

    if (!request.user) {
      throw new UnauthorizedException(
        'Authenticated user missing from request context.',
      );
    }

    return request.user;
  },
);
