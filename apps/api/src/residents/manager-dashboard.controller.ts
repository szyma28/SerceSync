import {
  Controller,
  Get,
  ParseUUIDPipe,
  Query,
  Sse,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { ManagerDashboardStreamService } from '../manager-dashboard-stream/manager-dashboard-stream.service';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { ResidentsService } from './residents.service';

@Controller('manager/dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('MANAGER')
export class ManagerDashboardController {
  constructor(
    private readonly residentsService: ResidentsService,
    private readonly managerDashboardStream: ManagerDashboardStreamService,
  ) {}

  @Get('shifts')
  getActiveShifts() {
    return this.residentsService.getManagerActiveShifts();
  }

  @Get()
  getDashboard(
    @Query('shiftId', new ParseUUIDPipe({ version: '4', optional: true }))
    shiftId?: string,
  ) {
    return this.residentsService.getManagerDashboard(shiftId);
  }

  @Sse('stream')
  async streamDashboard(
    @Query('shiftId', new ParseUUIDPipe({ version: '4' })) shiftId: string,
  ) {
    await this.residentsService.ensureManagerDashboardShiftAccess(shiftId);
    return this.managerDashboardStream.streamForShift(shiftId);
  }
}
