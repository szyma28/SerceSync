import { Module } from '@nestjs/common';
import { ManagerDashboardStreamService } from './manager-dashboard-stream.service';

@Module({
  providers: [ManagerDashboardStreamService],
  exports: [ManagerDashboardStreamService],
})
export class ManagerDashboardStreamModule {}
