import { Controller, Get, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../common/jwt-auth.guard';
import { Roles } from '../common/roles.decorator';
import { RolesGuard } from '../common/roles.guard';
import { ResidentsService } from './residents.service';

@Controller('manager/dashboard')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('MANAGER')
export class ManagerDashboardController {
  constructor(private readonly residentsService: ResidentsService) {}

  @Get()
  getDashboard() {
    return this.residentsService.getManagerDashboard();
  }
}
