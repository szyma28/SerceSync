import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { RolesGuard } from '../common/roles.guard';
import { ManagerDashboardStreamModule } from '../manager-dashboard-stream/manager-dashboard-stream.module';
import { PrismaModule } from '../prisma/prisma.module';
import { ManagerDashboardController } from './manager-dashboard.controller';
import { ManagerIncidentsController } from './manager-incidents.controller';
import { ManagerResidentsController } from './manager-residents.controller';
import { ResidentMediaController } from './resident-media.controller';
import { ResidentsController } from './residents.controller';
import { ResidentsService } from './residents.service';

@Module({
  imports: [AuthModule, PrismaModule, ManagerDashboardStreamModule],
  controllers: [
    ResidentsController,
    ManagerDashboardController,
    ManagerIncidentsController,
    ManagerResidentsController,
    ResidentMediaController,
  ],
  providers: [ResidentsService, RolesGuard],
})
export class ResidentsModule {}
