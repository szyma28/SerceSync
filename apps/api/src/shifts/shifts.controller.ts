import { Controller, Get, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/current-user.decorator';
import type { AuthenticatedUser } from '../common/authenticated-user.interface';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ShiftsService } from './shifts.service';

@Controller('shifts')
@UseGuards(JwtAuthGuard)
export class ShiftsController {
  constructor(private readonly shiftsService: ShiftsService) {}

  @Get('current')
  getCurrentShift(@CurrentUser() user: AuthenticatedUser) {
    return this.shiftsService.getCurrentShiftForUser(user.userId);
  }

  @Get('my')
  getShiftOverview(@CurrentUser() user: AuthenticatedUser) {
    return this.shiftsService.getShiftOverviewForUser(user.userId);
  }
}
