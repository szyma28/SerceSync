import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { HandoversService } from './handovers.service';

@Controller('handovers')
@UseGuards(JwtAuthGuard)
export class HandoversController {
  constructor(private readonly handoversService: HandoversService) {}

  @Get('current')
  getCurrentHandover(@CurrentUser() user: AuthenticatedUser) {
    return this.handoversService.getCurrentHandover(user);
  }

  @Post('current/acknowledge')
  acknowledgeCurrentHandover(@CurrentUser() user: AuthenticatedUser) {
    return this.handoversService.acknowledgeCurrentHandover(user);
  }
}
